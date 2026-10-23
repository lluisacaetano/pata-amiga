// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Caixa que indica um cuidado de saúde do animal (castrado, vacinado ou
// vermifugado). Fica preenchida em verde quando [marcado] e neutra quando não
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
