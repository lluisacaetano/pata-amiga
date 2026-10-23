// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo auth_components.dart: logotipo da tela de carregamento.
import 'screens/auth_components.dart';
// Arquivo boas_vindas_screen.dart: tela de quem não tem sessão.
import 'screens/boas_vindas_screen.dart';
// Arquivo de_volta_screen.dart: recepção rápida de quem reabre o app logado.
import 'screens/de_volta_screen.dart';
// Arquivo feed_adocao.dart: feed de animais, a tela principal do app.
import '../telas/feed_adocao.dart';
// Arquivo onboarding_screen.dart: onboarding e se ele já foi visto.
import '../telas/onboarding_screen.dart';
// Arquivo usuario_provider.dart: se há uma sessão aberta.
import '../provider/usuario_provider.dart';

// Primeira tela do app: decide para onde a pessoa vai ao abrir.
// Sem sessão salva, mostra as boas-vindas; com sessão, mostra o onboarding
// (se ainda não foi visto) ou a recepção rápida seguida do feed
class RoteadorAutenticacao extends StatefulWidget {
  const RoteadorAutenticacao({super.key});

  @override
  State<RoteadorAutenticacao> createState() => _EstadoRoteadorAutenticacao();
}

// Nome alternativo mantido para as rotas que já usam AuthRouter
typedef AuthRouter = RoteadorAutenticacao;

class _EstadoRoteadorAutenticacao extends State<RoteadorAutenticacao> {
  bool _estaLogado = false;
  bool _estaCarregando = true;
  bool _mostrarOnboarding = false;
  // Quem reabre o app com a sessão salva passa pela recepção antes do feed
  bool _mostrarDeVolta = true;

  @override
  void initState() {
    super.initState();
    _verificarStatusLogin();
  }

  // Pergunta ao UsuarioProvider se há sessão (ele a restaura ao abrir o
  // app). O onboarding só é consultado para quem está logado, porque quem
  // não está passa antes pelo login
  Future<void> _verificarStatusLogin() async {
    final logado = context.read<UsuarioProvider?>()?.estaLogado ?? false;
    final onboardingConcluido = logado ? await OnboardingStorage.jaViu() : true;
    if (!mounted) return;

    setState(() {
      _estaLogado = logado;
      _mostrarOnboarding = logado && !onboardingConcluido;
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
      // Com a sessão salva: a recepção rápida e, ao fim dela, o feed. Sem
      // animação quando o aparelho pede movimento reduzido
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
