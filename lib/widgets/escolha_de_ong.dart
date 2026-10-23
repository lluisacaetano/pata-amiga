// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo racas.dart: busca sem acentos (buscarNaLista).
import '../dados/racas.dart';
// Arquivo ong.dart: modelo da ONG.
import '../modelos/ong.dart';
// Arquivo ong_service.dart: serviço que busca as ONGs na API.
import '../services/ong_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo escolha_de_tipo.dart: estilo padrão das abas.
import 'escolha_de_tipo.dart';
// Arquivo selecao_com_busca.dart: campo de seleção com busca.
import 'selecao_com_busca.dart';

// Pergunta "Você faz parte de alguma ONG ou abrigo?" usada em "Criar conta"
// e "Editar perfil". Com "Sim", carrega as ONGs em ordem alfabética para a
// pessoa escolher. A escolha é um pedido de entrada, que precisa ser
// aprovado por quem administra a ONG
class EscolhaDeOng extends StatefulWidget {
  final OngService? servico;
  final Ong? escolhida;
  final ValueChanged<Ong?> aoEscolher;
  // Estilo da pergunta, para seguir os rótulos da tela que usa o widget
  final TextStyle? estiloDaPergunta;

  const EscolhaDeOng({
    super.key,
    this.servico,
    required this.escolhida,
    required this.aoEscolher,
    this.estiloDaPergunta,
  });

  @override
  State<EscolhaDeOng> createState() => _EscolhaDeOngState();
}

class _EscolhaDeOngState extends State<EscolhaDeOng> {
  late final _servico = widget.servico ?? OngService();
  late bool _fazParte = widget.escolhida != null;
  List<Ong>? _ongs;
  bool _semConexao = false;
  final _busca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _busca.text = widget.escolhida?.nome ?? '';
    // Já nasce com uma ONG escolhida: carrega a lista para poder trocá-la
    if (_fazParte) _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  // ONG cujo nome corresponde ao texto, ignorando acentos e maiúsculas
  Ong? _pelaNome(List<Ong> ongs, String texto) => ongs
      .where((ong) => Ong.nomeComparavel(ong.nome) == Ong.nomeComparavel(texto))
      .firstOrNull;

  // Busca as ONGs na API e ordena pelo nome. Só é chamada após o "Sim" ou
  // quando já há uma ONG escolhida, para não carregar a lista sem necessidade
  Future<void> _carregar() async {
    setState(() => _semConexao = false);
    try {
      final ongs = await _servico.buscarOngs()
        ..sort(
          (a, b) =>
              Ong.nomeComparavel(a.nome).compareTo(Ong.nomeComparavel(b.nome)),
        );
      if (mounted) setState(() => _ongs = ongs);
    } on Exception {
      if (mounted) setState(() => _semConexao = true);
    }
  }

  // Trata a resposta: "Não" limpa a escolha; "Sim" carrega a lista
  void _responder(bool fazParte) {
    setState(() => _fazParte = fazParte);
    if (!fazParte) {
      widget.aoEscolher(null);
    } else if (_ongs == null) {
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ongs = _ongs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Você faz parte de alguma ONG ou abrigo?',
          style:
              widget.estiloDaPergunta ??
              TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.cores.texto,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Não')),
              ButtonSegment(value: true, label: Text('Sim')),
            ],
            selected: {_fazParte},
            showSelectedIcon: false,
            onSelectionChanged: (escolha) => _responder(escolha.first),
            style: estiloDasAbas(context, context.cores.fundo),
          ),
        ),
        if (_fazParte) ...[
          const SizedBox(height: 12),
          if (_semConexao)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Não foi possível carregar as ONGs.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.cores.destaque,
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
            )
          else if (ongs == null)
            Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: context.cores.principal,
                ),
              ),
            )
          else if (ongs.isEmpty)
            Text(
              'Nenhuma ONG cadastrada ainda.',
              style: TextStyle(fontSize: 13, color: context.cores.textoFraco),
            )
          else ...[
            SelecaoComBusca(
              // Com estilo próprio, rótulo e texto seguem os campos da tela
              rotulo: widget.estiloDaPergunta == null ? 'ONG' : 'Qual ONG?',
              estiloDoRotulo: widget.estiloDaPergunta,
              estiloDoTexto: widget.estiloDaPergunta == null
                  ? null
                  : const TextStyle(fontFamily: 'Roboto', fontSize: 16),
              dica: 'Digite para buscar a ONG',
              controlador: _busca,
              opcoes: (digitado) =>
                  buscarNaLista([for (final ong in ongs) ong.nome], digitado),
              daLista: (texto) => _pelaNome(ongs, texto)?.nome,
              aoEscolher: (nome) => widget.aoEscolher(
                nome == null ? null : _pelaNome(ongs, nome),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Quem administra a ONG recebe o seu pedido e precisa aprovar antes '
              'de você publicar animais em nome dela.',
              style: TextStyle(fontSize: 12, color: context.cores.textoFraco),
            ),
          ],
        ],
      ],
    );
  }
}
