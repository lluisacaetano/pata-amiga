class Usuario {

  final String nome;
  final String email;
  final String senha;

  Usuario({
    required this.nome,
    required this.email,
    required this.senha,
  });

  String toJson() => '$email|$senha|$nome';

  static Usuario formJson(String json) {
    final parts = json.split('|');
    return Usuario(nome: parts[0], email: parts[1], senha: parts[2],
    );
  }
}
