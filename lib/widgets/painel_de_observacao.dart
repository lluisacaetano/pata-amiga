// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Resultado do painel: a situação escolhida (quando há opções) e a observação
typedef ObservacaoEscolhida<T> = ({T? escolha, String observacao});

// Abre o painel inferior que registra uma mudança de situação com observação
// obrigatória. Com [opcoes], a pessoa também escolhe a nova situação. Devolve
// nulo se a pessoa cancelar
Future<ObservacaoEscolhida<T>?> pedirObservacao<T>(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String rotuloPrincipal,
  List<(T, String)> opcoes = const [],
}) => showModalBottomSheet<ObservacaoEscolhida<T>>(
  context: context,
  backgroundColor: context.cores.cartao,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => PainelDeObservacao<T>(
    titulo: titulo,
    texto: texto,
    rotuloPrincipal: rotuloPrincipal,
    opcoes: opcoes,
  ),
);

// Conteúdo do painel: título, explicação, as opções de situação (se houver),
// o campo da observação e os botões. Salvar só funciona com a situação
// escolhida e a observação preenchida; o campo vazio fica em vermelho
class PainelDeObservacao<T> extends StatefulWidget {
  const PainelDeObservacao({
    super.key,
    required this.titulo,
    required this.texto,
    required this.rotuloPrincipal,
    this.opcoes = const [],
  });

  final String titulo;
  final String texto;
  final String rotuloPrincipal;
  final List<(T, String)> opcoes;

  @override
  State<PainelDeObservacao<T>> createState() => _PainelDeObservacaoState<T>();
}

class _PainelDeObservacaoState<T> extends State<PainelDeObservacao<T>> {
  final _observacao = TextEditingController();
  T? _escolha;
  bool _tentou = false;

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  // Confere os obrigatórios e devolve o resultado a quem abriu o painel
  void _salvar() {
    setState(() => _tentou = true);
    final semEscolha = widget.opcoes.isNotEmpty && _escolha == null;
    if (semEscolha || _observacao.text.trim().isEmpty) return;
    Navigator.pop(context, (
      escolha: _escolha,
      observacao: _observacao.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final semEscolha = _tentou && widget.opcoes.isNotEmpty && _escolha == null;
    final semObservacao = _tentou && _observacao.text.trim().isEmpty;
    return SafeArea(
      child: SingleChildScrollView(
        // Sobe junto com o teclado
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.cores.textoFraco,
                height: 1.4,
              ),
            ),
            if (widget.opcoes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final (valor, rotulo) in widget.opcoes)
                    ChoiceChip(
                      label: Text(rotulo),
                      selected: _escolha == valor,
                      onSelected: (_) => setState(() => _escolha = valor),
                      selectedColor: context.cores.principal,
                      backgroundColor: context.cores.fundo,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _escolha == valor
                            ? context.sobrePrincipal
                            : context.cores.texto,
                      ),
                      side: BorderSide(
                        color: semEscolha
                            ? context.cores.destaque
                            : context.cores.borda,
                      ),
                    ),
                ],
              ),
              if (semEscolha)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Escolha a nova situação.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.cores.destaque,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Text(
              'OBSERVAÇÃO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: context.cores.textoFraco,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _observacao,
              minLines: 3,
              maxLines: null,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_tentou) setState(() {});
              },
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Conte o que foi feito.',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: context.cores.textoFraco,
                ),
                filled: true,
                fillColor: context.cores.fundo,
                errorText: semObservacao ? 'Campo obrigatório' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.cores.borda),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.cores.borda),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.cores.principal),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _salvar,
              style: FilledButton.styleFrom(
                backgroundColor: context.cores.principal,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(widget.rotuloPrincipal),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: context.cores.textoFraco,
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
