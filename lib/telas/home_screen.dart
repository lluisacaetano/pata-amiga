// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Ação vazia usada quando a tela é criada sem callback de saída
void _noop() {}

// Tela inicial mínima, com saudação e botão de sair
class HomeScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    VoidCallback? onLogout,
  }) : onLogout = onLogout ?? _noop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pata Amiga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bem-vindo! 🐾'),
          ],
        ),
      ),
    );
  }
}

// Variante sem ação de saída, usada pela rota AppRoutes.home
class SuaTelaHome extends HomeScreen {
  const SuaTelaHome({super.key}) : super(onLogout: _noop);
}

// Variante que recebe a ação de saída pelo construtor
class TelaInicial extends HomeScreen {
  const TelaInicial({
    super.key,
    required VoidCallback aoSair,
  }) : super(onLogout: aoSair);
}