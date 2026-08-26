import 'package:flutter/material.dart';

import '../tema/cores.dart';

class FeedAdocao extends StatelessWidget {
  const FeedAdocao({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        titleSpacing: 16,
        title: Row(
          children: [
            const Text(
              'PATA\nAMIGA',
              style: TextStyle(
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.bold,
                color: Cores.principal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'pesquisar',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: Cores.cartao,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Cores.borda),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Cores.borda),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: const SizedBox.expand(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Cores.principal,
        unselectedItemColor: Cores.textoFraco,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'adoção'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'mapa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_outlined),
            label: 'reportar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'perfil',
          ),
        ],
      ),
    );
  }
}
