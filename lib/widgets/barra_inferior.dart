import 'package:flutter/material.dart';

import '../tema/cores.dart';

// O aviso que as telas ainda não construídas dão quando alguém toca nelas
void avisarProximaSprint(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Esta tela entra em uma próxima sprint.'),
        duration: Duration(seconds: 2),
      ),
    );
}

class BarraInferior extends StatelessWidget {
  final int atual;
  final ValueChanged<int>? aoTocar;

  const BarraInferior({super.key, this.atual = 0, this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: atual,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Cores.cartao,
      onTap: aoTocar,
      selectedItemColor: Cores.principal,
      unselectedItemColor: Cores.textoFraco,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Início'),
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Mapa'),
        BottomNavigationBarItem(
          icon: Icon(Icons.report_outlined),
          label: 'Reportar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
