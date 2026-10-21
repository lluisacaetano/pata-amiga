import 'dart:convert';

class Usuario {
  final String nome;
  final String email;
  final String senha;
  final String telefone;
  final String? foto;

  Usuario({
    required this.nome,
    required this.email,
    required this.senha,
    this.telefone = '',
    this.foto,
  });

  Map<String, Object?> toMap() => {
    'nome': nome,
    'email': email,
    'telefone': telefone,
    'foto': foto,
  };

  factory Usuario.fromMap(Map<String, Object?> map) => Usuario(
    nome: map['nome'] as String? ?? '',
    email: map['email'] as String? ?? '',
    senha: '',
    telefone: map['telefone'] as String? ?? '',
    foto: map['foto'] as String?,
  );

  String toProfileJson() => jsonEncode(toMap());

  static Usuario fromProfileJson(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Dados do perfil inválidos.');
    }
    return Usuario.fromMap(decoded);
  }

  String toJson() => '$email|$senha|$nome|$telefone|${foto ?? ''}';

  static Usuario formJson(String json) {
    final parts = json.split('|');

    return Usuario(
      nome: parts[2],
      email: parts[0],
      senha: parts[1],
      telefone: parts.length > 3 ? parts[3] : '',
      foto: parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null,
    );
  }
}
