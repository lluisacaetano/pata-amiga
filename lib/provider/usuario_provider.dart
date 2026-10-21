import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/usuario.dart';

class UsuarioProvider extends ChangeNotifier {
  static const _chaveUsuario = 'usuario_perfil:';
  static const _chaveSessao = 'loggedInEmail';

  Usuario _usuario = Usuario(nome: '', email: '', senha: '', telefone: '');

  Usuario get usuario => _usuario;

  Future<void> restaurarSessao() async {
    final armazenamento = await SharedPreferences.getInstance();
    final email = armazenamento.getString(_chaveSessao);
    if (email == null) return;
    await carregarUsuario(email);
  }

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

  Future<void> carregarUsuario(String email) async {
    final armazenamento = await SharedPreferences.getInstance();
    final salvo = armazenamento.getString('$_chaveUsuario$email');
    _usuario = salvo == null
        ? Usuario(nome: '', email: email, senha: '')
        : Usuario.fromProfileJson(salvo);
    await armazenamento.setString(_chaveSessao, email);
    notifyListeners();
  }

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

  // O perfil continua salvo no aparelho; só a sessão é encerrada
  Future<void> encerrarSessao() async {
    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.remove(_chaveSessao);
    _usuario = Usuario(nome: '', email: '', senha: '');
    notifyListeners();
  }

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
