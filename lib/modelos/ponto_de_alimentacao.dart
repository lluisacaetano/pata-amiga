import 'dart:math' as math;

// Comedouros e bebedouros públicos da cidade e o registro de quem os
// abasteceu, para saber qual está precisando de comida ou água

enum TipoDePonto { comedouro, bebedouro, ambos }

extension RotuloDoPonto on TipoDePonto {
  String get rotulo => switch (this) {
    TipoDePonto.comedouro => 'Comedouro',
    TipoDePonto.bebedouro => 'Bebedouro',
    TipoDePonto.ambos => 'Comedouro e bebedouro',
  };

  // Na escolha do cadastro, o terceiro tipo aparece mais curto
  String get rotuloCurto => this == TipoDePonto.ambos ? 'Os dois' : rotulo;
}

class PontoDeAlimentacao {
  final int? id;
  final TipoDePonto tipo;
  // Como achar o ponto no lugar: "perto do banco da praça"
  final String referencia;
  final String rua;
  final String bairro;
  final double latitude;
  final double longitude;
  final String cadastradoPor;
  final DateTime cadastradoEm;

  PontoDeAlimentacao({
    this.id,
    required this.tipo,
    this.referencia = '',
    this.rua = '',
    this.bairro = '',
    required this.latitude,
    required this.longitude,
    this.cadastradoPor = '',
    required this.cadastradoEm,
  });

  factory PontoDeAlimentacao.fromJson(Map<String, dynamic> json) =>
      PontoDeAlimentacao(
        id: (json['id'] as num?)?.toInt(),
        tipo: TipoDePonto.values.byName(json['tipo'] as String),
        referencia: json['referencia'] as String? ?? '',
        rua: json['rua'] as String? ?? '',
        bairro: json['bairro'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        cadastradoPor: json['cadastradoPor'] as String? ?? '',
        cadastradoEm: DateTime.parse(json['cadastradoEm'] as String),
      );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'tipo': tipo.name,
    'referencia': referencia,
    'rua': rua,
    'bairro': bairro,
    'latitude': latitude,
    'longitude': longitude,
    'cadastradoPor': cadastradoPor,
    'cadastradoEm': cadastradoEm.toIso8601String(),
  };

  String get lugar =>
      [rua, bairro].where((parte) => parte.trim().isNotEmpty).join(', ');
}

class Abastecimento {
  final int? id;
  final int ponto;
  final DateTime data;
  final String registradoPor;
  // O e-mail identifica quem registrou: dois usuários podem ter o mesmo nome
  final String email;
  // A foto do ponto abastecido, opcional, que todo mundo vê no resumo
  final String foto;

  Abastecimento({
    this.id,
    required this.ponto,
    required this.data,
    this.registradoPor = '',
    this.email = '',
    this.foto = '',
  });

