import 'package:flutter/material.dart';
import '../tema/cores.dart';

// Chip das abas adoção / perdidos / resgate.
class ChipFiltro extends StatelessWidget {
  final String rotulo;
  final bool selecionado;
  final VoidCallback aoTocar;

  const ChipFiltro({
    super.key,
    required this.rotulo,
    required this.selecionado,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? Cores.principal : Cores.cartao,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? Cores.principal : Cores.borda,
          ),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            color: selecionado ? Colors.white : Cores.texto,
            fontWeight: selecionado ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
