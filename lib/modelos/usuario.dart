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