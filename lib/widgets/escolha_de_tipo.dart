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

// Estilo das abas do app: a escolhida cheia no verde, as outras no fundo
// claro com borda. Usado no feed, no cadastro e no perfil, para que toda
// aba do app tenha a mesma cara
ButtonStyle estiloDasAbas(BuildContext context, Color fundoDaOpcao) =>
    ButtonStyle(
  backgroundColor: WidgetStateProperty.resolveWith(
    (estados) => estados.contains(WidgetState.selected)
        ? context.cores.principal
        : fundoDaOpcao,
  ),
  foregroundColor: WidgetStateProperty.resolveWith(
    (estados) =>
        estados.contains(WidgetState.selected) ? Colors.white : context.cores.texto,
  ),
  textStyle: WidgetStateProperty.resolveWith(
    (estados) => TextStyle(
      fontSize: 14,
      fontWeight: estados.contains(WidgetState.selected)
          ? FontWeight.w600
          : FontWeight.w500,
    ),
  ),
  side: WidgetStatePropertyAll(BorderSide(color: context.cores.borda)),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

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
        style: estiloDasAbas(context, fundoDaOpcao),
      ),
    );
  }
}
