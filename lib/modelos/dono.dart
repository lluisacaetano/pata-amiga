// Quem responde por um animal (tutor, protetor independente ou ONG), com o
// telefone de contato
class Dono {
  final String nome;
  final String telefone;

  const Dono({required this.nome, required this.telefone});

  // Cria o responsável a partir do JSON aninhado no animal:
  // "dono": {"nome": "...", "telefone": "..."}. Os dois campos são obrigatórios
  factory Dono.fromJson(Map<String, dynamic> json) => Dono(
        nome: json['nome'] as String,
        telefone: json['telefone'] as String,
      );

  // Converte o responsável no JSON aninhado no animal. Precisa espelhar o
  // fromJson
  Map<String, dynamic> toJson() => {
        'nome': nome,
        'telefone': telefone,
      };
}

extension ContatoNoWhatsApp on Dono {
  // O número no formato do link wa.me: só dígitos e com o código do país.
  // Números de até 11 dígitos (DDD e telefone) recebem o 55 do Brasil
  String get numeroNoWhatsApp {
    final digitos = telefone.replaceAll(RegExp(r'\D'), '');
    return digitos.length <= 11 ? '55$digitos' : digitos;
  }
}