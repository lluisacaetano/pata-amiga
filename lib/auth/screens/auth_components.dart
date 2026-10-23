// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter/services: formatação de teclado (TextInputFormatter).
import 'package:flutter/services.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../../tema/cores.dart';

// Componentes visuais comuns às telas de entrada (boas-vindas, login,
// cadastro, recuperação de senha e recepção)

// Fundo em degradê das telas de entrada, com o conteúdo centralizado,
// rolável e limitado a 420 de largura. Adapta as cores ao tema escuro
class AuthBackground extends StatelessWidget {
  final Widget child;
  // Mostra a seta de voltar no canto superior esquerdo
  final bool comVoltar;

  const AuthBackground({
    super.key,
    required this.child,
    this.comVoltar = false,
  });

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: escuro
              ? [
                  context.cores.fundo,
                  context.cores.principalClara,
                  const Color(0xFF253329),
                ]
              : [
                  const Color(0xFFBFDCC8),
                  const Color(0xFFDCEBDD),
                  const Color(0xFFF2F5EE),
                  const Color(0xFFFFF1E5),
                ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: child,
                ),
              ),
            ),
            if (comVoltar)
              Positioned(
                top: 4,
                left: 12,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Voltar',
                  color: context.cores.principal,
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// A patinha da marca, usada como logotipo nas telas de entrada
class AuthBrandMark extends StatelessWidget {
  final double size;

  const AuthBrandMark({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/marca/pata.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Pata Amiga',
    );
  }
}

// Campo de formulário das telas de entrada: rótulo acima, ícone à esquerda
// e, opcionalmente, um botão à direita (como o de mostrar a senha)
class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixPressed,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.cores.borda),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.cores.texto,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          validator: validator,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: context.cores.texto,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.cores.textoFraco),
            prefixIcon: Icon(prefixIcon, size: 20, color: context.cores.textoFraco),
            suffixIcon: suffixIcon == null
                ? null
                : IconButton(
                    tooltip: obscureText ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: onSuffixPressed,
                    icon: Icon(suffixIcon, size: 20, color: context.cores.textoFraco),
                  ),
            filled: true,
            fillColor: context.cores.cartao.withValues(alpha: 0.9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: outline,
            enabledBorder: outline,
            focusedBorder: outline.copyWith(
              borderSide: BorderSide(color: context.cores.principal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// Botão de largura total das telas de entrada. O principal é preenchido de
// verde; o secundário é contornado. [leading] aparece antes do rótulo
class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final Widget? leading;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    final contents = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        Text(label),
      ],
    );

    if (primary) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: style.copyWith(
            backgroundColor: WidgetStatePropertyAll(context.cores.principal),
            foregroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: contents,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: style.copyWith(
          foregroundColor: WidgetStatePropertyAll(context.cores.texto),
          side: WidgetStatePropertyAll(BorderSide(color: context.cores.borda)),
          backgroundColor: WidgetStatePropertyAll(context.cores.cartao),
        ),
        child: contents,
      ),
    );
  }
}

// A palavra "Google" nas cores da marca, usada no botão de entrar com o
// Google
class GoogleWordmark extends StatelessWidget {
  const GoogleWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700),
        children: [
          TextSpan(
            text: 'G',
            style: TextStyle(color: Color(0xFF4285F4)),
          ),
          TextSpan(
            text: 'o',
            style: TextStyle(color: Color(0xFFEA4335)),
          ),
          TextSpan(
            text: 'o',
            style: TextStyle(color: Color(0xFFFBBC05)),
          ),
          TextSpan(
            text: 'g',
            style: TextStyle(color: Color(0xFF4285F4)),
          ),
          TextSpan(
            text: 'l',
            style: TextStyle(color: Color(0xFF34A853)),
          ),
          TextSpan(
            text: 'e',
            style: TextStyle(color: Color(0xFFEA4335)),
          ),
        ],
      ),
    );
  }
}
