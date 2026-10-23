// Biblioteca dart:async: o Timer que encerra a recepção.
import 'dart:async';

// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo usuario_provider.dart: nome de quem está logado.
import '../../provider/usuario_provider.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../../tema/cores.dart';
// Arquivo auth_components.dart: fundo e logotipo das telas de entrada.
import 'auth_components.dart';

// Recepção de quem reabre o app com a sessão salva: cumprimenta pelo
// primeiro nome e chama [aoTerminar] depois de 1,8 s ou ao primeiro toque
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
    // Com animações desligadas no aparelho, a tela já aparece pronta
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrada.value = 1;
    } else if (!_entrada.isAnimating && _entrada.value == 0) {
      _entrada.forward();
    }
  }

  // Garante que [aoTerminar] seja chamado uma única vez, pelo tempo ou pelo
  // toque, o que vier primeiro
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

    // A patinha cresce de leve e a saudação aparece em seguida
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
