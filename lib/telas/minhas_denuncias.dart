// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo denuncia.dart: modelo da denúncia e data relativa.
import '../modelos/denuncia.dart';
// Arquivo filtros_de_denuncia.dart: filtros e busca da lista de denúncias.
import '../modelos/filtros_de_denuncia.dart';
// Arquivo ong.dart: a organização cujas denúncias recebidas são listadas.
import '../modelos/ong.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo denuncia_service.dart: busca as denúncias deste aparelho.
import '../services/denuncia_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo aviso_no_centro.dart: aviso centralizado de lista vazia ou erro.
import '../widgets/aviso_no_centro.dart';
// Arquivo barra_inferior.dart: barra inferior, na aba Reportar.
import '../widgets/barra_inferior.dart';
// Arquivo campo_de_busca.dart: campo de busca arredondado do topo da lista.
import '../widgets/campo_de_busca.dart';
// Arquivo foto_animal.dart: exibição da primeira foto da denúncia.
import '../widgets/foto_animal.dart';
// Arquivo painel_de_filtros_de_denuncia.dart: painel com os filtros da lista.
import '../widgets/painel_de_filtros_de_denuncia.dart';

// Lista de denúncias com a situação atual de cada uma buscada na API. Sem
// [organizacao], mostra as registradas neste aparelho (os protocolos ficam
// salvos localmente). Com [organizacao], mostra as denúncias recebidas por
// ela, na aba Reportar, com o botão "+" para registrar uma nova. Permite
// buscar pelo protocolo, pela descrição ou pelo local, filtrar como no feed
// (tipo, situação, animal, bairro e data) e atualizar puxando a lista para baixo ou pelo
// botão "Tentar de novo" quando falta conexão.
//
// [servico] permite injetar um serviço falso nos testes.
class MinhasDenuncias extends StatefulWidget {
  final DenunciaService? servico;
  final Ong? organizacao;

  const MinhasDenuncias({super.key, this.servico, this.organizacao});

  @override
  State<MinhasDenuncias> createState() => _MinhasDenunciasState();
}

class _MinhasDenunciasState extends State<MinhasDenuncias> {
  late final _servico = widget.servico ?? DenunciaService();
  List<Denuncia>? _denuncias;
  bool _semConexao = false;
  final _pesquisa = TextEditingController();
  String _busca = '';
  FiltrosDeDenuncia _filtros = const FiltrosDeDenuncia();

  @override
  void dispose() {
    _pesquisa.dispose();
    super.dispose();
  }

  // As denúncias que atendem à busca e aos filtros
  List<Denuncia> _visiveis(List<Denuncia> todas, FiltrosDeDenuncia filtros) {
    final agora = DateTime.now();
    return [
      for (final denuncia in todas)
        if (denunciaContem(denuncia, _busca) &&
            filtros.combina(denuncia, agora))
          denuncia,
    ];
  }

