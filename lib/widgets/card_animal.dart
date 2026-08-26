import 'package:flutter/material.dart';
import '../modelos/animal.dart';
import '../tema/cores.dart';
import 'foto_animal.dart';

// Card de um animal no feed.
class CardAnimal extends StatelessWidget {
  final Animal animal;
  final bool curtido;
  final VoidCallback aoCurtir;
  final VoidCallback aoTocar;

  const CardAnimal({
    super.key,
    required this.animal,
    required this.curtido,
    required this.aoCurtir,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTocar,
      child: Container(
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              animal.resumo,
              style: const TextStyle(color: Cores.textoFraco),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Acao(
                  icone: curtido ? Icons.favorite : Icons.favorite_border,
                  rotulo: 'curtir',
                  destacado: curtido,
                  aoTocar: aoCurtir,
                ),
                _Acao(
                  icone: Icons.share_outlined,
                  rotulo: 'compartilhar',
                  aoTocar: () {},
                ),
                _Acao(
                  icone: Icons.chat_bubble_outline,
                  rotulo: 'conversar',
                  aoTocar: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Acao extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool destacado;
  final VoidCallback aoTocar;

  const _Acao({
    required this.icone,
    required this.rotulo,
    required this.aoTocar,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = destacado ? Cores.destaque : Cores.textoFraco;
    return InkWell(
      onTap: aoTocar,
      child: Row(
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 5),
          Text(rotulo, style: TextStyle(color: cor, fontSize: 13)),
        ],
      ),
    );
  }
}
