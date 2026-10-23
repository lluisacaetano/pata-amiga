// Nomes de todas as rotas do app, para não espalhar strings pelo código.
// A tabela que liga cada nome à sua tela fica em app_router.dart
abstract final class AppRoutes {
  static const welcome = '/';
  static const login = '/login';
  static const register = '/cadastro';
  static const terms = '/termos-de-uso';
  static const privacy = '/politica-de-privacidade';
  static const recoverPassword = '/recuperacao';
  static const feed = '/feed';
  static const home = '/home';
  static const details = '/detalhes-animal';
  static const registerAnimal = '/cadastro-animal';
  static const onboarding = '/onboarding';
  static const perfilUsuario = '/perfil-usuario';
  static const editarPerfil = '/editar-perfil';
  static const configuracoesAparencia = '/configuracoes-aparencia';
  static const configuracoesAcessibilidade = '/configuracoes-acessibilidade';
  static const mapa = '/mapa';
  static const ongs = '/ongs';
  static const perfilOng = '/perfil-ong';
  static const cadastroOng = '/cadastro-ong';
  static const registrarAvistamento = '/registrar-avistamento';
  static const cadastrarPonto = '/cadastrar-ponto';
  static const registrarAbastecimento = '/registrar-abastecimento';
  static const reportar = '/reportar';
  static const minhasDenuncias = '/minhas-denuncias';
  static const detalhesDenuncia = '/detalhes-denuncia';
}
