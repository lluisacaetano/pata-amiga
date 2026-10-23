// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo cadastro_animal.dart: tela de cadastro de animal.
import 'telas/cadastro_animal.dart';
// Arquivo cores.dart: tema claro do app.
import 'tema/cores.dart';

// Ponto de entrada alternativo: abre direto a tela de cadastro de animal, sem
// login, feed nem estado compartilhado. Serve para testar o formulário
// isoladamente. Uso: flutter run -t lib/main_cadastro.dart
void main() {
  runApp(
    MaterialApp(
      title: 'Pata Amiga',
      debugShowCheckedModeBanner: false,
      theme: temaPataAmiga(),
      home: const CadastroAnimal(),
    ),
  );
}
