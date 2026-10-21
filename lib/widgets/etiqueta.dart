import 'package:flutter/material.dart';

import '../modelos/animal.dart';
import '../tema/cores.dart';

// Etiqueta ao lado do nome do animal: o tipo do registro, e o adotado
// quando for o caso. A cheia marca o desfecho, a clara só classifica
class Etiqueta extends StatelessWidget {
  final String texto;
  final bool cheia;

  const Etiqueta(this.texto, {super.key, this.cheia = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cheia ? context.cores.principal : context.cores.principalClara,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        comMaiuscula(texto),
        style: TextStyle(
          color: cheia ? Colors.white : context.cores.principal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
