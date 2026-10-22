import 'package:flutter/material.dart';

import '../dados/racas.dart';
import '../modelos/ong.dart';
import '../services/ong_service.dart';
import '../tema/cores.dart';
import 'escolha_de_tipo.dart';
import 'selecao_com_busca.dart';

// "Você faz parte de alguma ONG?": com o sim, aparecem as ONGs cadastradas
// em ordem alfabética para escolher. Escolher só pede para entrar: quem
// administra a ONG aprova antes de a pessoa ter acesso. Serve ao "Criar conta" e
// ao "Editar perfil"
class EscolhaDeOng extends StatefulWidget {
  final OngService? servico;
  final Ong? escolhida;
  final ValueChanged<Ong?> aoEscolher;
  // No "Criar conta" a pergunta segue os rótulos daquela tela
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
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Ong? _pelaNome(List<Ong> ongs, String texto) => ongs
      .where((ong) => Ong.nomeComparavel(ong.nome) == Ong.nomeComparavel(texto))
      .firstOrNull;

  // As ONGs só são buscadas com o sim: quem não faz parte de nenhuma não
  // espera a lista carregar
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
              const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Cores.texto,
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
            style: estiloDasAbas(Cores.fundo),
          ),
        ),
        if (_fazParte) ...[
          const SizedBox(height: 12),
          if (_semConexao)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Não foi possível carregar as ONGs.',
                    style: TextStyle(fontSize: 13, color: Cores.destaque),
                  ),
                ),
                TextButton(
                  onPressed: _carregar,
                  style: TextButton.styleFrom(foregroundColor: Cores.principal),
                  child: const Text('Tentar de novo'),
                ),
              ],
            )
          else if (ongs == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: Cores.principal),
              ),
            )
          else if (ongs.isEmpty)
            const Text(
              'Nenhuma ONG cadastrada ainda.',
              style: TextStyle(fontSize: 13, color: Cores.textoFraco),
            )
          else ...[
            // O mesmo select com busca do bairro e da raça, em ordem
            // alfabética
            SelecaoComBusca(
              // No "Criar conta", o rótulo e o texto seguem os outros campos
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
            const Text(
              'Quem administra a ONG recebe o seu pedido e precisa aprovar antes '
              'de você publicar animais em nome dela.',
              style: TextStyle(fontSize: 12, color: Cores.textoFraco),
            ),
          ],
        ],
      ],
    );
  }
}
