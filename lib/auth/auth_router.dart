import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth_components.dart';
import 'screens/boas_vindas_screen.dart';
import '../telas/home_screen.dart'; // Sua tela principal
import '../telas/onboarding_screen.dart';

// Nome da classe traduzido: AuthRouter -> RoteadorAutenticacao
class RoteadorAutenticacao extends StatefulWidget {
  const RoteadorAutenticacao({Key? key}) : super(key: key);

  @override
  State<RoteadorAutenticacao> createState() => _EstadoRoteadorAutenticacao();
}

typedef AuthRouter = RoteadorAutenticacao;

class _EstadoRoteadorAutenticacao extends State<RoteadorAutenticacao> {
  // Variáveis em português
  bool _estaLogado = false;
  bool _estaCarregando = true;
  bool _mostrarOnboarding = false;

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

  // Método responsável por fazer o encerramento da sessão (logout)
  void _encerrarSessao() {
    SharedPreferences.getInstance().then((preferencias) {
      preferencias.remove('loggedInEmail');
      setState(() {
        _estaLogado = false;
      });
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
      // passa a função de encerrar sessão para a tela principal
      return HomeScreen(onLogout: _encerrarSessao);
    }

    return const BoasVindasScreen();
  }
}
