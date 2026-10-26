// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo filtros_do_feed.dart: filtros do feed e as opções de cada grupo.
import '../modelos/filtros_do_feed.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo bairros_formiga.dart: bairros de Formiga.
import '../dados/bairros_formiga.dart';
// Arquivo racas.dart: raças e a busca na lista.
import '../dados/racas.dart';
// Arquivo animal.dart: modelo do animal.
import '../modelos/animal.dart';
// Arquivo ong.dart: modelo da ONG e a comparação de nomes.
import '../modelos/ong.dart';
// Arquivo escolha_de_tipo.dart: estilo das abas.
import 'escolha_de_tipo.dart';
// Arquivo selecao_com_busca.dart: seleção com campo de busca.
import 'selecao_com_busca.dart';

// Opção do rodapé da raça que remove o filtro de raça
const todasAsRacas = 'Todas as raças';
// Opções do rodapé da ONG para marcar todas ou nenhuma de uma vez
const _todasAsOngs = 'Selecionar todas';
const _nenhumaOng = 'Desmarcar todas';

// Painel inferior com os filtros do feed. As escolhas ficam em rascunho e só
// são aplicadas ao tocar no botão final, que devolve os filtros pelo
// Navigator.pop e já mostra quantos animais vão aparecer
class PainelDeFiltros extends StatefulWidget {
  final FiltrosDoFeed inicial;
  // Animais do feed. As opções de raça, bairro e ONG saem deles, para não
  // oferecer uma opção que não traga nenhum resultado
  final List<Animal> animais;
  // Conta quantos animais combinam com os filtros, para o texto do botão
  final int Function(FiltrosDoFeed) contar;
  // ONGs cadastradas, para mostrar o nome no lugar do id
  final List<Ong> ongs;

  const PainelDeFiltros({
    super.key,
    required this.inicial,
    required this.animais,
    required this.contar,
    this.ongs = const [],
  });

  @override
  State<PainelDeFiltros> createState() => _PainelDeFiltrosState();
}

class _PainelDeFiltrosState extends State<PainelDeFiltros> {
  late FiltrosDoFeed _filtros = widget.inicial;
  // Textos digitados nas buscas de raça, bairro e ONG. As opções marcadas
  // ficam em _filtros, não nos campos
  final _raca = TextEditingController();
  final _bairro = TextEditingController();
  final _ong = TextEditingController();

  @override
  void dispose() {
    _raca.dispose();
    _bairro.dispose();
    _ong.dispose();
    super.dispose();
  }

  // Marca ou desmarca uma raça; "Todas as raças" limpa o grupo. Depois,
  // ajusta a espécie para a das raças marcadas (uma raça pertence a uma só
  // espécie). "Sem raça definida" vale para as duas e não altera a espécie
  void _alternarRaca(String? raca) {
    if (raca == null) return;
    setState(() {
      _filtros = raca == todasAsRacas
          ? _filtros.comGrupo(GrupoDeFiltro.raca, const {})
          : _filtros.alternar(GrupoDeFiltro.raca, raca);
      final especies = {
        for (final animal in widget.animais)
          if (racaPadrao(animal.raca) != semRacaDefinida &&
              _filtros.de(GrupoDeFiltro.raca).contains(racaPadrao(animal.raca)))
            ...valoresDe(animal, GrupoDeFiltro.especie),
      };
      if (especies.isNotEmpty) {
        _filtros = _filtros.comGrupo(GrupoDeFiltro.especie, especies);
      }
    });
  }

  void _alternarBairro(String? bairro) {
    if (bairro == null) return;
    setState(() => _filtros = _filtros.alternar(GrupoDeFiltro.bairro, bairro));
  }

