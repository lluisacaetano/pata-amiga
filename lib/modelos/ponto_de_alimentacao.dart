// Biblioteca dart:math: seno, cosseno e raiz, usados no cálculo de distância.
import 'dart:math' as math;

// Comedouros e bebedouros públicos da cidade e o registro de quem os
// abasteceu, para indicar quais precisam de comida ou água

// O que o ponto oferece
enum TipoDePonto { comedouro, bebedouro, ambos }

extension RotuloDoPonto on TipoDePonto {
  // O nome do tipo como aparece na tela
  String get rotulo => switch (this) {
    TipoDePonto.comedouro => 'Comedouro',
    TipoDePonto.bebedouro => 'Bebedouro',
    TipoDePonto.ambos => 'Comedouro e bebedouro',
  };

  // Versão curta do nome, usada na escolha do tipo no cadastro
  String get rotuloCurto => this == TipoDePonto.ambos ? 'Os dois' : rotulo;
}

// Um comedouro ou bebedouro público, com a localização e quem o cadastrou
class PontoDeAlimentacao {
  final int? id;
  final TipoDePonto tipo;
  // Referência para achar o ponto no local, como "perto do banco da praça"
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

  // Rua e bairro separados por vírgula, omitindo o que estiver vazio
  String get lugar =>
      [rua, bairro].where((parte) => parte.trim().isNotEmpty).join(', ');
}

// O registro de que alguém abasteceu um ponto em uma data
class Abastecimento {
  final int? id;
  // O id do ponto abastecido
  final int ponto;
  final DateTime data;
  final String registradoPor;
  // O e-mail de quem registrou; identifica a pessoa, já que nomes se repetem
  final String email;
  // Foto opcional do ponto abastecido, exibida no resumo do ponto
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

// Distância máxima, em metros, entre a pessoa e o ponto para registrar o
// abastecimento
const distanciaMaximaDoPonto = 150.0;

// Por que um abastecimento não pode ser registrado
enum MotivoDaRecusa { longeDoPonto, jaRegistrouHoje }

extension TextoDoMotivo on MotivoDaRecusa {
  // A mensagem exibida para a pessoa
  String get texto => switch (this) {
    MotivoDaRecusa.longeDoPonto =>
      'Você precisa estar no ponto para registrar o abastecimento.',
    MotivoDaRecusa.jaRegistrouHoje =>
      'Você já registrou o abastecimento deste ponto hoje.',
  };
}

// Verifica se o abastecimento pode ser registrado: a pessoa precisa estar a
// até 150 m do ponto e não ter registrado o mesmo ponto no mesmo dia.
// Devolve null quando pode, ou o motivo da recusa
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

// Se a pessoa já registrou o abastecimento deste ponto hoje
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

// O abastecimento mais recente do ponto, ou null se nunca foi abastecido
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

// A situação do ponto conforme o tempo desde o último abastecimento
enum SituacaoDoPonto { abastecido, abastecerLogo, precisa }

extension RotuloDaSituacao on SituacaoDoPonto {
  // O nome da situação como aparece na tela
  String get rotulo => switch (this) {
    SituacaoDoPonto.abastecido => 'Abastecido',
    SituacaoDoPonto.abastecerLogo => 'Abastecer logo',
    SituacaoDoPonto.precisa => 'Precisa de abastecimento',
  };
}

// Classifica o ponto pelos dias desde o último abastecimento: até 2,
// abastecido; de 3 a 6, abastecer logo; 7 ou mais, ou nunca, precisa
SituacaoDoPonto situacaoDoPonto(Abastecimento? ultimo, DateTime agora) {
  if (ultimo == null) return SituacaoDoPonto.precisa;
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(ultimo.data.year, ultimo.data.month, ultimo.data.day);
  final dias = hoje.difference(dia).inDays;
  if (dias <= 2) return SituacaoDoPonto.abastecido;
  if (dias <= 6) return SituacaoDoPonto.abastecerLogo;
  return SituacaoDoPonto.precisa;
}

// Há quanto tempo foi a data: "hoje", "ontem" ou "há 3 dias"
String haQuantoTempo(DateTime data, DateTime agora) {
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(data.year, data.month, data.day);
  final dias = hoje.difference(dia).inDays;
  if (dias <= 0) return 'hoje';
  if (dias == 1) return 'ontem';
  return 'há $dias dias';
}
