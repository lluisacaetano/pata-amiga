import 'package:flutter/material.dart';

import 'telas/cadastro_animal.dart';
import 'tema/cores.dart';

// Entrada temporária, só para abrir a tela de cadastro no emulador enquanto ela não está ligada ao feed
// Rodar com: flutter run -t lib/main_cadastro.dart
// APAGAR quando o botão de "+" do feed virar o caminho de entrada
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
