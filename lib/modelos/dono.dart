// Quem responde por um animal: o tutor, o protetor independente ou a ONG
class Dono {
  final String nome;
  final String telefone;

  const Dono({required this.nome, required this.telefone});
}

extension ContatoNoWhatsApp on Dono {
  // O wa.me só aceita dígitos com o código do país; com DDD são 10 ou 11
  String get numeroNoWhatsApp {
    final digitos = telefone.replaceAll(RegExp(r'\D'), '');
    return digitos.length <= 11 ? '55$digitos' : digitos;
  }
}
