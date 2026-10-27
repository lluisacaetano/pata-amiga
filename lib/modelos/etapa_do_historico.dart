// Uma mudança de situação registrada no histórico de uma denúncia ou de um
// animal: a situação nova, a observação obrigatória de quem mudou, quando foi
// e o nome de quem fez a mudança
class EtapaDoHistorico {
  // O nome da situação no enum de quem usa o histórico (ex.: "emApuracao",
  // "adotado"); cada tela converte no rótulo exibido
  final String situacao;
  final String observacao;
  final DateTime em;
  final String autor;

  const EtapaDoHistorico({
    required this.situacao,
    required this.observacao,
    required this.em,
    this.autor = '',
  });

  // Cria a etapa a partir do JSON; campos ausentes recebem um padrão
  factory EtapaDoHistorico.fromJson(Map<String, dynamic> json) =>
      EtapaDoHistorico(
        situacao: json['situacao'] as String? ?? '',
        observacao: json['observacao'] as String? ?? '',
        em:
            DateTime.tryParse(json['em'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        autor: json['autor'] as String? ?? '',
      );

  // Converte a etapa no JSON gravado na API. Precisa espelhar o fromJson
  Map<String, dynamic> toJson() => {
    'situacao': situacao,
    'observacao': observacao,
    'em': em.toIso8601String(),
    'autor': autor,
  };

  // Lê uma lista de etapas do JSON, ignorando itens com defeito
  static List<EtapaDoHistorico> lista(Object? valor) => [
    if (valor is List)
      for (final item in valor)
        if (item is Map<String, dynamic>) EtapaDoHistorico.fromJson(item),
  ];
}
