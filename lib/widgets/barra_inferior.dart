// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Navegação da barra inferior, centralizada para que todas as telas tenham o
// mesmo comportamento. [indice] é o item tocado e [atual], o item da tela
// aberta. Tocar no item atual não faz nada, exceto Início, que sempre volta
// ao feed
void navegarPelaBarra(
  BuildContext context,
  int indice, {
  required int atual,
  VoidCallback? aoIrParaInicio,
}) {
  // Telas como detalhes e cadastro também marcam Início como atual, por isso
  // o índice 0 nunca é ignorado
  if (indice == atual && indice != 0) return;
  final navegador = Navigator.of(context);
  switch (indice) {
    case 0:
      // O feed é a base da pilha; a tela pode fornecer a própria volta
      if (aoIrParaInicio != null) {
        aoIrParaInicio();
      } else {
        _voltarAoInicio(navegador);
      }
    case 1:
      navegador.pushNamed(AppRoutes.mapa);
    case 2:
      navegador.pushNamed(AppRoutes.reportar);
    case 3:
      navegador.pushNamed(AppRoutes.ongs);
    case 4:
      navegador.pushNamed(AppRoutes.perfilUsuario);
  }
}

// Desempilha as telas uma a uma com maybePop (e não popUntil) para que um
// formulário com alterações não salvas possa pedir confirmação. Para quando
// uma tela bloqueia a volta ou abre um diálogo
Future<void> _voltarAoInicio(NavigatorState navegador) async {
  // Rota do topo da pilha, lida sem desempilhar nada
  Route<dynamic>? topo() {
    Route<dynamic>? atual;
    navegador.popUntil((rota) {
      atual = rota;
      return true;
    });
    return atual;
  }

  while (navegador.canPop()) {
    final antes = topo();
    await navegador.maybePop();
    final depois = topo();
    if (identical(antes, depois) || depois is PopupRoute) return;
  }
}

// Barra de navegação inferior com Início, Mapa, Reportar, ONGs e Perfil.
// [atual] indica o item destacado
class BarraInferior extends StatelessWidget {
  final int atual;
  // Substitui a volta padrão ao feed, para telas que precisam devolver um
  // resultado ao sair (como os detalhes do animal)
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
          icon: Icon(Icons.volunteer_activism_outlined),
          label: 'ONGs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
