// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo animal.dart: tipo do registro do animal.
import '../modelos/animal.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Nome do tipo no singular, usado em etiquetas e no cadastro
String rotuloSingular(TipoRegistro tipo) => switch (tipo) {
  TipoRegistro.adocao => 'Adoção',
  TipoRegistro.perdido => 'Perdido',
  TipoRegistro.resgate => 'Resgate',
};

// Nome do tipo no plural, com inicial maiúscula, usado nas abas do feed
String rotuloPlural(TipoRegistro tipo) {
  final rotulo = tipo.rotulo;
  return rotulo[0].toUpperCase() + rotulo.substring(1);
}

// Estilo padrão das abas (SegmentedButton) do app: a opção selecionada fica
// preenchida na cor principal e as demais usam [fundoDaOpcao] com borda.
// Compartilhado pelo feed, cadastro, perfil e escolha de ONG
ButtonStyle estiloDasAbas(BuildContext context, Color fundoDaOpcao) =>
    ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected)
            ? context.cores.principal
            : fundoDaOpcao,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected)
            ? context.sobrePrincipal
            : context.cores.texto,
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

// Abas com os três tipos de registro (adoção, perdido e resgate). Começa sem
// seleção quando [escolhido] é nulo; [rotulo] define o texto de cada aba
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
        // Tocar na aba já escolhida devolve um conjunto vazio: nada muda
        onSelectionChanged: (escolha) {
          if (escolha.isNotEmpty) aoEscolher(escolha.first);
        },
        style: estiloDasAbas(context, fundoDaOpcao),
      ),
    );
  }
}
