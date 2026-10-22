import 'package:flutter/material.dart';

import '../routes/route_names.dart';
import '../tema/cores.dart';

// O aviso que as telas ainda não construídas dão quando alguém toca nelas.
// Enquanto a funcionalidade não existe, o toque avisa em vez de não fazer
// nada, para o usuário saber que o botão não está quebrado
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

// O que cada item da barra faz, igual em todas as telas. Fica aqui, num
// lugar só, para que uma tela nova entre na barra já funcionando: foi por
// cada tela ter a própria cópia que o Mapa ficou "em próxima sprint" fora
// do feed depois de pronto
void navegarPelaBarra(
  BuildContext context,
  int indice, {
  required int atual,
  VoidCallback? aoIrParaInicio,
}) {
  // Início sempre volta ao feed: detalhes e cadastro também o marcam
  if (indice == atual && indice != 0) return;
  final navegador = Navigator.of(context);
  switch (indice) {
    case 0:
      // O feed é sempre a primeira tela depois do login
      if (aoIrParaInicio != null) {
        aoIrParaInicio();
      } else {
        navegador.popUntil((rota) => rota.isFirst);
      }
    case 1:
      navegador.pushNamed(AppRoutes.mapa);
    case 2:
      navegador.pushNamed(AppRoutes.reportar);
    case 3:
      navegador.pushNamed(AppRoutes.perfilUsuario);
    default:
      avisarProximaSprint(context);
  }
}

class BarraInferior extends StatelessWidget {
  final int atual;
  // Só para quem precisa voltar ao feed de outro jeito, como os detalhes,
  // que devolvem o animal ao sair
  final VoidCallback? aoIrParaInicio;

  const BarraInferior({super.key, this.atual = 0, this.aoIrParaInicio});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: atual,
      type: BottomNavigationBarType.fixed,
      backgroundColor: context.cores.cartao,
      onTap: (indice) => navegarPelaBarra(
        context,
        indice,
        atual: atual,
        aoIrParaInicio: aoIrParaInicio,
      ),
      selectedItemColor: context.cores.principal,
      unselectedItemColor: context.cores.textoFraco,
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
