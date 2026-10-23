// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo estado_pata_amiga.dart: ONGs e animais compartilhados.
import '../estado/estado_pata_amiga.dart';
// Arquivo animal.dart: modelo do animal.
import '../modelos/animal.dart';
// Arquivo ong.dart: modelo da ONG e a comparação de nomes.
import '../modelos/ong.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo ong_service.dart: busca das ONGs na API.
import '../services/ong_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo barra_inferior.dart: barra de navegação inferior.
import '../widgets/barra_inferior.dart';
// Arquivo avatar_da_ong.dart: avatar da ONG com foto ou iniciais.
import '../widgets/avatar_da_ong.dart';
// Arquivo aviso_no_centro.dart: aviso centralizado de lista vazia ou erro.
import '../widgets/aviso_no_centro.dart';
// Arquivo campo_de_busca.dart: campo de busca arredondado do topo da lista.
import '../widgets/campo_de_busca.dart';

// Lista das ONGs e abrigos, aberta pelo item "ONGs" da barra inferior. Dá
// acesso ao perfil de cada ONG sem passar por um animal do feed
class ListaOngs extends StatefulWidget {
  final OngService? servico;

  const ListaOngs({super.key, this.servico});

  @override
  State<ListaOngs> createState() => _ListaOngsState();
}

class _ListaOngsState extends State<ListaOngs> {
  late final _servico = widget.servico ?? OngService();
  final _pesquisa = TextEditingController();
  String _busca = '';
  bool _carregando = true;
  bool _semConexao = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _pesquisa.dispose();
    super.dispose();
  }

  // Recarrega as ONGs da API ao abrir, pois uma ONG pode ter sido criada
  // depois do carregamento do feed. Sem conexão, mantém a lista em memória
  Future<void> _carregar() async {
    try {
      final ongs = await _servico.buscarOngs();
      if (!mounted) return;
      PataAmigaScope.of(context).atualizarOngs(ongs);
      setState(() {
        _carregando = false;
        _semConexao = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _semConexao = true;
      });
    }
  }

  // A busca é pelo nome da ONG, sem ligar para maiúsculas e acentos
  bool _combina(Ong ong) {
    final busca = Ong.nomeComparavel(_busca);
    return busca.isEmpty || Ong.nomeComparavel(ong.nome).contains(busca);
  }

  // Aviso no lugar da lista: sem conexão, busca sem resultado ou nenhuma ONG
  Widget _avisoDaListaVazia({
    required bool buscando,
    required bool semConexao,
  }) {
    if (semConexao) {
      return AvisoNoCentro(
        icone: Icons.wifi_off,
        titulo: 'Não foi possível carregar as ONGs.',
        texto: 'Confira a conexão com a internet e tente de novo.',
        acao: 'Tentar de novo',
        aoAgir: _carregar,
        acaoEmDestaque: true,
      );
    }
    if (buscando) {
      return const AvisoNoCentro(
        icone: Icons.search_off,
        titulo: 'Nenhuma ONG com esse nome.',
        texto: 'Confira a escrita ou busque por outra palavra do nome.',
      );
    }
    return const AvisoNoCentro(
      icone: Icons.volunteer_activism_outlined,
      titulo: 'Nenhuma ONG cadastrada ainda.',
      texto:
          'Representa uma ONG ou abrigo? Crie o perfil dela em Editar '
          'perfil.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final ongs = estado.ongs.where(_combina).toList()
      // Ordem alfabética ignorando acentos, para "Órfãos" ficar junto do "O"
      ..sort(
        (a, b) =>
            Ong.nomeComparavel(a.nome).compareTo(Ong.nomeComparavel(b.nome)),
      );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.cores.fundo,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'ONGS E ABRIGOS',
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
            CampoDeBusca(
              controller: _pesquisa,
              dica: 'Buscar pelo nome da ONG',
              aoMudar: (texto) => setState(() => _busca = texto),
            ),
            const SizedBox(height: 16),
            // Sem conexão mas com ONGs em memória: avisa que a lista pode
            // estar desatualizada. Sem nenhuma, o aviso vem no lugar da lista
            if (_semConexao && estado.ongs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sem conexão: a lista pode estar desatualizada.',
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
          aviso: _carregando && estado.ongs.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: context.cores.principal,
                  ),
                )
              : ongs.isEmpty
              ? _avisoDaListaVazia(
                  buscando: _busca.trim().isNotEmpty,
                  semConexao: _semConexao && estado.ongs.isEmpty,
                )
              : null,
          itens: [
            for (final ong in ongs)
              _CartaoDaOng(
                ong: ong,
                emAberto: estado
                    .animaisDa(ong)
                    .where((animal) => !animal.finalizado)
                    .toList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BarraInferior(atual: 3),
    );
  }
}

// Card de uma ONG: avatar (foto ou iniciais), nome, bairro e quantos animais
// dela estão em aberto. O toque abre o perfil da ONG
class _CartaoDaOng extends StatelessWidget {
  const _CartaoDaOng({required this.ong, required this.emAberto});

  final Ong ong;
  final List<Animal> emAberto;

  @override
  Widget build(BuildContext context) {
    final quantos = emAberto.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: context.cores.cartao,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.cores.borda),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.perfilOng, arguments: ong),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AvatarDaOng(ong: ong, raio: 34),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ong.nome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (ong.bairro.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: context.cores.principal,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${ong.bairro}, Formiga',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.cores.principal,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: context.cores.borda),
                Row(
                  children: [
                    Icon(
                      Icons.pets_outlined,
                      size: 18,
                      color: context.cores.textoFraco,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        switch (quantos) {
                          0 => 'Nenhum animal em aberto',
                          1 => '1 animal em aberto',
                          _ => '$quantos animais em aberto',
                        },
                        style: TextStyle(
                          fontSize: 13,
                          color: context.cores.textoFraco,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
