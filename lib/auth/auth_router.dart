import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth_components.dart';
import 'screens/boas_vindas_screen.dart';
import 'screens/de_volta_screen.dart';
import '../telas/feed_adocao.dart';
import '../telas/onboarding_screen.dart';

// Nome da classe traduzido: AuthRouter -> RoteadorAutenticacao
class RoteadorAutenticacao extends StatefulWidget {
  const RoteadorAutenticacao({super.key});

  @override
  State<RoteadorAutenticacao> createState() => _EstadoRoteadorAutenticacao();
}

typedef AuthRouter = RoteadorAutenticacao;

class _EstadoRoteadorAutenticacao extends State<RoteadorAutenticacao> {
  // Variáveis em português
  bool _estaLogado = false;
  bool _estaCarregando = true;
  bool _mostrarOnboarding = false;
  // Quem reabre o app já logado passa poucos segundos pela recepção
  bool _mostrarDeVolta = true;

  @override
  void initState() {
    super.initState();
    _verificarStatusLogin();
  }

  // Método responsável por verificar se o e-mail está salvo
  Future<void> _verificarStatusLogin() async {
    final preferencias = await SharedPreferences.getInstance();
    final emailLogado = preferencias.getString('loggedInEmail');
    final onboardingConcluido = emailLogado == null
        ? true
        : await OnboardingStorage.jaViu();
    if (!mounted) return;

    setState(() {
      _estaLogado = emailLogado != null;
      _mostrarOnboarding = emailLogado != null && !onboardingConcluido;
      _estaCarregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_estaCarregando) {
      return const Scaffold(body: Center(child: AuthBrandMark(size: 76)));
    }

    if (_estaLogado) {
      if (_mostrarOnboarding) {
        return OnboardingScreen(
          onFinish: () {
            if (mounted) setState(() => _mostrarOnboarding = false);
          },
        );
      }
      // Com a sessão salva, uma recepção rápida e depois o feed, como logo
      // depois do login. A saída da conta fica no perfil
      return AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 400),
        child: _mostrarDeVolta
            ? DeVoltaScreen(
                aoTerminar: () {
                  if (mounted) setState(() => _mostrarDeVolta = false);
                },
              )
            : const FeedAdocao(),
      );
    }

    return const BoasVindasScreen();
  }
}
