import 'package:flutter/material.dart';

class CadastroAnimal extends StatelessWidget {
  const CadastroAnimal({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Cadastro do animal'),
      ),
    );
  }
}

// ============================================
// CUSTOM PAINTERS
// ============================================

class PawPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Centro
    canvas.drawCircle(Offset(centerX, centerY), 6, paint);

    // Dedos
    final fingerRadius = 3.5;
    final fingerDistance = 10.0;

    canvas.drawCircle(
      Offset(centerX, centerY - fingerDistance),
      fingerRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX, centerY + fingerDistance),
      fingerRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX - fingerDistance, centerY),
      fingerRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX + fingerDistance, centerY),
      fingerRadius,
      paint,
    );
  }

  @override
  bool shouldRepaint(PawPainter oldDelegate) => false;
}