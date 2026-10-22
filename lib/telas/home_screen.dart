import 'package:flutter/material.dart';

void _noop() {}

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

class SuaTelaHome extends HomeScreen {
  const SuaTelaHome({super.key}) : super(onLogout: _noop);
}

class TelaInicial extends HomeScreen {
  const TelaInicial({
    super.key,
    required VoidCallback aoSair,
  }) : super(onLogout: aoSair);
}