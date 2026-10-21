import 'package:flutter/material.dart';

import '../tema/cores.dart';

// Uma opção fixa no rodapé da lista, em verde: o valor que ela escolhe e o
// texto que aparece
typedef OpcaoFixa = ({String valor, String texto});

// O select com busca do bairro e da raça, no cadastro e nos filtros do feed:
// a caixa é a mesma dos outros campos, e digitar filtra a lista. As opções
// fixas ("Outro bairro", "Sem raça definida", "Todas as raças") ficam sempre
// no rodapé, mesmo quando nada combina com o que foi digitado. Nos filtros, um
// X limpa a escolha
class SelecaoComBusca extends StatefulWidget {
  final String rotulo;
  final String dica;
  final bool habilitada;
  final TextEditingController controlador;
  final Iterable<String> Function(String digitado) opcoes;
  // A opção da lista que corresponde ao texto, ou null
  final String? Function(String texto) daLista;
  final List<OpcaoFixa> rodape;
  // O X para limpar, nos filtros; no cadastro fica a seta
  final bool limpavel;
  final bool comErro;
  // Nos filtros dá para escolher várias: as escolhidas viram etiquetas abaixo
  // do campo, ganham um ✓ na lista, e aoEscolher passa a marcar ou desmarcar.
  // Sem elas, o campo guarda uma escolha só, como no cadastro
  final Set<String>? marcadas;
  final ValueChanged<String?> aoEscolher;

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

  void _limpar() {
    widget.controlador.clear();
    // Com várias, o X só apaga a busca; as escolhidas saem nas etiquetas
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
          widget.rotulo.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Cores.textoFraco,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, restricoes) => RawAutocomplete<String>(
            textEditingController: widget.controlador,
            focusNode: _foco,
            // Sem nenhuma opção achada a lista sumiria, e com ela o
            // rodapé; o marcador mantém as opções fixas aparecendo
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
              // Com várias, o campo volta vazio para buscar a próxima. Só
              // depois da seleção, senão o campo não refaz a lista
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
                  style: const TextStyle(fontSize: 15),
                  textCapitalization: TextCapitalization.words,
                  // Só conta como escolhido o que bate com a lista
                  onChanged: (texto) {
                    if (!_varias) widget.aoEscolher(widget.daLista(texto));
                    if (widget.limpavel) setState(() {});
                  },
                  decoration: _caixa(
                    widget.dica,
                    comErro: widget.comErro,
                    acao: widget.limpavel && controlador.text.isNotEmpty
                        ? IconButton(
                            onPressed: _limpar,
                            tooltip: 'Limpar ${widget.rotulo.toLowerCase()}',
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Cores.textoFraco,
                            ),
                          )
                        : const Icon(
                            Icons.keyboard_arrow_down,
                            color: Cores.textoFraco,
                          ),
                  ),
                ),
            optionsViewBuilder: (context, escolher, opcoes) {
              // A lista sai na hora do que está escrito: as opções podem ter
              // mudado por fora, como as raças quando a espécie muda
              final daLista = widget
                  .opcoes(widget.controlador.text)
                  .where((opcao) => !fixas.contains(opcao))
                  .toList();
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Cores.cartao,
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
                        // Fica fixo no rodapé: quem não acha a opção não
                        // precisa rolar a lista inteira para descobrir a saída
                        if (widget.rodape.isNotEmpty)
                          const Divider(height: 1, color: Cores.borda),
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
        // As escolhidas numa linha só; se não couberem, a linha rola para o
        // lado, como a faixa de filtros do feed
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
                      backgroundColor: Cores.principalClara,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        color: Cores.principal,
                        fontWeight: FontWeight.w600,
                      ),
                      deleteIconColor: Cores.principal,
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
          const Padding(
            padding: EdgeInsets.only(top: 5, left: 2),
            child: Text(
              'Campo obrigatório',
              style: TextStyle(fontSize: 12, color: Cores.destaque),
            ),
          ),
      ],
    );
  }
}

// A mesma caixa dos campos do cadastro
InputDecoration _caixa(String dica, {bool comErro = false, Widget? acao}) =>
    InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Cores.fundo,
      hintText: dica,
      suffixIcon: acao,
      hintStyle: const TextStyle(fontSize: 14, color: Cores.textoFraco),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: comErro ? Cores.destaque : Cores.borda,
          width: comErro ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: comErro ? Cores.destaque : Cores.principal,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.borda),
      ),
    );

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
                  color: destaque || marcada ? Cores.principal : Cores.texto,
                  fontWeight: destaque || marcada
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            if (marcada)
              const Icon(Icons.check, size: 18, color: Cores.principal),
          ],
        ),
      ),
    );
  }
}
