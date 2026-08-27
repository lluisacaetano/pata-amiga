import 'package:flutter/material.dart';

import '../tema/cores.dart';

class CadastroAnimal extends StatefulWidget {
  const CadastroAnimal({super.key});

  @override
  State<CadastroAnimal> createState() => _CadastroAnimalState();
}

class _CadastroAnimalState extends State<CadastroAnimal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset('assets/marca/pata.png', width: 26),
            const SizedBox(width: 6),
            const Text(
              'PATA\nAMIGA',
              style: TextStyle(
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.bold,
                color: Cores.principal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            color: Cores.texto,
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'CADASTRAR ANIMAL',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
