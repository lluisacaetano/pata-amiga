// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo animal.dart: modelo do animal, argumento de várias rotas.
import '../modelos/animal.dart';
// Arquivo denuncia.dart: modelo da denúncia, argumento dos detalhes.
import '../modelos/denuncia.dart';
// Arquivo ong.dart: modelo da ONG, argumento do perfil e do cadastro.
import '../modelos/ong.dart';
// Arquivo ponto_de_alimentacao.dart: modelo do ponto de alimentação.
import '../modelos/ponto_de_alimentacao.dart';
// Arquivo auth_router.dart: escolhe entre boas-vindas e volta à conta.
import '../auth/auth_router.dart';
// Arquivo cadastro_screen.dart: tela de cadastro de conta.
import '../auth/screens/cadastro_screen.dart';
// Arquivo documento_legal_screen.dart: termos de uso e privacidade.
import '../auth/screens/documento_legal_screen.dart';
// Arquivo login_screen.dart: tela de login.
import '../auth/screens/login_screen.dart';
// Arquivo recuperar_senha.dart: tela de recuperação de senha.
import '../auth/screens/recuperar_senha.dart';
// Arquivo home_screen.dart: tela inicial simples da rota home.
import '../telas/home_screen.dart';
// Arquivo feed_adocao.dart: feed de animais.
import '../telas/feed_adocao.dart';
// Arquivo detalhes_animal.dart: ficha do animal.
import '../telas/detalhes_animal.dart';
// Arquivo cadastrar_ponto.dart: cadastro de ponto de alimentação.
import '../telas/cadastrar_ponto.dart';
// Arquivo cadastro_animal.dart: cadastro e edição de animal.
import '../telas/cadastro_animal.dart';
// Arquivo cadastro_ong.dart: cadastro e edição de ONG.
import '../telas/cadastro_ong.dart';
// Arquivo lista_ongs.dart: lista de ONGs.
import '../telas/lista_ongs.dart';
// Arquivo perfil_ong.dart: perfil público da ONG.
import '../telas/perfil_ong.dart';
// Arquivo acoes_do_registro.dart: EdicaoDoRegistro, argumento da edição.
import '../widgets/acoes_do_registro.dart';
// Arquivo onboarding_screen.dart: apresentação inicial do app.
import '../telas/onboarding_screen.dart';
// Arquivo editar_perfil.dart: edição do perfil.
import '../telas/editar_perfil.dart';
// Arquivo perfil_usuario.dart: perfil da pessoa logada.
import '../telas/perfil_usuario.dart';
// Arquivo configuracoes_aparencia.dart: configurações de aparência.
import '../telas/configuracoes_aparencia.dart';
// Arquivo configuracoes_acessibilidade.dart: configurações de acessibilidade.
import '../telas/configuracoes_acessibilidade.dart';
// Arquivo registrar_abastecimento.dart: registro de abastecimento de um ponto.
import '../telas/registrar_abastecimento.dart';
// Arquivo registrar_avistamento.dart: registro de avistamento.
import '../telas/registrar_avistamento.dart';
// Arquivo tela_mapa.dart: mapa com as camadas.
import '../telas/tela_mapa.dart';
// Arquivo reportar.dart: tela de denúncia.
import '../telas/reportar.dart';
// Arquivo minhas_denuncias.dart: lista das denúncias feitas neste aparelho.
import '../telas/minhas_denuncias.dart';
// Arquivo detalhes_denuncia.dart: detalhes de uma denúncia.
import '../telas/detalhes_denuncia.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import 'route_names.dart';

// Arquivo route_names.dart: reexporta os nomes das rotas.
export 'route_names.dart';

// Tabela de rotas nomeadas do app. Rotas que dependem de um objeto (animal,
// ONG, ponto, denúncia) leem o argumento da rota e falham com ArgumentError
// se ele faltar ou for de outro tipo
class AppRoutesConfig {
  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.welcome: (_) => const AuthRouter(),

    AppRoutes.login: (_) => const LoginScreen(),

    AppRoutes.register: (_) => const RegisterScreen(),

    AppRoutes.terms: (_) =>
        const DocumentoLegalScreen(tipo: TipoDocumentoLegal.termos),

    AppRoutes.privacy: (_) =>
        const DocumentoLegalScreen(tipo: TipoDocumentoLegal.privacidade),

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
        throw ArgumentError('A rota de detalhes precisa receber um Animal.');
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

    AppRoutes.ongs: (_) => const ListaOngs(),

    AppRoutes.perfilOng: (context) {
      final ong = ModalRoute.of(context)?.settings.arguments;
      if (ong is! Ong) {
        throw ArgumentError('O perfil precisa saber de qual ONG é.');
      }
      return PerfilOng(ong: ong);
    },

    // Sem argumento, cria a ONG; com uma, edita
    AppRoutes.cadastroOng: (context) {
      final ong = ModalRoute.of(context)?.settings.arguments;
      return CadastroOng(editando: ong is Ong ? ong : null);
    },

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

    AppRoutes.minhasDenuncias: (_) => const MinhasDenuncias(),

    AppRoutes.detalhesDenuncia: (context) {
      final denuncia = ModalRoute.of(context)?.settings.arguments;
      if (denuncia is! Denuncia) {
        throw ArgumentError('Os detalhes precisam saber de qual denúncia são.');
      }
      return DetalhesDenuncia(denuncia: denuncia);
    },
  };
}
