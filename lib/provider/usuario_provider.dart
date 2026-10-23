// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';

// Arquivo usuario.dart: modelo do usuário e a conversão do perfil salvo.
import '../modelos/usuario.dart';

// Perfil de quem está logado. O perfil fica salvo no aparelho, um por
// e-mail, e a sessão é o e-mail gravado em [_chaveSessao]
class UsuarioProvider extends ChangeNotifier {
  static const _chaveUsuario = 'usuario_perfil:';
  static const _chaveSessao = 'loggedInEmail';

  Usuario _usuario = Usuario(nome: '', email: '', senha: '', telefone: '');

  Usuario get usuario => _usuario;

  // Ao abrir o app, carrega o perfil da sessão salva, se houver
  Future<void> restaurarSessao() async {
    final armazenamento = await SharedPreferences.getInstance();
    final email = armazenamento.getString(_chaveSessao);
    if (email == null) return;
    await carregarUsuario(email);
  }

  // Cria o perfil de uma conta nova e já abre a sessão com ele
  Future<void> registrarUsuario({
    required String nome,
    required String email,
    required String telefone,
  }) async {
    _usuario = Usuario(
      nome: nome.trim(),
      email: email.trim(),
      senha: '',
      telefone: telefone.trim(),
    );
    notifyListeners();
    await _salvarPerfil();
  }

  Future<void> iniciarSessao(String email) async {
    await carregarUsuario(email.trim());
  }

  // Carrega o perfil salvo para o e-mail (ou um perfil vazio, se não houver)
  // e grava esse e-mail como a sessão atual
  Future<void> carregarUsuario(String email) async {
    final armazenamento = await SharedPreferences.getInstance();
    final salvo = armazenamento.getString('$_chaveUsuario$email');
    _usuario = salvo == null
        ? Usuario(nome: '', email: email, senha: '')
        : Usuario.fromProfileJson(salvo);
    await armazenamento.setString(_chaveSessao, email);
    notifyListeners();
  }

  // Troca nome, telefone e foto do perfil atual e salva no aparelho
  Future<void> atualizarUsuario({
    required String nome,
    required String telefone,
    String? foto,
  }) {
    _usuario = Usuario(
      nome: nome,
      email: _usuario.email,
      senha: _usuario.senha,
      telefone: telefone,
      foto: foto,
    );

    notifyListeners();
    return _salvarPerfil();
  }

  // Encerra a sessão; o perfil continua salvo no aparelho para o próximo
  // login com o mesmo e-mail
  Future<void> encerrarSessao() async {
    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.remove(_chaveSessao);
    _usuario = Usuario(nome: '', email: '', senha: '');
    notifyListeners();
  }

  // Grava o perfil na chave do e-mail e mantém a sessão nesse e-mail
  Future<void> _salvarPerfil() async {
    if (_usuario.email.isEmpty) return;
    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setString(
      '$_chaveUsuario${_usuario.email}',
      _usuario.toProfileJson(),
    );
    await armazenamento.setString(_chaveSessao, _usuario.email);
  }
}
