// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Desenho do pino: círculo na cor da camada com um símbolo dentro e uma
// ponta embaixo que marca o local exato
class PinoDaPatinha extends StatelessWidget {
  const PinoDaPatinha({
    super.key,
    required this.cor,
    this.tamanho = 38,
    this.simbolo,
  });

  final Color cor;
  final double tamanho;
  // Símbolo dentro do círculo; sem ele, usa a patinha
  final Widget? simbolo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho + 10,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Ponta: um quadrado girado 45 graus, metade escondida pelo círculo
          Positioned(
            bottom: 2,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(width: 12, height: 12, color: cor),
            ),
          ),
          Container(
            width: tamanho,
            height: tamanho,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child:
                simbolo ??
                Icon(Icons.pets, color: Colors.white, size: tamanho * 0.5),
          ),
        ],
      ),
    );
  }
}
