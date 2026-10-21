import 'package:flutter/material.dart';

import 'foto_animal.dart';

// As fotos do animal, uma de cada vez, com setas nos cantos e bolinhas dizendo
// em qual se está. As setas aparecem sempre, e apagam quando não há para onde ir.
class GaleriaAnimal extends StatefulWidget {
  final List<String> fotos;
  final double altura;

  const GaleriaAnimal({super.key, required this.fotos, this.altura = 280});

  @override
  State<GaleriaAnimal> createState() => _GaleriaAnimalState();
}

class _GaleriaAnimalState extends State<GaleriaAnimal> {
  final _paginas = PageController();
  int _atual = 0;

  bool get _temAnterior => _atual > 0;
  bool get _temProxima => _atual < widget.fotos.length - 1;

  void _irPara(BuildContext context, int indice) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _paginas.jumpToPage(indice);
    } else {
      _paginas.animateToPage(
        indice,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.altura,
      child: Stack(
        children: [
          Positioned.fill(child: _fotos()),
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _Seta(
                icone: Icons.chevron_left,
                dica: 'Foto anterior',
                aoTocar: _temAnterior
                    ? () => _irPara(context, _atual - 1)
                    : null,
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _Seta(
                icone: Icons.chevron_right,
                dica: 'Próxima foto',
                aoTocar: _temProxima
                    ? () => _irPara(context, _atual + 1)
                    : null,
              ),
            ),
          ),
          if (widget.fotos.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var indice = 0; indice < widget.fotos.length; indice++)
                    Container(
                      key: ValueKey('bolinha-$indice'),
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: indice == _atual ? Colors.white : Colors.white54,
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 4),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Com uma foto só, ou nenhuma, não há o que deslizar
  Widget _fotos() {
    if (widget.fotos.length <= 1) {
      return FotoAnimal(
        caminho: widget.fotos.isEmpty ? '' : widget.fotos.first,
        altura: widget.altura,
      );
    }

    return PageView.builder(
      controller: _paginas,
      itemCount: widget.fotos.length,
      onPageChanged: (indice) => setState(() => _atual = indice),
      itemBuilder: (_, indice) =>
          FotoAnimal(caminho: widget.fotos[indice], altura: widget.altura),
    );
  }
}

// Seta sobre a foto, sem fundo: a sombra é o que a segura em foto clara
class _Seta extends StatelessWidget {
  final IconData icone;
  final String dica;
  final VoidCallback? aoTocar;

  const _Seta({required this.icone, required this.dica, this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icone,
        shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
      ),
      iconSize: 24,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      tooltip: dica,
      color: Colors.white,
      disabledColor: Colors.white54,
      onPressed: aoTocar,
    );
  }
}
