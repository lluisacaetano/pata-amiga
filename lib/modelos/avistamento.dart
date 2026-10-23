// Arquivo animal.dart: modelo do animal, usado para achar os avistamentos dele.
import 'animal.dart';

// O registro de que alguém viu um animal perdido: quando, onde e, se houver,
// uma foto
class Avistamento {
  final int? id;
  // A chave do animal avistado (Animal.chave): o id da API ou, se o animal
  // existe só no aparelho, o nome
  final String animal;
  final DateTime data;
  final double latitude;
  final double longitude;
  // Endereço obtido a partir do ponto no mapa; pode ficar vazio quando o
  // serviço de endereços não o encontra
  final String rua;
  final String bairro;
  final String foto;
  final String registradoPor;
  final DateTime registradoEm;

  Avistamento({
    this.id,
    required this.animal,
    required this.data,
    required this.latitude,
    required this.longitude,
    this.rua = '',
    this.bairro = '',
    this.foto = '',
    this.registradoPor = '',
    required this.registradoEm,
  });

  factory Avistamento.fromJson(Map<String, dynamic> json) => Avistamento(
    id: (json['id'] as num?)?.toInt(),
    animal: json['animal'].toString(),
    data: DateTime.parse(json['data'] as String),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    rua: json['rua'] as String? ?? '',
    bairro: json['bairro'] as String? ?? '',
    foto: json['foto'] as String? ?? '',
    registradoPor: json['registradoPor'] as String? ?? '',
    registradoEm: DateTime.parse(json['registradoEm'] as String),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'animal': animal,
    'data': data.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'rua': rua,
    'bairro': bairro,
    'foto': foto,
    'registradoPor': registradoPor,
    'registradoEm': registradoEm.toIso8601String(),
  };

  // Rua e bairro separados por vírgula, omitindo o que estiver vazio
  String get lugar =>
      [rua, bairro].where((parte) => parte.trim().isNotEmpty).join(', ');

  // Há quanto tempo foi o avistamento: "hoje", "ontem" ou "há 3 dias"
  String vistoHa(DateTime agora) {
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dia = DateTime(data.year, data.month, data.day);
    final dias = hoje.difference(dia).inDays;
    if (dias <= 0) return 'hoje';
    if (dias == 1) return 'ontem';
    return 'há $dias dias';
  }
}

// Os avistamentos de um animal, do mais recente para o mais antigo. Com a
// mesma data, vem primeiro o registrado por último
List<Avistamento> avistamentosDe(Animal animal, Iterable<Avistamento> todos) =>
    todos.where((avistamento) => avistamento.animal == animal.chave).toList()
      ..sort((a, b) {
        final porData = b.data.compareTo(a.data);
        return porData != 0
            ? porData
            : b.registradoEm.compareTo(a.registradoEm);
      });

// O avistamento mais recente do animal, que define onde ele aparece no mapa
Avistamento? ultimoAvistamento(Animal animal, Iterable<Avistamento> todos) {
  final dele = avistamentosDe(animal, todos);
  return dele.isEmpty ? null : dele.first;
}

// A mensagem pronta enviada pelo WhatsApp ao responsável pelo animal
String mensagemParaOTutor(
  Animal animal,
  Avistamento avistamento,
  DateTime agora,
) {
  final quando = avistamento.vistoHa(agora);
  final lugar = avistamento.lugar.isEmpty
      ? ''
      : ', perto de ${avistamento.lugar}';
  return 'Olá! Vi ${animal.nome} $quando$lugar. '
      'Registrei o avistamento no Pata Amiga, com o ponto no mapa.';
}
