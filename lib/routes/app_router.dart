// Padronização de rotas da aplicação
import 'package:flutter/material.dart';

import '../modelos/animal.dart';
import '../auth/auth_router.dart';
import '../auth/screens/cadastro_screen.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/recuperar_senha.dart';
import '../telas/home_screen.dart';
import '../telas/feed_adocao.dart';
import '../telas/detalhes_animal.dart';
import '../telas/cadastro_animal.dart';
import '../telas/onboarding_screen.dart';
import '../telas/perfil_usuario.dart';
import 'route_names.dart';

export 'route_names.dart';

class AppRoutesConfig {
  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.welcome: (_) => const AuthRouter(),

    AppRoutes.login: (_) => const LoginScreen(),

    AppRoutes.register: (_) => const RegisterScreen(),

    AppRoutes.recoverPassword: (_) => const RecoverPasswordScreen(),

    AppRoutes.home: (_) => const SuaTelaHome(),

    AppRoutes.feed: (_) => const FeedAdocao(),

    AppRoutes.onboarding: (context) => OnboardingScreen(
      onFinish: () =>
          Navigator.of(context).pushReplacementNamed(AppRoutes.feed),
    ),

    AppRoutes.details: (context) {
      final animal = ModalRoute.of(context)?.settings.arguments;

      if (animal is! Animal) {
        throw ArgumentError(
          'A rota de detalhes precisa receber um Animal.',
        );
      }

      return DetalhesAnimal(animal: animal);
    },

    AppRoutes.registerAnimal: (_) => const CadastroAnimal(),

    // Perfil do usuário
    AppRoutes.profile: (_) => const PerfilUsuario(),
  };
}