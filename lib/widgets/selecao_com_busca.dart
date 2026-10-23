// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Opção fixa exibida em destaque no rodapé da lista: [valor] é o que se
// escolhe e [texto], o que aparece
typedef OpcaoFixa = ({String valor, String texto});

// Campo de seleção com busca (autocomplete), usado para bairro, raça e ONG
// no cadastro e nos filtros do feed. Digitar filtra as opções. As opções
// fixas do [rodape] ("Outro bairro", "Sem raça definida" etc.) aparecem
// sempre, mesmo sem resultado na busca. Funciona com escolha única ou, com
// [marcadas], com várias escolhas
class SelecaoComBusca extends StatefulWidget {
  final String rotulo;
  final String dica;
  final bool habilitada;
  final TextEditingController controlador;
  final Iterable<String> Function(String digitado) opcoes;
  // Devolve a opção da lista correspondente ao texto digitado, ou null
  final String? Function(String texto) daLista;
  final List<OpcaoFixa> rodape;
  // Mostra um X para limpar o campo em vez da seta de lista
  final bool limpavel;
  final bool comErro;
  // Ativa a escolha múltipla: as opções marcadas viram etiquetas abaixo do
  // campo e recebem um check na lista, e aoEscolher passa a alternar a
  // marcação. Nulo mantém escolha única
  final Set<String>? marcadas;
  final ValueChanged<String?> aoEscolher;
  // Estilos opcionais para telas com outro padrão de rótulo. Com
  // [estiloDoRotulo], o rótulo é exibido como escrito, sem maiúsculas
  final TextStyle? estiloDoRotulo;
  final TextStyle? estiloDoTexto;

  const SelecaoComBusca({
    super.key,
    required this.rotulo,
    required this.dica,
    this.habilitada = true,
    required this.controlador,
    required this.opcoes,
    required this.daLista,
    this.rodape = const [],
    this.limpavel = false,
    this.comErro = false,
    this.marcadas,
    required this.aoEscolher,
    this.estiloDoRotulo,
    this.estiloDoTexto,
  });

  @override
  State<SelecaoComBusca> createState() => _SelecaoComBuscaState();
}

class _SelecaoComBuscaState extends State<SelecaoComBusca> {
  final _foco = FocusNode();

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  bool get _varias => widget.marcadas != null;

