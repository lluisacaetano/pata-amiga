import 'dart:math';

// O que a denúncia relata
enum TipoDeDenuncia { mausTratos, abandono, negligencia, outros }

extension RotuloDoTipoDeDenuncia on TipoDeDenuncia {
  String get rotulo => switch (this) {
    TipoDeDenuncia.mausTratos => 'Maus-tratos',
    TipoDeDenuncia.abandono => 'Abandono',
    TipoDeDenuncia.negligencia => 'Negligência',
    TipoDeDenuncia.outros => 'Outros',
  };
}

// Por onde a denúncia passa depois de registrada
enum SituacaoDaDenuncia { recebida, emApuracao, encerrada }

extension RotuloDaSituacao on SituacaoDaDenuncia {
  String get rotulo => switch (this) {
    SituacaoDaDenuncia.recebida => 'Recebida',
    SituacaoDaDenuncia.emApuracao => 'Em apuração',
    SituacaoDaDenuncia.encerrada => 'Encerrada',
  };
}

// Uma denúncia de maus-tratos. Na anônima, nome e contato de quem denunciou
// ficam vazios e não vão para a API
class Denuncia {
  final int? id;
  final String protocolo;
  final TipoDeDenuncia tipo;
  final String descricao;
  final String rua;
  final String bairro;
  final double? latitude;
  final double? longitude;
  // Quando aconteceu, se a pessoa souber
  final DateTime? ocorridaEm;
  final List<String> fotos;
  final bool anonima;
  final String denuncianteNome;
  final String denuncianteTelefone;
  final String denuncianteEmail;
  final SituacaoDaDenuncia situacao;
  final DateTime registradaEm;

  const Denuncia({
    this.id,
    required this.protocolo,
    required this.tipo,
    required this.descricao,
    required this.rua,
    required this.bairro,
    this.latitude,
    this.longitude,
    this.ocorridaEm,
    this.fotos = const [],
    this.anonima = false,
    this.denuncianteNome = '',
    this.denuncianteTelefone = '',
    this.denuncianteEmail = '',
    this.situacao = SituacaoDaDenuncia.recebida,
    required this.registradaEm,
  });

  // O protocolo sai do aparelho, com a data e quatro dígitos: PA-20261022-4821
  static String novoProtocolo(DateTime agora, [Random? sorte]) {
    String dois(int n) => n.toString().padLeft(2, '0');
    final numero = (sorte ?? Random())
        .nextInt(10000)
        .toString()
        .padLeft(4, '0');
    return 'PA-${agora.year}${dois(agora.month)}${dois(agora.day)}-$numero';
  }

  factory Denuncia.fromJson(Map<String, dynamic> json) => Denuncia(
    id: (json['id'] as num?)?.toInt(),
    protocolo: json['protocolo'] as String? ?? '',
    tipo:
        TipoDeDenuncia.values
            .where((tipo) => tipo.name == json['tipo'])
            .firstOrNull ??
        TipoDeDenuncia.outros,
    descricao: json['descricao'] as String? ?? '',
    rua: json['rua'] as String? ?? '',
    bairro: json['bairro'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    ocorridaEm: DateTime.tryParse(json['ocorridaEm'] as String? ?? ''),
    fotos: List<String>.from(json['fotos'] as List? ?? const []),
    anonima: json['anonima'] as bool? ?? false,
    denuncianteNome: json['denuncianteNome'] as String? ?? '',
    denuncianteTelefone: json['denuncianteTelefone'] as String? ?? '',
    denuncianteEmail: json['denuncianteEmail'] as String? ?? '',
    situacao:
        SituacaoDaDenuncia.values
            .where((situacao) => situacao.name == json['situacao'])
            .firstOrNull ??
        SituacaoDaDenuncia.recebida,
    registradaEm:
        DateTime.tryParse(json['registradaEm'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'protocolo': protocolo,
    'tipo': tipo.name,
    'descricao': descricao,
    'rua': rua,
    'bairro': bairro,
    'latitude': latitude,
    'longitude': longitude,
    if (ocorridaEm != null) 'ocorridaEm': ocorridaEm!.toIso8601String(),
    'fotos': fotos,
    'anonima': anonima,
    // Na anônima, quem denunciou não vai para a API
    'denuncianteNome': anonima ? '' : denuncianteNome,
    'denuncianteTelefone': anonima ? '' : denuncianteTelefone,
    'denuncianteEmail': anonima ? '' : denuncianteEmail,
    'situacao': situacao.name,
    'registradaEm': registradaEm.toIso8601String(),
  };

  // O texto que vai para a APAF junto com as fotos, pelo compartilhar do
  // celular
  String get mensagemParaOCanal {
    String dois(int n) => n.toString().padLeft(2, '0');
    final quando = ocorridaEm == null
        ? null
        : '${dois(ocorridaEm!.day)}/${dois(ocorridaEm!.month)}/'
              '${ocorridaEm!.year}';
    return [
      'Denúncia registrada no Pata Amiga',
      'Protocolo: $protocolo',
      'Tipo: ${tipo.rotulo}',
      'Local: $rua, $bairro, Formiga',
      if (quando != null) 'Quando: $quando',
      'O que aconteceu: $descricao',
      if (fotos.isNotEmpty) 'Fotos: ${fotos.length}, em anexo',
      anonima
          ? 'Denúncia anônima'
          : 'Denunciante: $denuncianteNome, $denuncianteTelefone',
    ].join('\n');
  }
}

// Quando a denúncia foi registrada, do jeito que se fala: "hoje às 14:19",
// "ontem às 09:05" e, antes disso, a data
String quandoFoi(DateTime momento, DateTime agora) {
  String dois(int n) => n.toString().padLeft(2, '0');
  final hora = '${dois(momento.hour)}:${dois(momento.minute)}';
  final dia = DateTime(momento.year, momento.month, momento.day);
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dias = hoje.difference(dia).inDays;
  if (dias == 0) return 'hoje às $hora';
  if (dias == 1) return 'ontem às $hora';
  return '${dois(momento.day)}/${dois(momento.month)}/${momento.year} às $hora';
}
