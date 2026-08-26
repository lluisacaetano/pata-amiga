import 'package:flutter/material.dart';

import '../modelos/animal.dart';
import '../tema/cores.dart';
import 'foto_animal.dart';

// Card de um animal no feed.
class CardAnimal extends StatelessWidget {
  final Animal animal;
  final bool curtido;
  final VoidCallback aoCurtir;
  final VoidCallback aoCompartilhar;
  final VoidCallback aoConversar;
  final VoidCallback aoTocar;

  const CardAnimal({
    super.key,
    required this.animal,
    required this.curtido,
    required this.aoCurtir,
    required this.aoCompartilhar,
    required this.aoConversar,
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              animal.resumo,
              style: const TextStyle(color: Cores.textoFraco),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: Cores.principal,
                ),
                const SizedBox(width: 4),
                Text(
                  '${animal.bairro}, ${animal.cidade}',
                  style: const TextStyle(
                    color: Cores.principal,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Em perdidos e resgates, onde e quando importa mais que o porte
            if (animal.tipo != TipoRegistro.adocao &&
                animal.observacoes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                animal.observacoes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Cores.texto, fontSize: 13),
              ),
            ],
            // Separa o que se lê do que se toca
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, thickness: 1, color: Cores.borda),
            ),
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
                  aoTocar: aoCompartilhar,
                ),
                _Acao(
                  icone: Icons.chat_bubble_outline,
                  rotulo: 'conversar',
                  aoTocar: aoConversar,
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
  final VoidCallback? aoTocar;

  const _Acao({
    required this.icone,
    required this.rotulo,
    this.destacado = false,
    this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = destacado ? Cores.principal : Cores.textoFraco;
    return GestureDetector(
      onTap: aoTocar,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icone, size: 18, color: cor),
            const SizedBox(width: 6),
            Text(rotulo, style: TextStyle(color: cor, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
