import 'package:flutter/material.dart';

import '../modelos/usuario.dart';

class UsuarioProvider extends ChangeNotifier {
  Usuario _usuario = Usuario(
    nome: 'Usuário',
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
      telefone: telefone,
      foto: foto,
    );

    notifyListeners();
  }
}