import 'dono.dart';

// Os dados chegam em caixa baixa; primeira letra maiúscula
String comMaiuscula(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

enum TipoRegistro { adocao, perdido, resgate }

extension RotuloTipo on TipoRegistro {
  String get rotulo {
    switch (this) {
      case TipoRegistro.adocao:
        return 'adoção';
      case TipoRegistro.perdido:
        return 'perdidos';
      case TipoRegistro.resgate:
        return 'resgate';
    }
  }

  // Titulo do contato
  String get tituloDoContato => switch (this) {
    TipoRegistro.adocao => 'Quem responde por ele',
    TipoRegistro.perdido => 'Quem está procurando',
    TipoRegistro.resgate => 'Quem encontrou',
  };

  // Em perdidos o lugar é a última pista, nos outros é onde o animal está
  String get tituloDoLugar => this == TipoRegistro.perdido
      ? 'Onde foi visto pela última vez'
      : 'Onde ele está';
}

enum StatusAnimal { disponivel, adotado }

extension RotuloStatus on StatusAnimal {
  String get rotulo =>
      this == StatusAnimal.disponivel ? 'disponível' : 'adotado';
}

class Animal {
  // O id que a API dá; animal cadastrado só no aparelho não tem
  final int? id;
  final String nome;
  final String especie;
  final String raca;
  final String sexo;
  final String porte;
  final String idade;
  final String peso;
  final String cor;
  // Fica guardada para o mapa e para o responsável; o feed e a ficha
  // mostram só bairro e cidade
  final String rua;
  final String bairro;
  final String cidade;
  final TipoRegistro tipo;
  final StatusAnimal status;
  final bool castrado;
  final bool vacinado;
  final bool vermifugado;
  final String observacoes;
  // O que esse animal precisa e os outros não: remédio contínuo, dieta, deficiência
  final String necessidadesEspeciais;
  final Dono dono;
  final List<String> fotos;
  final DateTime publicadoEm;
  // Salva a localização do aparelho quando a pessoa tocou no botão de localização
  // Fica vazio quando o endereço foi digitado à mão
  final double? latitude;
  final double? longitude;

  Animal({
    this.id,
    required this.nome,
    required this.especie,
    required this.raca,
    required this.sexo,
    required this.porte,
    required this.idade,
    required this.peso,
    required this.cor,
    this.rua = '',
    required this.bairro,
    required this.cidade,
    required this.tipo,
    this.status = StatusAnimal.disponivel,
    this.castrado = false,
    this.vacinado = false,
    this.vermifugado = false,
    this.observacoes = '',
    this.necessidadesEspeciais = '',
    required this.dono,
    this.fotos = const [],
    required this.publicadoEm,
    this.latitude,
    this.longitude,
  });

  // [SPRINT 3 - NOVO] Cria um Animal a partir do JSON da API ou do cache local.
  // Usado por AnimalService (lê a API) e CacheService (lê o cache offline).
  // Campos com `?? ''` ou `?? false` são opcionais: JSON incompleto não quebra.
  // Se um campo novo for criado no model, lembrar de incluir aqui e no toJson.
  factory Animal.fromJson(Map<String, dynamic> json) => Animal(
        id: (json['id'] as num?)?.toInt(),
        nome: json['nome'] as String,
        especie: json['especie'] as String,
        raca: json['raca'] as String? ?? '',
        sexo: json['sexo'] as String,
        porte: json['porte'] as String,
        idade: json['idade'] as String,
        peso: json['peso'] as String? ?? '',
        cor: json['cor'] as String? ?? '',
        rua: json['rua'] as String? ?? '',
        bairro: json['bairro'] as String,
        cidade: json['cidade'] as String,
        // Enums chegam como texto com o nome do valor ("adocao", "disponivel")
        tipo: TipoRegistro.values.byName(json['tipo'] as String),
        status: StatusAnimal.values
            .byName(json['status'] as String? ?? 'disponivel'),
        castrado: json['castrado'] as bool? ?? false,
        vacinado: json['vacinado'] as bool? ?? false,
        vermifugado: json['vermifugado'] as bool? ?? false,
        observacoes: json['observacoes'] as String? ?? '',
        necessidadesEspeciais: json['necessidadesEspeciais'] as String? ?? '',
        // O dono é um objeto aninhado: usa o Dono.fromJson (dono.dart)
        dono: Dono.fromJson(json['dono'] as Map<String, dynamic>),
        fotos: List<String>.from(json['fotos'] as List? ?? []),
        // A data chega como texto ISO 8601 (ex.: 2026-10-14T12:00:00.000)
        publicadoEm: DateTime.parse(json['publicadoEm'] as String),
        // `num?` porque o JSON pode trazer inteiro ou decimal, ou null
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  // [SPRINT 3 - NOVO] Converte o Animal em Map para o CacheService salvar
  // no SharedPreferences. Tem que espelhar o fromJson: se um campo faltar
  // aqui, ele some quando o app ler do cache em modo avião.
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'nome': nome,
        'especie': especie,
        'raca': raca,
        'sexo': sexo,
        'porte': porte,
        'idade': idade,
        'peso': peso,
        'cor': cor,
        'rua': rua,
        'bairro': bairro,
        'cidade': cidade,
        'tipo': tipo.name,
        'status': status.name,
        'castrado': castrado,
        'vacinado': vacinado,
        'vermifugado': vermifugado,
        'observacoes': observacoes,
        'necessidadesEspeciais': necessidadesEspeciais,
        'dono': dono.toJson(),
        'fotos': fotos,
        'publicadoEm': publicadoEm.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
      };

  // A capa do animal é a primeira foto
  String get foto => fotos.isEmpty ? '' : fotos.first;

  // Os mapas só conseguem desenhar o animal quando as duas coordenadas existem
  bool get temPonto => latitude != null && longitude != null;

  // Como o avistamento acha o animal: pelo id da API, ou pelo nome quando o
  // animal ainda só existe no aparelho
  String get chave => id?.toString() ?? nome;

  // Descrição curta do animal, exibida embaixo do nome no card do feed.
  String get resumo =>
      [sexo, 'porte $porte', idade].map(comMaiuscula).join(' · ');

  // Quem é o animal, na linha embaixo do nome na ficha de detalhes
  String get identidade => [especie, raca, sexo]
      .where((campo) => campo.trim().isNotEmpty)
      .map(comMaiuscula)
      .join(' · ');

  // Há quanto tempo o animal foi publicado, no formato que vai no card.
  // Compara só o dia, porque a hora não interessa a quem lê o feed.
  String publicadoHa(DateTime agora) {
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dia = DateTime(publicadoEm.year, publicadoEm.month, publicadoEm.day);
    final dias = hoje.difference(dia).inDays;

    if (dias <= 0) return 'hoje';
    if (dias == 1) return 'ontem';
    if (dias <= 30) return 'há $dias dias';

    final meses = dias ~/ 30;
    return meses == 1 ? 'há 1 mês' : 'há $meses meses';
  }
}