  // ONGs com pelo menos um animal no feed, em ordem alfabética. As demais
  // ficam de fora porque não trariam nenhum resultado, e as que só recebem
  // denúncias também, porque não publicam animais
  List<Ong> get _ongsDisponiveis {
    final comAnimais = opcoesDe(GrupoDeFiltro.ong, widget.animais).toSet();
    return widget.ongs
        .where(
          (ong) =>
              comAnimais.contains('${ong.id}') &&
              ong.finalidades.any(
                (finalidade) => finalidade != FinalidadeDaOng.denuncias,
              ),
        )
        .toList()
      ..sort(
        (a, b) =>
            Ong.nomeComparavel(a.nome).compareTo(Ong.nomeComparavel(b.nome)),
      );
  }

  // Marca ou desmarca uma ONG pelo nome exibido, guardando o id no filtro.
  // Também trata as opções de marcar todas e desmarcar todas
  void _alternarOng(String? escolha) {
    if (escolha == null) return;
    final disponiveis = _ongsDisponiveis;
    setState(() {
      if (escolha == _todasAsOngs) {
        _filtros = _filtros.comGrupo(GrupoDeFiltro.ong, {
          for (final ong in disponiveis) '${ong.id}',
        });
      } else if (escolha == _nenhumaOng) {
        _filtros = _filtros.comGrupo(GrupoDeFiltro.ong, const {});
      } else {
        final ong = disponiveis.where((ong) => ong.nome == escolha);
        if (ong.isEmpty) return;
        _filtros = _filtros.alternar(GrupoDeFiltro.ong, '${ong.first.id}');
      }
    });
  }

  // Atualiza um grupo de abas. Ao trocar a espécie, remove as raças marcadas
  // que não pertencem a ela
  void _mudarAba(GrupoDeFiltro grupo, Set<String> opcoes) {
    setState(() {
      _filtros = _filtros.comGrupo(grupo, opcoes);
      if (grupo != GrupoDeFiltro.especie) return;
      final validas = {..._racas, semRacaDefinida};
      _filtros = _filtros.comGrupo(GrupoDeFiltro.raca, {
        for (final raca in _filtros.de(GrupoDeFiltro.raca))
          if (validas.contains(raca)) raca,
      });
    });
  }

  // Limpa todos os filtros e os textos das buscas
  void _limpar() {
    _raca.clear();
    _bairro.clear();
    _ong.clear();
    setState(() => _filtros = const FiltrosDoFeed());
  }

