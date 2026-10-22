import 'package:flutter/material.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../tema/cores.dart';
import 'foto_animal.dart';

// Card de um animal no feed.
class CardAnimal extends StatelessWidget {
  final Animal animal;
  final VoidCallback aoCompartilhar;
  final VoidCallback aoChamarNoWhatsApp;
  final VoidCallback aoTocar;

  const CardAnimal({
    super.key,
    required this.animal,
    required this.aoCompartilhar,
    required this.aoChamarNoWhatsApp,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final curtido = estado.estaCurtido(animal.nome);

    return GestureDetector(
      onTap: aoTocar,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cores.cartao,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cores.borda),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, restricoes) =>
                  FotoAnimal(caminho: animal.foto, altura: restricoes.maxWidth),
            ),
            const SizedBox(height: 12),
            Text(
              animal.nome.toUpperCase(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              animal.resumo,
              style: TextStyle(color: context.cores.textoFraco),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: context.cores.principal,
                ),
                const SizedBox(width: 4),
                Text(
                  '${animal.bairro}, ${animal.cidade}',
                  style: TextStyle(
                    color: context.cores.principal,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Há quanto tempo foi publicado, na mesma linha do local
                Text(
                  ' · ${animal.publicadoHa(DateTime.now())}',
                  style: TextStyle(color: context.cores.textoFraco, fontSize: 13),
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
                style: TextStyle(color: context.cores.texto, fontSize: 13),
              ),
            ],
            // Separa o que se lê do que se toca
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, thickness: 1, color: context.cores.borda),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Acao(
                  icone: curtido ? Icons.favorite : Icons.favorite_border,
                  rotulo: 'curtir',
                  destacado: curtido,
                  aoTocar: () => estado.alternarCurtida(animal.nome),
                ),
                _Acao(
                  icone: Icons.chat_bubble_outline,
                  rotulo: 'WhatsApp',
                  aoTocar: aoChamarNoWhatsApp,
                ),
                _Acao(
                  icone: Icons.share_outlined,
                  rotulo: 'compartilhar',
                  aoTocar: aoCompartilhar,
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
    final cor = destacado ? context.cores.principal : context.cores.textoFraco;
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
