// Quem responde por um animal (tutor, protetor independente ou ONG), com o
// telefone de contato
class Dono {
  final String nome;
  final String telefone;

  const Dono({required this.nome, required this.telefone});

  // Cria o responsável a partir do JSON aninhado no animal:
  // "dono": {"nome": "...", "telefone": "..."}. Campo ausente fica vazio
  factory Dono.fromJson(Map<String, dynamic> json) => Dono(
    nome: json['nome'] as String? ?? '',
    telefone: json['telefone'] as String? ?? '',
  );

  // Converte o responsável no JSON aninhado no animal. Precisa espelhar o
  // fromJson
  Map<String, dynamic> toJson() => {'nome': nome, 'telefone': telefone};
}

extension ContatoNoWhatsApp on Dono {
  // O número no formato do link wa.me: só dígitos e com o código do país 55.
  // Retira o 55 e o 0 de operadora digitados a mais e, no celular escrito
  // com 8 dígitos (começando de 6 a 9), acrescenta o 9 depois do DDD.
  // Vazio quando não há telefone
  String get numeroNoWhatsApp {
    var digitos = telefone.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return '';
    if (digitos.length > 11 && digitos.startsWith('55')) {
      digitos = digitos.substring(2);
    }
    if (digitos.length > 10 && digitos.startsWith('0')) {
      digitos = digitos.substring(1);
    }
    if (digitos.length == 10 && '6789'.contains(digitos[2])) {
      digitos = '${digitos.substring(0, 2)}9${digitos.substring(2)}';
    }
    return '55$digitos';
  }
}
