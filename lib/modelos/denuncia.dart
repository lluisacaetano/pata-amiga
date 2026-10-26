// Biblioteca dart:math: Random, para sortear o número do protocolo.
import 'dart:math';

// Arquivo etapa_do_historico.dart: as mudanças de situação da denúncia.
import 'etapa_do_historico.dart';
// Arquivo json_da_api.dart: leitura e gravação do id da API.
import 'json_da_api.dart';

// O tipo de ocorrência relatada na denúncia
enum TipoDeDenuncia { mausTratos, abandono, negligencia, outros }

extension RotuloDoTipoDeDenuncia on TipoDeDenuncia {
  String get rotulo => switch (this) {
    TipoDeDenuncia.mausTratos => 'Maus-tratos',
    TipoDeDenuncia.abandono => 'Abandono',
    TipoDeDenuncia.negligencia => 'Negligência',
    TipoDeDenuncia.outros => 'Outros',
  };
}

// As etapas da denúncia depois de registrada
enum SituacaoDaDenuncia { recebida, emApuracao, encerrada }

extension RotuloDaSituacao on SituacaoDaDenuncia {
  String get rotulo => switch (this) {
    SituacaoDaDenuncia.recebida => 'Recebida',
    SituacaoDaDenuncia.emApuracao => 'Em apuração',
    SituacaoDaDenuncia.encerrada => 'Encerrada',
  };
}

// Uma denúncia de maus-tratos, abandono ou negligência, enviada a uma
// organização que recebe denúncias ([ongId]). Na anônima, o nome e o contato
// de quem denunciou não são enviados à API
class Denuncia {
  // O id gerado pela API, sempre em texto
  final String? id;
  final String protocolo;
  final TipoDeDenuncia tipo;
  final String descricao;
  final String rua;
  final String bairro;
  final double? latitude;
  final double? longitude;
  // Data da ocorrência; nula quando a pessoa não informa
  final DateTime? ocorridaEm;
  final List<String> fotos;
  final bool anonima;
  final String denuncianteNome;
  final String denuncianteTelefone;
  final String denuncianteEmail;
  final SituacaoDaDenuncia situacao;
  final DateTime registradaEm;
  // A organização que recebe a denúncia; nula nas registradas antes do envio
  // pelo app
  final String? ongId;
  // As mudanças de situação, da primeira para a mais recente
  final List<EtapaDoHistorico> historico;

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
    this.ongId,
    this.historico = const [],
  });

  // Uma cópia com a nova situação e a etapa correspondente no histórico; o
  // objeto original não muda
  Denuncia comSituacao(
    SituacaoDaDenuncia nova, {
    required String observacao,
    required String autor,
    DateTime? em,
  }) => Denuncia.fromJson({
    ...toJson(),
    'situacao': nova.name,
    'historico': [
      for (final etapa in historico) etapa.toJson(),
      EtapaDoHistorico(
        situacao: nova.name,
        observacao: observacao.trim(),
        em: em ?? DateTime.now(),
        autor: autor.trim(),
      ).toJson(),
    ],
  });

  // Gera o protocolo no aparelho: a data do registro e quatro dígitos
  // sorteados, no formato PA-AAAAMMDD-NNNN
  static String novoProtocolo(DateTime agora, [Random? sorte]) {
    String dois(int n) => n.toString().padLeft(2, '0');
    final numero = (sorte ?? Random())
        .nextInt(10000)
        .toString()
        .padLeft(4, '0');
    return 'PA-${agora.year}${dois(agora.month)}${dois(agora.day)}-$numero';
  }

  // Cria a denúncia a partir do JSON da API. Campos ausentes ou valores
  // desconhecidos recebem um padrão, sem gerar erro
  factory Denuncia.fromJson(Map<String, dynamic> json) => Denuncia(
    id: idDaApi(json['id']),
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
    ongId: idDaApi(json['ongId']),
    historico: EtapaDoHistorico.lista(json['historico']),
  );

  // Converte a denúncia no JSON enviado à API
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': idParaApi(id!),
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
    // Na anônima, os dados de quem denunciou vão vazios
    'denuncianteNome': anonima ? '' : denuncianteNome,
    'denuncianteTelefone': anonima ? '' : denuncianteTelefone,
    'denuncianteEmail': anonima ? '' : denuncianteEmail,
    'situacao': situacao.name,
    'registradaEm': registradaEm.toIso8601String(),
    if (ongId != null) 'ongId': idParaApi(ongId!),
    'historico': [for (final etapa in historico) etapa.toJson()],
  };

  // O texto enviado ao canal de denúncia pelo compartilhamento do aparelho,
  // junto com as fotos
  String get mensagemParaOCanal {
    String dois(int n) => n.toString().padLeft(2, '0');
    final quando = ocorridaEm == null
        ? null
        : '${dois(ocorridaEm!.day)}/${dois(ocorridaEm!.month)}/'
              '${ocorridaEm!.year}';
    // Rua e bairro vazios ficam de fora, sem deixar vírgula sobrando
    final local = [
      rua,
      bairro,
      'Formiga',
    ].where((parte) => parte.trim().isNotEmpty).join(', ');
    return [
      'Denúncia registrada no Pata Amiga',
      'Protocolo: $protocolo',
      'Tipo: ${tipo.rotulo}',
      'Local: $local',
      if (quando != null) 'Quando: $quando',
      'O que aconteceu: $descricao',
      if (fotos.isNotEmpty) 'Fotos: ${fotos.length}, em anexo',
      anonima
          ? 'Denúncia anônima. Solicita-se sigilo sobre o número que enviou '
                'esta mensagem.'
          : 'Denunciante: $denuncianteNome, $denuncianteTelefone',
    ].join('\n');
  }
}

// O momento da denúncia em texto: "hoje às 14:19", "ontem às 09:05" ou, nos
// dias anteriores, a data completa com a hora
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
