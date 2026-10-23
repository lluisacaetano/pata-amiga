// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo denuncia.dart: modelo da denúncia e data relativa.
import '../modelos/denuncia.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo denuncia_service.dart: busca as denúncias deste aparelho.
import '../services/denuncia_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo aviso_no_centro.dart: aviso centralizado de lista vazia ou erro.
import '../widgets/aviso_no_centro.dart';
// Arquivo campo_de_busca.dart: campo de busca arredondado do topo da lista.
import '../widgets/campo_de_busca.dart';
// Arquivo foto_animal.dart: exibição da primeira foto da denúncia.
import '../widgets/foto_animal.dart';

// Lista das denúncias registradas neste aparelho (os protocolos ficam
// salvos localmente), com a situação atual de cada uma buscada na API.
// Permite buscar pelo protocolo e atualizar puxando a lista para baixo ou
// pelo botão "Tentar de novo" quando falta conexão.
//
// [servico] permite injetar um serviço falso nos testes.
class MinhasDenuncias extends StatefulWidget {
  final DenunciaService? servico;

  const MinhasDenuncias({super.key, this.servico});

  @override
  State<MinhasDenuncias> createState() => _MinhasDenunciasState();
}

class _MinhasDenunciasState extends State<MinhasDenuncias> {
  late final _servico = widget.servico ?? DenunciaService();
  List<Denuncia>? _denuncias;
  bool _semConexao = false;
  final _pesquisa = TextEditingController();
  String _busca = '';

  @override
  void dispose() {
    _pesquisa.dispose();
    super.dispose();
  }

  // Normaliza o protocolo para a busca: maiúsculas, sem hífen nem espaço.
  // Assim, "pa 2026" encontra "PA-20261022-9204"
  static String _comparavel(String texto) =>
      texto.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  // Se a denúncia corresponde ao texto da busca (busca vazia aceita todas)
  bool _combina(Denuncia denuncia) {
    final busca = _comparavel(_busca);
    return busca.isEmpty || _comparavel(denuncia.protocolo).contains(busca);
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
      final denuncias = await _servico.minhasDenuncias();
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
    final denuncias = todas?.where(_combina).toList();
    final buscando = _busca.trim().isNotEmpty;
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
          'MINHAS DENÚNCIAS',
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
              CampoDeBusca(
                controller: _pesquisa,
                dica: 'Buscar pelo protocolo',
                aoMudar: (texto) => setState(() => _busca = texto),
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
              ? const AvisoNoCentro(
                  icone: Icons.search_off,
                  titulo: 'Nenhuma denúncia com esse protocolo.',
                  texto: 'Confira o número ou busque só por uma parte dele.',
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
              _CartaoDaDenuncia(denuncia: denuncia),
          ],
        ),
      ),
    );
  }
}

// Cartão de uma denúncia na lista: primeira foto, tipo, situação, protocolo,
// quando foi registrada e o bairro. Ao tocar, abre os detalhes
class _CartaoDaDenuncia extends StatelessWidget {
  const _CartaoDaDenuncia({required this.denuncia});

  final Denuncia denuncia;

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
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.detalhesDenuncia,
            arguments: denuncia,
          ),
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
