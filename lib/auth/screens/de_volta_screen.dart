import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/usuario_provider.dart';
import '../../tema/cores.dart';
import 'auth_components.dart';

// Recepção rápida de quem reabre o app com a sessão salva. Fica poucos
// segundos e segue sozinha para o feed; um toque pula a espera
class DeVoltaScreen extends StatefulWidget {
  final VoidCallback aoTerminar;

  const DeVoltaScreen({super.key, required this.aoTerminar});

  @override
  State<DeVoltaScreen> createState() => _DeVoltaScreenState();
}

class _DeVoltaScreenState extends State<DeVoltaScreen>
    with SingleTickerProviderStateMixin {
  static const _tempoNaTela = Duration(milliseconds: 1800);

  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  Timer? _espera;
  bool _terminou = false;

  @override
  void initState() {
    super.initState();
    _espera = Timer(_tempoNaTela, _terminar);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Quem desligou as animações no aparelho vê a tela já pronta
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrada.value = 1;
    } else if (!_entrada.isAnimating && _entrada.value == 0) {
      _entrada.forward();
    }
  }

  void _terminar() {
    if (_terminou) return;
    _terminou = true;
    _espera?.cancel();
    widget.aoTerminar();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nome = context.read<UsuarioProvider>().usuario.nome.trim();
    final primeiroNome = nome.isEmpty ? '' : nome.split(RegExp(r'\s+')).first;
    final saudacao = primeiroNome.isEmpty
        ? 'Que bom te ver de volta!'
        : 'Que bom te ver de volta, $primeiroNome!';

    // A patinha cresce de leve e a frase aparece logo depois dela
    final escala = Tween(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _entrada, curve: Curves.easeOutBack),
    );
    final frase = CurvedAnimation(
      parent: _entrada,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _terminar,
        child: AuthBackground(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: escala,
                child: const AuthBrandMark(size: 96),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: frase,
                child: Text(
                  saudacao,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    color: context.cores.principal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
