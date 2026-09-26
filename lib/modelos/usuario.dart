class Usuario {
  String nome;
  String telefone;
  String? foto;

  Usuario({
    required this.nome,
    required this.telefone,
    this.foto,
  });
}