// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo denuncia.dart: modelo da denúncia.
import '../modelos/denuncia.dart';
// Arquivo filtros_de_denuncia.dart: filtros da lista e as opções de cada
// grupo.
import '../modelos/filtros_de_denuncia.dart';
// Arquivo texto.dart: comparação de nomes sem acentos.
import '../modelos/texto.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo escolha_de_tipo.dart: estilo das abas.
import 'escolha_de_tipo.dart';
// Arquivo painel_de_filtros.dart: cartão, rótulo e abas do painel do feed.
import 'painel_de_filtros.dart';
// Arquivo selecao_com_busca.dart: seleção com campo de busca.
import 'selecao_com_busca.dart';

// Painel inferior com os filtros da lista de denúncias, no mesmo visual do
// painel do feed. As escolhas ficam em rascunho e só são aplicadas ao tocar
// no botão final, que devolve os filtros pelo Navigator.pop e já mostra
// quantas denúncias vão aparecer
class PainelDeFiltrosDeDenuncia extends StatefulWidget {
  const PainelDeFiltrosDeDenuncia({
    super.key,
    required this.inicial,
    required this.denuncias,
    required this.contar,
  });

  final FiltrosDeDenuncia inicial;
  // Denúncias da lista. As opções de bairro saem delas
  final List<Denuncia> denuncias;
  // Conta quantas denúncias combinam com os filtros, para o texto do botão
  final int Function(FiltrosDeDenuncia) contar;

  @override
  State<PainelDeFiltrosDeDenuncia> createState() =>
      _PainelDeFiltrosDeDenunciaState();
}

class _PainelDeFiltrosDeDenunciaState extends State<PainelDeFiltrosDeDenuncia> {
  late FiltrosDeDenuncia _filtros = widget.inicial;
  // Texto digitado na busca do bairro; os bairros marcados ficam em _filtros
  final _bairro = TextEditingController();

  @override
  void dispose() {
    _bairro.dispose();
    super.dispose();
  }

  // Limpa todos os filtros e o texto da busca do bairro
  void _limpar() {
    _bairro.clear();
    setState(() => _filtros = const FiltrosDeDenuncia());
  }

  // Abre o calendário de intervalo, sem datas futuras, e troca o atalho de
  // data pelo período escolhido
  Future<void> _escolherPeriodo() async {
    final hoje = DateTime.now();
    final atual = _filtros.periodo;
    final escolhido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(hoje.year, hoje.month, hoje.day),
      initialDateRange: atual == null
          ? null
          : DateTimeRange(start: atual.de, end: atual.ate),
      helpText: 'Registradas entre',
    );
    if (escolhido == null || !mounted) return;
    setState(
      () => _filtros = _filtros.comData(
        periodo: (de: escolhido.start, ate: escolhido.end),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quantos = widget.contar(_filtros);
    final bairros = opcoesDaDenuncia(GrupoDaDenuncia.bairro, widget.denuncias);
    final periodo = _filtros.periodo;
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
                child: CartaoDeFiltros(
                  children: [
                    // Os quatro tipos não cabem numa fileira sem quebrar as
                    // palavras: ficam em duas fileiras de duas abas, que
                    // marcam o mesmo grupo
                    RotuloDeFiltro(GrupoDaDenuncia.tipo.titulo),
                    for (final fileira in _emPares(
                      opcoesDaDenuncia(GrupoDaDenuncia.tipo, const []),
                    ))
                      AbasDeFiltro(
                        opcoes: fileira,
                        marcadas: _filtros
                            .de(GrupoDaDenuncia.tipo)
                            .where(fileira.contains)
                            .toSet(),
                        aoMudar: (opcoes) => setState(
                          () => _filtros = _filtros.comGrupo(
                            GrupoDaDenuncia.tipo,
                            {
                              for (final tipo in _filtros.de(
                                GrupoDaDenuncia.tipo,
                              ))
                                if (!fileira.contains(tipo)) tipo,
                              ...opcoes,
                            },
                          ),
                        ),
                      ),
                    for (final grupo in [
                      GrupoDaDenuncia.situacao,
                      GrupoDaDenuncia.especie,
                      GrupoDaDenuncia.porte,
                      GrupoDaDenuncia.sexo,
                    ]) ...[
                      RotuloDeFiltro(grupo.titulo),
                      AbasDeFiltro(
                        opcoes: opcoesDaDenuncia(grupo, const []),
                        marcadas: _filtros.de(grupo),
                        aoMudar: (opcoes) => setState(
                          () => _filtros = _filtros.comGrupo(grupo, opcoes),
                        ),
                      ),
                    ],
                    if (bairros.isNotEmpty)
                      SelecaoComBusca(
                        rotulo: 'Bairro',
                        dica: 'Digite para buscar o bairro',
                        controlador: _bairro,
                        opcoes: (digitado) => bairros.where(
                          (bairro) =>
                              semAcento(bairro).contains(semAcento(digitado)),
                        ),
                        daLista: (texto) => bairros
                            .where(
                              (bairro) => semAcento(bairro) == semAcento(texto),
                            )
                            .firstOrNull,
                        limpavel: true,
                        marcadas: _filtros.de(GrupoDaDenuncia.bairro),
                        aoEscolher: (bairro) {
                          if (bairro == null) return;
                          setState(
                            () => _filtros = _filtros.alternar(
                              GrupoDaDenuncia.bairro,
                              bairro,
                            ),
                          );
                        },
                      ),
                    const RotuloDeFiltro('Registrada'),
                    // Atalhos de data: só um por vez, e tocar no marcado
                    // tira o filtro
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<AtalhoDeData>(
                        segments: [
                          for (final atalho in AtalhoDeData.values)
                            ButtonSegment(
                              value: atalho,
                              label: Text(atalho.rotulo),
                            ),
                        ],
                        selected: {?_filtros.atalho},
                        emptySelectionAllowed: true,
                        showSelectedIcon: false,
                        onSelectionChanged: (escolha) => setState(
                          () => _filtros = _filtros.comData(
                            atalho: escolha.firstOrNull,
                          ),
                        ),
                        style: estiloDasAbas(context, context.cores.fundo),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _escolherPeriodo,
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: Text(
                        periodo == null
                            ? 'Escolher um período'
                            : 'De ${_data(periodo.de)} a ${_data(periodo.ate)}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.cores.principal,
                        backgroundColor: periodo == null
                            ? null
                            : context.cores.principalClara,
                        side: BorderSide(color: context.cores.principal),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                // Sem nenhuma denúncia que combine, aplicar só esvaziaria a
                // lista: o botão fica desativado até afrouxar o filtro
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
                      ? 'Nenhuma denúncia combina'
                      : quantos == 1
                      ? 'Mostrar 1 denúncia'
                      : 'Mostrar $quantos denúncias',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// As opções agrupadas de duas em duas, para as fileiras de abas
List<List<String>> _emPares(List<String> opcoes) => [
  for (var i = 0; i < opcoes.length; i += 2) opcoes.skip(i).take(2).toList(),
];

// A data no formato dd/mm/aaaa
String _data(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/${data.year}';
