// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Ícone de osso desenhado com CustomPaint, já que o Material Icons não tem
// um equivalente. Marca pontos de alimentação no mapa; com [comAgua], ganha
// uma gota para indicar comedouro e bebedouro no mesmo ponto
class IconeDeOsso extends StatelessWidget {
  final bool comAgua;
  final double tamanho;
  final Color cor;

  const IconeDeOsso({
    super.key,
    this.comAgua = false,
    this.tamanho = 20,
    this.cor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: CustomPaint(painter: _Osso(cor: cor, comAgua: comAgua)),
    );
  }
}

// Desenha o osso inclinado e, se pedido, a gota no canto inferior direito
class _Osso extends CustomPainter {
  _Osso({required this.cor, required this.comAgua});

  final Color cor;
  final bool comAgua;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tinta = Paint()..color = cor;

    canvas.save();
    // Gira o canvas em torno do centro para inclinar o osso
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-0.6);
    final comprimento = w * (comAgua ? 0.62 : 0.78);
    final grossura = h * 0.20;
    final cabeca = h * 0.14;
    final metade = comprimento / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: comprimento,
          height: grossura,
        ),
        Radius.circular(grossura / 2),
      ),
      tinta,
    );
    // Duas bolinhas em cada ponta formam as cabeças do osso
    for (final x in [-metade, metade]) {
      for (final y in [-cabeca * 0.85, cabeca * 0.85]) {
        canvas.drawCircle(Offset(x, y), cabeca, tinta);
      }
    }
    canvas.restore();

    if (comAgua) {
      // Gota d'água desenhada com duas curvas de Bézier
      final gota = Path()
        ..moveTo(w * 0.80, h * 0.56)
        ..quadraticBezierTo(w * 0.98, h * 0.80, w * 0.80, h * 0.96)
        ..quadraticBezierTo(w * 0.62, h * 0.80, w * 0.80, h * 0.56)
        ..close();
      canvas.drawPath(gota, tinta);
    }
  }

  @override
  bool shouldRepaint(_Osso antigo) =>
      antigo.cor != cor || antigo.comAgua != comAgua;
}
