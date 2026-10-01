import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tema/cores.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  // A mesma seta de voltar do cadastro do animal, no canto de cima
  final bool comVoltar;

  const AuthBackground({
    super.key,
    required this.child,
    this.comVoltar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBFDCC8), // verde mais aparente
      Color(0xFFDCEBDD), // verde pastel
      Color(0xFFF2F5EE), // quase branco
      Color(0xFFFFF1E5), ],
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
                  color: Cores.principal,
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
      borderSide: const BorderSide(color: Cores.borda),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Cores.texto,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Cores.texto,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Cores.textoFraco),
            prefixIcon: Icon(prefixIcon, size: 20, color: Cores.textoFraco),
            suffixIcon: suffixIcon == null
                ? null
                : IconButton(
                    tooltip: obscureText ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: onSuffixPressed,
                    icon: Icon(suffixIcon, size: 20, color: Cores.textoFraco),
                  ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: outline,
            enabledBorder: outline,
            focusedBorder: outline.copyWith(
              borderSide: const BorderSide(color: Cores.principal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

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
            backgroundColor: const WidgetStatePropertyAll(Cores.principal),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
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
          foregroundColor: const WidgetStatePropertyAll(Cores.texto),
          side: const WidgetStatePropertyAll(BorderSide(color: Cores.borda)),
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
        child: contents,
      ),
    );
  }
}

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
