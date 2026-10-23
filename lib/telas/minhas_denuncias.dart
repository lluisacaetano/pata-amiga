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
// Arquivo foto_animal.dart: exibição da primeira foto da denúncia.
import '../widgets/foto_animal.dart';

// Lista das denúncias registradas neste aparelho (os protocolos ficam
// salvos localmente), com a situação atual de cada uma buscada na API.
// Permite buscar pelo protocolo e atualizar puxando a lista para baixo.
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (todas != null && todas.isNotEmpty) ...[
              TextField(
                controller: _pesquisa,
                onChanged: (texto) => setState(() => _busca = texto),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: context.cores.cartao,
                  hintText: 'Buscar pelo protocolo',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: context.cores.textoFraco,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.cores.textoFraco,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: context.cores.borda),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: context.cores.principal,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_semConexao)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Sem conexão: não foi possível atualizar a situação. Puxe '
                  'para baixo para tentar de novo.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cores.textoFraco,
                  ),
                ),
              ),
            if (denuncias == null)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: context.cores.principal,
                  ),
                ),
              )
            else if (denuncias.isEmpty && buscando)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'Nenhuma denúncia com esse protocolo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.cores.textoFraco,
                  ),
                ),
              )
            else if (denuncias.isEmpty && !_semConexao)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 44,
                      color: context.cores.principal,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhuma denúncia feita neste aparelho.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'As denúncias que você registrar pelo Reportar aparecem '
                      'aqui, com o protocolo e a situação.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.cores.textoFraco,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final denuncia in denuncias)
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
