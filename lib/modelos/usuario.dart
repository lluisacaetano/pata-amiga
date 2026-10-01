class Usuario {
   String nome;
  String telefone;
  String? foto;
  final String telefone;
  final String? foto;

  Usuario({
    required this.nome,
    required this.telefone,
    this.foto,
    this.telefone = '',
    this.foto,
  });
}