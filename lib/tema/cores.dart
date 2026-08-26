import 'package:flutter/material.dart';

// Paleta do Pata Amiga.
class Cores {
  static const Color principal = Color(0xFF3F7D58);
  static const Color principalClara = Color(0xFFE3F0E7);
  static const Color fundo = Color(0xFFFAF8F5);
  static const Color cartao = Colors.white;
  static const Color texto = Color(0xFF2B2B2B);
  static const Color textoFraco = Color(0xFF6E6E6E);
  static const Color borda = Color(0xFFDCD8D2);
  static const Color destaque = Color(0xFFD35D4E);
}

ThemeData temaPataAmiga() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Cores.fundo,
    colorScheme: base.colorScheme.copyWith(
      primary: Cores.principal,
      surface: Cores.cartao,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Cores.texto,
      displayColor: Cores.texto,
    ),
  );
}
