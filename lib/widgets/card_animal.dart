import 'package:flutter/material.dart';

import '../modelos/animal.dart';
import '../tema/cores.dart';
import 'foto_animal.dart';

// Card de um animal no feed.
class CardAnimal extends StatelessWidget {
  final Animal animal;

  const CardAnimal({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FotoAnimal(caminho: animal.foto),
          const SizedBox(height: 12),
          Text(
            animal.nome.toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(animal.resumo, style: const TextStyle(color: Cores.textoFraco)),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Acao(icone: Icons.favorite_border, rotulo: 'curtir'),
              _Acao(icone: Icons.share_outlined, rotulo: 'compartilhar'),
              _Acao(icone: Icons.chat_bubble_outline, rotulo: 'conversar'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Acao extends StatelessWidget {
  final IconData icone;
  final String rotulo;

  const _Acao({required this.icone, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icone, size: 18, color: Cores.textoFraco),
          const SizedBox(width: 6),
          Text(
            rotulo,
            style: const TextStyle(color: Cores.textoFraco, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