  // Limpa o campo. Na escolha múltipla, apaga só a busca; as marcadas são
  // removidas pelas etiquetas
  void _limpar() {
    widget.controlador.clear();
    if (!_varias) widget.aoEscolher(null);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fixas = {for (final opcao in widget.rodape) opcao.valor};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.estiloDoRotulo == null
              ? widget.rotulo.toUpperCase()
              : widget.rotulo,
          style:
              widget.estiloDoRotulo ??
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: context.cores.textoFraco,
              ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, restricoes) => RawAutocomplete<String>(
            textEditingController: widget.controlador,
            focusNode: _foco,
            // Sem resultados a lista fecharia junto com o rodapé; devolver
            // uma opção fixa mantém a lista aberta com as opções fixas
            optionsBuilder: (digitado) {
              if (!widget.habilitada) return const [];
              final achados = widget
                  .opcoes(digitado.text)
                  .where((opcao) => !fixas.contains(opcao));
              return achados.isEmpty && fixas.isNotEmpty
                  ? [fixas.first]
                  : achados;
            },
            onSelected: (opcao) {
              FocusScope.of(context).unfocus();
              widget.aoEscolher(opcao);
              // Na escolha múltipla, limpa o campo para a próxima busca. A
              // limpeza fica para o quadro seguinte, senão a lista não é
              // refeita
              if (_varias) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  widget.controlador.clear();
                  setState(() {});
                });
              }
              setState(() {});
            },
            fieldViewBuilder: (context, controlador, foco, aoEnviar) =>
                TextField(
                  controller: controlador,
                  focusNode: foco,
                  enabled: widget.habilitada,
                  style: widget.estiloDoTexto ?? const TextStyle(fontSize: 15),
                  textCapitalization: TextCapitalization.words,
                  // Na escolha única, só conta como escolhido o texto que
                  // corresponde a uma opção da lista
                  onChanged: (texto) {
                    if (!_varias) widget.aoEscolher(widget.daLista(texto));
                    if (widget.limpavel) setState(() {});
                  },
                  decoration: _caixa(
                    context,
                    widget.dica,
                    comErro: widget.comErro,
                    acao: widget.limpavel && controlador.text.isNotEmpty
                        ? IconButton(
                            onPressed: _limpar,
                            tooltip: 'Limpar ${widget.rotulo.toLowerCase()}',
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: context.cores.textoFraco,
                            ),
                          )
                        : Icon(
                            Icons.keyboard_arrow_down,
                            color: context.cores.textoFraco,
                          ),
                  ),
                ),
            optionsViewBuilder: (context, escolher, opcoes) {
              // Recalcula a lista a partir do texto atual, pois as opções
              // podem mudar por fora (as raças mudam com a espécie)
              final daLista = widget
                  .opcoes(widget.controlador.text)
                  .where((opcao) => !fixas.contains(opcao))
                  .toList();
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: context.cores.cartao,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 300,
                      maxWidth: restricoes.maxWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shrinkWrap: true,
                            itemCount: daLista.length,
                            itemBuilder: (context, indice) {
                              final opcao = daLista[indice];
                              return _Opcao(
                                texto: opcao,
                                marcada:
                                    widget.marcadas?.contains(opcao) ?? false,
                                aoTocar: () => escolher(opcao),
                              );
                            },
                          ),
                        ),
                        // Opções fixas fora da rolagem, sempre visíveis
                        if (widget.rodape.isNotEmpty)
                          Divider(height: 1, color: context.cores.borda),
                        for (final fixa in widget.rodape)
                          _Opcao(
                            texto: fixa.texto,
                            destaque: true,
                            marcada:
                                widget.marcadas?.contains(fixa.valor) ?? false,
                            aoTocar: () => escolher(fixa.valor),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Etiquetas das opções marcadas, numa linha com rolagem horizontal
        if (widget.marcadas?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  for (final opcao in widget.marcadas!)
                    InputChip(
                      label: Text(opcao),
                      onDeleted: () => widget.aoEscolher(opcao),
                      deleteButtonTooltipMessage: 'Tirar $opcao',
                      backgroundColor: context.cores.principalClara,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: context.cores.principal,
                        fontWeight: FontWeight.w600,
                      ),
                      deleteIconColor: context.cores.principal,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (widget.comErro)
          Padding(
            padding: EdgeInsets.only(top: 5, left: 2),
            child: Text(
              'Campo obrigatório',
              style: TextStyle(fontSize: 12, color: context.cores.destaque),
            ),
          ),
      ],
    );
  }
}

// Decoração do campo, igual à dos campos do cadastro, com borda de erro
InputDecoration _caixa(
  BuildContext context,
  String dica, {
  bool comErro = false,
  Widget? acao,
}) => InputDecoration(
      isDense: true,
      filled: true,
      fillColor: context.cores.fundo,
      hintText: dica,
      suffixIcon: acao,
      hintStyle: TextStyle(fontSize: 14, color: context.cores.textoFraco),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: comErro ? context.cores.destaque : context.cores.borda,
          width: comErro ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: comErro ? context.cores.destaque : context.cores.principal,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.cores.borda),
      ),
    );

// Item da lista de opções. Opções fixas e marcadas ficam na cor principal
class _Opcao extends StatelessWidget {
  final String texto;
  final bool destaque;
  final bool marcada;
  final VoidCallback aoTocar;

  const _Opcao({
    required this.texto,
    required this.aoTocar,
    this.destaque = false,
    this.marcada = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 15,
                  color: destaque || marcada ? context.cores.principal : context.cores.texto,
                  fontWeight: destaque || marcada
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            if (marcada)
              Icon(Icons.check, size: 18, color: context.cores.principal),
          ],
        ),
      ),
    );
  }
}
