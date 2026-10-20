import 'package:flutter/material.dart';

// O osso de comida de pet, desenhado à mão: o Material não tem um. No ponto
// que é comedouro e bebedouro ao mesmo tempo, leva uma gotinha d'água junto
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
    // O osso inclinado, como costuma aparecer nos desenhos de pet
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
    for (final x in [-metade, metade]) {
      for (final y in [-cabeca * 0.85, cabeca * 0.85]) {
        canvas.drawCircle(Offset(x, y), cabeca, tinta);
      }
    }
    canvas.restore();

    if (comAgua) {
      // A gotinha no canto de baixo
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
