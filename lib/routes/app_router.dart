// Padronização de rotas da aplicação
import 'package:flutter/material.dart';

import '../modelos/animal.dart';
import '../modelos/ponto_de_alimentacao.dart';
import '../auth/auth_router.dart';
import '../auth/screens/cadastro_screen.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/recuperar_senha.dart';
import '../telas/home_screen.dart';
import '../telas/feed_adocao.dart';
import '../telas/detalhes_animal.dart';
import '../telas/cadastrar_ponto.dart';
import '../telas/cadastro_animal.dart';
import '../widgets/acoes_do_registro.dart';
import '../telas/onboarding_screen.dart';
import '../telas/editar_perfil.dart';
import '../telas/perfil_usuario.dart';
import '../telas/configuracoes_aparencia.dart';
import '../telas/configuracoes_acessibilidade.dart';
import '../telas/registrar_abastecimento.dart';
import '../telas/registrar_avistamento.dart';
import '../telas/tela_mapa.dart'; // NOVO
import '../telas/reportar.dart';
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

    AppRoutes.registerAnimal: (context) {
      // Sem argumento, um cadastro novo; com um animal, a publicação do
      // resgate para adoção; com uma edição, o registro inteiro
      final argumento = ModalRoute.of(context)?.settings.arguments;
      return CadastroAnimal(
        base: argumento is Animal ? argumento : null,
        editando: argumento is EdicaoDoRegistro ? argumento.animal : null,
      );
    },
    AppRoutes.perfilUsuario: (_) => const PerfilUsuario(),
    AppRoutes.editarPerfil: (_) => const EditarPerfil(),
    AppRoutes.configuracoesAparencia: (_) => const ConfiguracoesAparencia(),
    AppRoutes.configuracoesAcessibilidade: (_) =>
        const ConfiguracoesAcessibilidade(),

    AppRoutes.mapa: (context) {
      // Vindo da ficha, o mapa recebe o animal para abrir com zoom nele
      final animal = ModalRoute.of(context)?.settings.arguments;
      return PaginaMapa(focar: animal is Animal ? animal : null);
    },

    AppRoutes.cadastrarPonto: (_) => const CadastrarPonto(),

    AppRoutes.registrarAbastecimento: (context) {
      final ponto = ModalRoute.of(context)?.settings.arguments;
      if (ponto is! PontoDeAlimentacao) {
        throw ArgumentError('O abastecimento precisa saber de qual ponto é.');
      }
      return RegistrarAbastecimento(ponto: ponto);
    },

    AppRoutes.registrarAvistamento: (context) {
      final animal = ModalRoute.of(context)?.settings.arguments;
      if (animal is! Animal) {
        throw ArgumentError('O avistamento precisa saber de qual animal é.');
      }
      return RegistrarAvistamento(animal: animal);
    },

    AppRoutes.reportar: (_) => const ReportarScreen(),
  };
}