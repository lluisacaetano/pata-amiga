import 'package:flutter/material.dart';

import '../modelos/animal.dart';
import '../tema/cores.dart';

String rotuloSingular(TipoRegistro tipo) => switch (tipo) {
  TipoRegistro.adocao => 'Adoção',
  TipoRegistro.perdido => 'Perdido',
  TipoRegistro.resgate => 'Resgate',
};

String rotuloPlural(TipoRegistro tipo) {
  final rotulo = tipo.rotulo;
  return rotulo[0].toUpperCase() + rotulo.substring(1);
}

class EscolhaDeTipo extends StatelessWidget {
  final TipoRegistro? escolhido;
  final ValueChanged<TipoRegistro> aoEscolher;
  final String Function(TipoRegistro) rotulo;
  final Color fundoDaOpcao;

  const EscolhaDeTipo({
    super.key,
    required this.escolhido,
    required this.aoEscolher,
    required this.rotulo,
    required this.fundoDaOpcao,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<TipoRegistro>(
        segments: [
          for (final tipo in TipoRegistro.values)
            ButtonSegment(value: tipo, label: Text(rotulo(tipo))),
        ],
        selected: escolhido == null ? const <TipoRegistro>{} : {escolhido!},
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        onSelectionChanged: (escolha) => aoEscolher(escolha.first),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? Cores.principal
                : fundoDaOpcao,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? Colors.white
                : Cores.texto,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: Cores.borda)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
