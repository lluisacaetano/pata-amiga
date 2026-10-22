import 'package:flutter/material.dart';

// Paleta do Pata Amiga.
class Cores {
  static const Color principal = Color(0xFF3F7D58);
  static const Color principalClara = Color(0xFFE3F0E7);
  static const Color fundo = Color(0xFFFAF8F5);
  static const Color cartao = Colors.white;
  static const Color texto = Color(0xFF2B2B2B);
  static const Color textoFraco = Color(0xFF6E6E6E);
  static const Color borda = Color(0xFFDCD8D2);
  static const Color destaque = Color(0xFFD35D4E);
  // Os pontos de alimentação no mapa: um ocre de ração, que convive com o
  // verde e o coral sem se confundir com eles
  static const Color alimentacao = Color(0xFFC98A2E);
  // Os bebedouros: um azul de água, suave como o resto da paleta
  static const Color agua = Color(0xFF4A86B4);
}

@immutable
class PaletaPataAmiga extends ThemeExtension<PaletaPataAmiga> {
  const PaletaPataAmiga({
    required this.principal,
    required this.principalClara,
    required this.fundo,
    required this.cartao,
    required this.texto,
    required this.textoFraco,
    required this.borda,
    required this.destaque,
    required this.alimentacao,
    required this.agua,
  });

  final Color principal;
  final Color principalClara;
  final Color fundo;
  final Color cartao;
  final Color texto;
  final Color textoFraco;
  final Color borda;
  final Color destaque;
  final Color alimentacao;
  final Color agua;

  static PaletaPataAmiga de(BuildContext context) {
    final tema = Theme.of(context);
    return tema.extension<PaletaPataAmiga>() ??
        PaletaPataAmiga(
          principal: tema.colorScheme.primary,
          principalClara: tema.colorScheme.primaryContainer,
          fundo: tema.scaffoldBackgroundColor,
          cartao: tema.colorScheme.surface,
          texto: tema.colorScheme.onSurface,
          textoFraco: tema.colorScheme.onSurfaceVariant,
          borda: tema.colorScheme.outline,
          destaque: Cores.destaque,
          alimentacao: Cores.alimentacao,
          agua: Cores.agua,
        );
  }

  @override
  PaletaPataAmiga copyWith({
    Color? principal,
    Color? principalClara,
    Color? fundo,
    Color? cartao,
    Color? texto,
    Color? textoFraco,
    Color? borda,
    Color? destaque,
    Color? alimentacao,
    Color? agua,
  }) => PaletaPataAmiga(
    principal: principal ?? this.principal,
    principalClara: principalClara ?? this.principalClara,
    fundo: fundo ?? this.fundo,
    cartao: cartao ?? this.cartao,
    texto: texto ?? this.texto,
    textoFraco: textoFraco ?? this.textoFraco,
    borda: borda ?? this.borda,
    destaque: destaque ?? this.destaque,
    alimentacao: alimentacao ?? this.alimentacao,
    agua: agua ?? this.agua,
  );

  @override
  PaletaPataAmiga lerp(
    covariant ThemeExtension<PaletaPataAmiga>? other,
    double t,
  ) {
    if (other is! PaletaPataAmiga) return this;
    return PaletaPataAmiga(
      principal: Color.lerp(principal, other.principal, t)!,
      principalClara: Color.lerp(principalClara, other.principalClara, t)!,
      fundo: Color.lerp(fundo, other.fundo, t)!,
      cartao: Color.lerp(cartao, other.cartao, t)!,
      texto: Color.lerp(texto, other.texto, t)!,
      textoFraco: Color.lerp(textoFraco, other.textoFraco, t)!,
      borda: Color.lerp(borda, other.borda, t)!,
      destaque: Color.lerp(destaque, other.destaque, t)!,
      alimentacao: Color.lerp(alimentacao, other.alimentacao, t)!,
      agua: Color.lerp(agua, other.agua, t)!,
    );
  }
}

extension CoresContexto on BuildContext {
  PaletaPataAmiga get cores => PaletaPataAmiga.de(this);
}

ThemeData temaPataAmiga({Brightness brilho = Brightness.light}) {
  final escuro = brilho == Brightness.dark;
  final paleta = PaletaPataAmiga(
    principal: escuro ? const Color(0xFF8DCEA0) : Cores.principal,
    principalClara: escuro ? const Color(0xFF253D2D) : Cores.principalClara,
    fundo: escuro ? const Color(0xFF101510) : Cores.fundo,
    cartao: escuro ? const Color(0xFF1C241E) : Cores.cartao,
    texto: escuro ? const Color(0xFFF3F5F3) : Cores.texto,
    textoFraco: escuro ? const Color(0xFFE0E5E1) : Cores.textoFraco,
    borda: escuro ? const Color(0xFF59645B) : Cores.borda,
    destaque: escuro ? const Color(0xFFFF9387) : Cores.destaque,
    alimentacao: escuro ? const Color(0xFFFFCB72) : Cores.alimentacao,
    agua: escuro ? const Color(0xFF91C8F0) : Cores.agua,
  );
  final base = ThemeData(
    brightness: brilho,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: paleta.principal,
      brightness: brilho,
      surface: paleta.cartao,
    ),
  );
  return base.copyWith(
    extensions: [paleta],
    scaffoldBackgroundColor: paleta.fundo,
    colorScheme: base.colorScheme.copyWith(
      primary: paleta.principal,
      onPrimary: escuro ? const Color(0xFF102016) : Colors.white,
      surface: paleta.cartao,
      onSurface: paleta.texto,
      outline: paleta.borda,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'Roboto',
      bodyColor: paleta.texto,
      displayColor: paleta.texto,
    ),
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(actionTextColor: paleta.principalClara),
    popupMenuTheme: PopupMenuThemeData(
      color: paleta.cartao,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: paleta.principal,
        foregroundColor: base.colorScheme.onPrimary,
      ),
    ),
  );
}