  // Abre o painel de filtros e aplica o que ele devolver. O painel recebe a
  // contagem para mostrar quantas denúncias vão aparecer
  Future<void> _abrirFiltros(List<Denuncia> todas) async {
    final escolhidos = await showModalBottomSheet<FiltrosDeDenuncia>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.cores.fundo,
      builder: (_) => PainelDeFiltrosDeDenuncia(
        inicial: _filtros,
        denuncias: todas,
        contar: (filtros) => _visiveis(todas, filtros).length,
      ),
    );
    if (escolhidos == null || !mounted) return;
    setState(() => _filtros = escolhidos);
  }

  // Tira a busca e os filtros, voltando a mostrar todas as denúncias
  void _limparBusca() {
    _pesquisa.clear();
    setState(() {
      _busca = '';
      _filtros = const FiltrosDeDenuncia();
    });
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // Busca as denúncias. Sem conexão, mantém a lista anterior (ou uma vazia)
  // e exibe o aviso
  Future<void> _carregar() async {
    try {
      final organizacao = widget.organizacao;
      final denuncias = organizacao?.id == null
          ? await _servico.minhasDenuncias()
          : await _servico.daOrganizacao(organizacao!.id!);
      if (!mounted) return;
      setState(() {
        _denuncias = denuncias;
        _semConexao = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _denuncias ??= const [];
        _semConexao = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final todas = _denuncias;
    final denuncias = todas == null ? null : _visiveis(todas, _filtros);
    final buscando = _busca.trim().isNotEmpty || !_filtros.vazio;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.cores.fundo,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            color: context.cores.principal,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          widget.organizacao == null
              ? 'MINHAS DENÚNCIAS'
              : 'DENÚNCIAS RECEBIDAS',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: context.cores.principal,
        onRefresh: _carregar,
        child: ListaComAviso(
          topo: [
            if (todas != null && todas.isNotEmpty) ...[
              // Busca e, ao lado, o botão dos filtros com o número de
              // filtros marcados, como no feed
              Row(
                children: [
                  Expanded(
                    child: CampoDeBusca(
                      controller: _pesquisa,
                      dica: 'Buscar protocolo, local ou descrição',
                      aoMudar: (texto) => setState(() => _busca = texto),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _abrirFiltros(todas),
                    tooltip: 'Filtros',
                    color: context.cores.principal,
                    icon: Badge(
                      isLabelVisible: !_filtros.vazio,
                      label: Text('${_filtros.quantos}'),
                      backgroundColor: context.cores.principal,
                      child: const Icon(Icons.tune),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Sem conexão, mas com a lista anterior: aviso discreto
              if (_semConexao)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sem conexão: a situação pode estar '
                          'desatualizada.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.cores.textoFraco,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _carregar,
                        style: TextButton.styleFrom(
                          foregroundColor: context.cores.principal,
                        ),
                        child: const Text('Tentar de novo'),
                      ),
                    ],
                  ),
                ),
            ],
          ],
          aviso: denuncias == null
              ? Center(
                  child: CircularProgressIndicator(
                    color: context.cores.principal,
                  ),
                )
              : denuncias.isEmpty && buscando
              ? AvisoNoCentro(
                  icone: Icons.search_off,
                  titulo: 'Nenhuma denúncia encontrada.',
                  texto: 'Confira o que digitou ou tire algum filtro.',
                  acao: 'Limpar busca e filtros',
                  aoAgir: _limparBusca,
                )
              : denuncias.isEmpty && _semConexao
              ? AvisoNoCentro(
                  icone: Icons.wifi_off,
                  titulo: 'Sem conexão',
                  texto:
                      'Não foi possível buscar a situação das denúncias. '
                      'Confira a internet e tente de novo.',
                  acao: 'Tentar de novo',
                  aoAgir: _carregar,
                  acaoEmDestaque: true,
                )
              : denuncias.isEmpty && widget.organizacao != null
              ? AvisoNoCentro(
                  icone: Icons.shield_outlined,
                  titulo: 'Nenhuma denúncia recebida.',
                  texto:
                      'As denúncias enviadas a ${widget.organizacao!.nome} '
                      'pelo app aparecem aqui.',
                )
              : denuncias.isEmpty
              ? const AvisoNoCentro(
                  icone: Icons.shield_outlined,
                  titulo: 'Nenhuma denúncia feita neste aparelho.',
                  texto:
                      'As denúncias que você registrar pelo Reportar '
                      'aparecem aqui, com o protocolo e a situação.',
                )
              : null,
          itens: [
            for (final denuncia in denuncias ?? const <Denuncia>[])
              _CartaoDaDenuncia(denuncia: denuncia, aoVoltar: _carregar),
          ],
        ),
      ),
      // Na aba Reportar da organização, o "+" abre o formulário, como o de
      // cadastro no feed, e a lista é atualizada na volta
      floatingActionButton: widget.organizacao == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.novaDenuncia);
                _carregar();
              },
              backgroundColor: context.cores.principal,
              foregroundColor: context.sobrePrincipal,
              tooltip: 'Registrar denúncia',
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: widget.organizacao == null
          ? null
          : const BarraInferior(atual: 2),
    );
  }
}

// Cartão de uma denúncia na lista: primeira foto, tipo, situação, protocolo,
// quando foi registrada e o bairro. Ao tocar, abre os detalhes e, na volta,
// executa [aoVoltar] para mostrar a situação atualizada
class _CartaoDaDenuncia extends StatelessWidget {
  const _CartaoDaDenuncia({required this.denuncia, required this.aoVoltar});

  final Denuncia denuncia;
  final VoidCallback aoVoltar;

  @override
  Widget build(BuildContext context) {
    final situacao = denuncia.situacao;
    // Etiqueta da situação: fundo claro enquanto em aberto, cheio quando
    // encerrada
    final encerrada = situacao == SituacaoDaDenuncia.encerrada;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.cores.cartao,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.cores.borda),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.pushNamed(
              context,
              AppRoutes.detalhesDenuncia,
              arguments: denuncia,
            );
            aoVoltar();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Primeira foto da denúncia; sem foto, o ícone padrão
                SizedBox(
                  width: 72,
                  child: FotoAnimal(
                    caminho: denuncia.fotos.firstOrNull ?? '',
                    altura: 72,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              denuncia.tipo.rotulo,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: encerrada
                                  ? context.cores.principal
                                  : context.cores.principalClara,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              situacao.rotulo,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: encerrada
                                    ? context.sobrePrincipal
                                    : context.cores.principal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Protocolo ${denuncia.protocolo}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.cores.texto,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registrada ${quandoFoi(denuncia.registradaEm, DateTime.now())}'
                        '${denuncia.bairro.isEmpty ? '' : ', ${denuncia.bairro}'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.cores.textoFraco,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
