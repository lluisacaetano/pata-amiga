import 'package:flutter/material.dart';

import '../tema/cores.dart';

// A caixa de um cuidado do animal (castrado, vacinado, vermifugado)
class Cuidado extends StatelessWidget {
  final String rotulo;
  final bool marcado;

  const Cuidado({super.key, required this.rotulo, required this.marcado});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: marcado ? context.cores.principalClara : context.cores.fundo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: marcado ? context.cores.principal : context.cores.borda),
      ),
      child: Text(
        rotulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: marcado ? context.cores.principal : context.cores.textoFraco,
        ),
      ),
    );
  }
}
