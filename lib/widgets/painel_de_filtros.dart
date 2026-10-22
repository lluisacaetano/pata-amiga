import 'package:flutter/material.dart';

import '../modelos/filtros_do_feed.dart';
import '../tema/cores.dart';
import '../dados/bairros_formiga.dart';
import '../dados/racas.dart';
import '../modelos/animal.dart';
import '../modelos/ong.dart';
import 'escolha_de_tipo.dart';
import 'selecao_com_busca.dart';

// O painel que sobe de baixo com os filtros do feed, com o mesmo vocabulário
// do cadastro: um cartão branco, abas para as escolhas curtas e os selects com
// busca para raça e bairro. Marcar não muda o feed: ele só recarrega ao tocar
// em "Mostrar", e o botão já diz quantos vão aparecer
// A opção do rodapé da raça que desliga o filtro de raça
const todasAsRacas = 'Todas as raças';
// As opções do rodapé da ONG: marcar todas ou nenhuma de uma vez
const _todasAsOngs = 'Selecionar todas';
const _nenhumaOng = 'Desmarcar todas';

class PainelDeFiltros extends StatefulWidget {
  final FiltrosDoFeed inicial;
  // Os animais do feed: raças e bairros do filtro saem deles, para não
  // oferecer uma opção que não devolve ninguém
  final List<Animal> animais;
  final int Function(FiltrosDoFeed) contar;
  // As ONGs, para o select mostrar o nome de cada uma
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
  // Os campos de busca de raça e bairro; as escolhidas ficam nas etiquetas
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

  // Tocar numa raça marca ou desmarca; "Todas as raças" desmarca todas. As
  // raças escolhidas marcam sozinhas as espécies delas, porque não existe
  // Labrador gato; "Sem raça definida" serve às duas e não mexe na espécie
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

  // Só as ONGs que têm animais no feed, em ordem alfabética: escolher uma
  // que não traz ninguém seria uma falsa esperança, como nas raças
  List<Ong> get _ongsDisponiveis {
    final comAnimais = opcoesDe(GrupoDeFiltro.ong, widget.animais).toSet();
    return widget.ongs.where((ong) => comAnimais.contains('${ong.id}')).toList()
      ..sort(
        (a, b) =>
            Ong.nomeComparavel(a.nome).compareTo(Ong.nomeComparavel(b.nome)),
      );
  }

  // O select mostra o nome; o filtro guarda o id
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

  // Trocar a espécie apaga as raças que não são dela, como no cadastro
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

  void _limpar() {
    _raca.clear();
    _bairro.clear();
    _ong.clear();
    setState(() => _filtros = const FiltrosDoFeed());
  }

  // As raças dos animais cadastrados, só da espécie marcada quando houver
  // uma; "Sem raça definida" vai para o rodapé
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
                onPressed: () => Navigator.pop(context, _filtros),
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

// O mesmo cartão do cadastro: branco, borda clara e canto de 16
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

// O rótulo pequeno em cima de cada escolha, como no cadastro
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

// As escolhas curtas (espécie, porte, sexo) nas abas do feed, aqui deixando
// marcar mais de uma ou nenhuma
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
            ButtonSegment(value: opcao, label: Text(rotuloDaOpcao(opcao))),
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
