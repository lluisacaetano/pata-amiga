// Quem responde por um animal: o tutor, o protetor independente ou a ONG
class Dono {
  final String nome;
  final String telefone;

  const Dono({required this.nome, required this.telefone});

  // [SPRINT 3 - NOVO] Cria um Dono a partir de um Map (JSON).
  // Usado pelo Animal.fromJson, porque o dono vem aninhado dentro do animal:
  // "dono": { "nome": "Maria", "telefone": "13999990000" }
  factory Dono.fromJson(Map<String, dynamic> json) => Dono(
        nome: json['nome'] as String,
        telefone: json['telefone'] as String,
      );

  // [SPRINT 3 - NOVO] Converte o Dono em Map para ser salvo no cache.
  // Usado pelo Animal.toJson. Se criarem um campo novo no Dono, incluam aqui
  // e no fromJson acima, senão ele some quando o app ler do cache offline.
  Map<String, dynamic> toJson() => {
        'nome': nome,
        'telefone': telefone,
      };
}

extension ContatoNoWhatsApp on Dono {
  // O wa.me só aceita dígitos com o código do país; com DDD são 10 ou 11
  String get numeroNoWhatsApp {
    final digitos = telefone.replaceAll(RegExp(r'\D'), '');
    return digitos.length <= 11 ? '55$digitos' : digitos;
  }
}