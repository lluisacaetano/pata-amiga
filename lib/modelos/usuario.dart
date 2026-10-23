// Biblioteca dart:convert: converte texto JSON em objetos e vice-versa.
import 'dart:convert';

// A conta de uma pessoa: dados do perfil guardados no aparelho. A senha não
// é persistida pelo perfil
class Usuario {
  final String nome;
  final String email;
  final String senha;
  final String telefone;
  // Caminho da foto de perfil no aparelho; nulo quando não há foto
  final String? foto;

  Usuario({
    required this.nome,
    required this.email,
    required this.senha,
    this.telefone = '',
    this.foto,
  });

  // Os dados do perfil, sem a senha
  Map<String, Object?> toMap() => {
    'nome': nome,
    'email': email,
    'telefone': telefone,
    'foto': foto,
  };

  // Cria o usuário a partir dos dados do perfil; a senha fica vazia
  factory Usuario.fromMap(Map<String, Object?> map) => Usuario(
    nome: map['nome'] as String? ?? '',
    email: map['email'] as String? ?? '',
    senha: '',
    telefone: map['telefone'] as String? ?? '',
    foto: map['foto'] as String?,
  );

  // O perfil em JSON, como é gravado no aparelho
  String toProfileJson() => jsonEncode(toMap());

  // Lê o perfil gravado; lança FormatException se o conteúdo for inválido
  static Usuario fromProfileJson(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Dados do perfil inválidos.');
    }
    return Usuario.fromMap(decoded);
  }

  // Formato antigo, com os campos separados por "|" e a senha em texto.
  // Não é usado pelo app
  String toJson() => '$email|$senha|$nome|$telefone|${foto ?? ''}';

  // Lê o formato antigo separado por "|". Não é usado pelo app
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