  // Raças presentes no feed, restritas às espécies marcadas quando houver.
  // "Sem raça definida" aparece no rodapé da seleção
  List<String> get _racas {
    final especies = _filtros.de(GrupoDeFiltro.especie);
    return opcoesDe(GrupoDeFiltro.raca, [
      for (final animal in widget.animais)
        if (especies.isEmpty ||
            especies.any(valoresDe(animal, GrupoDeFiltro.especie).contains))
          animal,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final quantos = widget.contar(_filtros);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _filtros.vazio ? null : _limpar,
                    style: TextButton.styleFrom(
                      foregroundColor: context.cores.principal,
                    ),
                    child: const Text('Limpar filtros'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: _Cartao(
                  children: [
                    for (final grupo in [
                      GrupoDeFiltro.especie,
                      GrupoDeFiltro.porte,
                      GrupoDeFiltro.sexo,
                    ]) ...[
                      _Rotulo(grupo.titulo),
                      _Abas(
                        opcoes: opcoesDe(grupo, const []),
                        marcadas: _filtros.de(grupo),
                        aoMudar: (opcoes) => _mudarAba(grupo, opcoes),
                      ),
                    ],
                    SelecaoComBusca(
                      rotulo: 'Raça',
                      dica: 'Digite para buscar a raça',
                      controlador: _raca,
                      opcoes: (digitado) => buscarNaLista(_racas, digitado),
                      daLista: (texto) => _racas.contains(racaPadrao(texto))
                          ? racaPadrao(texto)
                          : null,
                      rodape: [
                        if (_racas.contains(semRacaDefinida))
                          (valor: semRacaDefinida, texto: semRacaDefinida),
                        (valor: todasAsRacas, texto: todasAsRacas),
                      ],
                      limpavel: true,
                      marcadas: _filtros.de(GrupoDeFiltro.raca),
                      aoEscolher: _alternarRaca,
                    ),
                    SelecaoComBusca(
                      rotulo: 'Bairro',
                      dica: 'Digite para buscar o bairro',
                      controlador: _bairro,
                      opcoes: (digitado) => buscarNaLista(
                        opcoesDe(GrupoDeFiltro.bairro, widget.animais),
                        digitado,
                      ),
                      daLista: (texto) {
                        final bairro = bairroDaLista(texto);
                        return opcoesDe(
                              GrupoDeFiltro.bairro,
                              widget.animais,
                            ).contains(bairro)
                            ? bairro
                            : null;
                      },
                      limpavel: true,
                      marcadas: _filtros.de(GrupoDeFiltro.bairro),
                      aoEscolher: _alternarBairro,
                    ),
                    if (_ongsDisponiveis case final ongs when ongs.isNotEmpty)
                      SelecaoComBusca(
                        rotulo: 'ONG',
                        dica: 'Digite para buscar a ONG',
                        controlador: _ong,
                        opcoes: (digitado) => buscarNaLista([
                          for (final ong in ongs) ong.nome,
                        ], digitado),
                        daLista: (texto) => [for (final ong in ongs) ong.nome]
                            .where(
                              (nome) =>
                                  Ong.nomeComparavel(nome) ==
                                  Ong.nomeComparavel(texto),
                            )
                            .firstOrNull,
                        rodape: const [
                          (valor: _todasAsOngs, texto: _todasAsOngs),
                          (valor: _nenhumaOng, texto: _nenhumaOng),
                        ],
                        limpavel: true,
                        marcadas: {
                          for (final ong in ongs)
                            if (_filtros
                                .de(GrupoDeFiltro.ong)
                                .contains('${ong.id}'))
                              ong.nome,
                        },
                        aoEscolher: _alternarOng,
                      ),
                    const _Rotulo('Saúde'),
                    _Abas(
                      opcoes: opcoesDe(GrupoDeFiltro.saude, const []),
                      marcadas: _filtros.de(GrupoDeFiltro.saude),
                      aoMudar: (opcoes) => setState(
                        () => _filtros = _filtros.comGrupo(
                          GrupoDeFiltro.saude,
                          opcoes,
                        ),
                      ),
                    ),
                    Text(
                      'Na saúde, aparecem só os animais com todos os '
                      'cuidados marcados.',
                      style: TextStyle(fontSize: 12, color: context.cores.textoFraco),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                // Sem nenhum animal que combine, aplicar só esvaziaria o
                // feed: o botão fica desativado até a pessoa afrouxar o filtro
                onPressed: quantos == 0
                    ? null
                    : () => Navigator.pop(context, _filtros),
                style: FilledButton.styleFrom(
                  backgroundColor: context.cores.principal,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(
                  quantos == 0
                      ? 'Nenhum animal combina'
                      : quantos == 1
                      ? 'Mostrar 1 animal'
                      : 'Mostrar $quantos animais',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Cartão que agrupa os filtros, no mesmo estilo do cartão do cadastro
class _Cartao extends StatelessWidget {
  const _Cartao({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final filho in children) ...[const SizedBox(height: 10), filho],
        ],
      ),
    );
  }
}

// Rótulo pequeno exibido acima de cada grupo de filtro
class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: context.cores.textoFraco,
    ),
  );
}

// Abas para os grupos curtos (espécie, porte, sexo e saúde). Permitem marcar
// várias opções ou nenhuma
class _Abas extends StatelessWidget {
  const _Abas({
    required this.opcoes,
    required this.marcadas,
    required this.aoMudar,
  });

  final List<String> opcoes;
  final Set<String> marcadas;
  final ValueChanged<Set<String>> aoMudar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        segments: [
          for (final opcao in opcoes)
            ButtonSegment(value: opcao, label: Text(comMaiuscula(opcao))),
        ],
        selected: marcadas,
        multiSelectionEnabled: true,
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        onSelectionChanged: aoMudar,
        style: estiloDasAbas(context, context.cores.fundo),
      ),
    );
  }
}
