import 'package:flutter/material.dart';

import '../modelos/usuario.dart';

class UsuarioProvider extends ChangeNotifier {
  Usuario _usuario = Usuario(
    nome: 'Usuário',
    email: '',
    senha: '',
    telefone: '',
  );

  Usuario get usuario => _usuario;

  void atualizarUsuario({
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
  }
}