  factory Abastecimento.fromJson(Map<String, dynamic> json) => Abastecimento(
    id: (json['id'] as num?)?.toInt(),
    ponto: (json['ponto'] as num).toInt(),
    data: DateTime.parse(json['data'] as String),
    registradoPor: json['registradoPor'] as String? ?? '',
    email: json['email'] as String? ?? '',
    foto: json['foto'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'ponto': ponto,
    'data': data.toIso8601String(),
    'registradoPor': registradoPor,
    'email': email,
    'foto': foto,
  };
}

// Distância em metros entre dois pontos, pela fórmula de haversine
double distanciaEmMetros(
  double latitude1,
  double longitude1,
  double latitude2,
  double longitude2,
) {
  const raioDaTerra = 6371000.0;
  double radianos(double graus) => graus * math.pi / 180;
  final dLat = radianos(latitude2 - latitude1);
  final dLon = radianos(longitude2 - longitude1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(radianos(latitude1)) *
          math.cos(radianos(latitude2)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * raioDaTerra * math.asin(math.sqrt(a));
}

// A distância máxima entre a pessoa e o ponto para o abastecimento valer
const distanciaMaximaDoPonto = 150.0;

enum MotivoDaRecusa { longeDoPonto, jaRegistrouHoje }

extension TextoDoMotivo on MotivoDaRecusa {
  String get texto => switch (this) {
    MotivoDaRecusa.longeDoPonto =>
      'Você precisa estar no ponto para registrar o abastecimento.',
    MotivoDaRecusa.jaRegistrouHoje =>
      'Você já registrou o abastecimento deste ponto hoje.',
  };
}

// Se o abastecimento pode valer: com a pessoa a até 150 m do ponto e sem
// outro registro dela no mesmo ponto no mesmo dia. Devolve null quando pode.
// A foto é opcional e não entra na verificação
MotivoDaRecusa? verificarAbastecimento({
  required double latitudeDoPonto,
  required double longitudeDoPonto,
  required int? idDoPonto,
  required double latitudeDaPessoa,
  required double longitudeDaPessoa,
  required String email,
  required Iterable<Abastecimento> abastecimentos,
  required DateTime agora,
}) {
  final distancia = distanciaEmMetros(
    latitudeDoPonto,
    longitudeDoPonto,
    latitudeDaPessoa,
    longitudeDaPessoa,
  );
  if (distancia > distanciaMaximaDoPonto) return MotivoDaRecusa.longeDoPonto;
  if (jaAbasteceuHoje(idDoPonto, email, abastecimentos, agora)) {
    return MotivoDaRecusa.jaRegistrouHoje;
  }
  return null;
}

bool jaAbasteceuHoje(
  int? idDoPonto,
  String email,
  Iterable<Abastecimento> abastecimentos,
  DateTime agora,
) {
  if (idDoPonto == null || email.isEmpty) return false;
  return abastecimentos.any(
    (item) =>
        item.ponto == idDoPonto &&
        item.email == email &&
        item.data.year == agora.year &&
        item.data.month == agora.month &&
        item.data.day == agora.day,
  );
}

// O abastecimento mais recente de um ponto, ou null se nunca foi abastecido
Abastecimento? ultimoAbastecimento(
  PontoDeAlimentacao ponto,
  Iterable<Abastecimento> todos,
) {
  Abastecimento? ultimo;
  for (final abastecimento in todos) {
    if (abastecimento.ponto != ponto.id) continue;
    if (ultimo == null || abastecimento.data.isAfter(ultimo.data)) {
      ultimo = abastecimento;
    }
  }
  return ultimo;
}

enum SituacaoDoPonto { abastecido, abastecerLogo, precisa }

extension RotuloDaSituacao on SituacaoDoPonto {
  String get rotulo => switch (this) {
    SituacaoDoPonto.abastecido => 'Abastecido',
    SituacaoDoPonto.abastecerLogo => 'Abastecer logo',
    SituacaoDoPonto.precisa => 'Precisa de abastecimento',
  };
}

// Até 2 dias, abastecido; de 3 a 6, abastecer logo; 7 ou mais, ou nunca,
// precisa. Os limites foram uma proposta do squad, a confirmar com a PO
SituacaoDoPonto situacaoDoPonto(Abastecimento? ultimo, DateTime agora) {
  if (ultimo == null) return SituacaoDoPonto.precisa;
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(ultimo.data.year, ultimo.data.month, ultimo.data.day);
  final dias = hoje.difference(dia).inDays;
  if (dias <= 2) return SituacaoDoPonto.abastecido;
  if (dias <= 6) return SituacaoDoPonto.abastecerLogo;
  return SituacaoDoPonto.precisa;
}

// "hoje", "ontem" ou "há 3 dias", como no resto do app
String haQuantoTempo(DateTime data, DateTime agora) {
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(data.year, data.month, data.day);
  final dias = hoje.difference(dia).inDays;
  if (dias <= 0) return 'hoje';
  if (dias == 1) return 'ontem';
  return 'há $dias dias';
}
