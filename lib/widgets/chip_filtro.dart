import 'package:flutter/material.dart';

import '../tema/cores.dart';

// Chip das abas adoção, perdidos e resgate
class ChipFiltro extends StatelessWidget {
  final String rotulo;
  final int quantidade;
  final bool selecionado;
  final VoidCallback aoTocar;

  const ChipFiltro({
    super.key,
    required this.rotulo,
    required this.quantidade,
    required this.selecionado,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTocar,
      behavior: HitTestBehavior.opaque,
      // O badge passa do limite do chip, então não pode ser recortado
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: selecionado ? Cores.principal : Cores.principalClara,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              // O rótulo vem em minúscula do modelo, e aqui é título de botão
              rotulo[0].toUpperCase() + rotulo.substring(1),
              style: TextStyle(
                color: selecionado ? Colors.white : Cores.principal,
                fontWeight: selecionado ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 21),
              height: 21,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Cores.cartao,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Cores.principal, width: 1.5),
              ),
              child: Text(
                '$quantidade',
                style: const TextStyle(
                  color: Cores.principal,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
