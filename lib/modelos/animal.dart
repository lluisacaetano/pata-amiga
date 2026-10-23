// Arquivo dono.dart: modelo do responsável pelo animal.
import 'dono.dart';
// Arquivo json_da_api.dart: leitura e gravação do id da API.
import 'json_da_api.dart';
// Arquivo texto.dart: primeira letra maiúscula e "há N dias".
import 'texto.dart';

// Quem importa o modelo do animal também recebe comMaiuscula
export 'texto.dart' show comMaiuscula;

// O tipo de publicação: animal para adoção, perdido ou que precisa de resgate
enum TipoRegistro { adocao, perdido, resgate }

extension RotuloTipo on TipoRegistro {
  // O nome do tipo como aparece nas abas e etiquetas
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

  // O título da seção de contato na ficha do animal
  String get tituloDoContato => switch (this) {
    TipoRegistro.adocao => 'Quem responde por ele',
    TipoRegistro.perdido => 'Quem está procurando',
    TipoRegistro.resgate => 'Quem encontrou',
  };

  // O título da seção de endereço: no perdido, o lugar é onde foi visto pela
  // última vez; nos outros tipos, é onde o animal está
  String get tituloDoLugar => this == TipoRegistro.perdido
      ? 'Onde foi visto pela última vez'
      : 'Onde ele está';
}

// A situação do animal. Cada tipo tem um desfecho próprio: adoção termina em
// adotado, perdido em encontrado e resgate em resgatado. Com o desfecho
// marcado, o animal deixa de aparecer no feed e no mapa
enum StatusAnimal { disponivel, adotado, encontrado, resgatado }

extension RotuloStatus on StatusAnimal {
  // O nome da situação como aparece na tela
  String get rotulo => switch (this) {
    StatusAnimal.disponivel => 'disponível',
    StatusAnimal.adotado => 'adotado',
    StatusAnimal.encontrado => 'encontrado',
    StatusAnimal.resgatado => 'resgatado',
  };
}

// Um animal publicado no feed, com os dados do cadastro, o responsável e a
// localização. É o mesmo formato usado pela API e pelo cache do aparelho
class Animal {
  // O id gerado pela API, sempre em texto; fica nulo enquanto o animal
  // existe só no aparelho
  final String? id;
  final String nome;
  final String especie;
  final String raca;
  final String sexo;
  final String porte;
  final String idade;
  final String peso;
  final String cor;
  // A rua é guardada para o mapa e para o responsável; o feed e a ficha
  // mostram só o bairro e a cidade
  final String rua;
  final String bairro;
  final String cidade;
  final TipoRegistro tipo;
  final StatusAnimal status;
  final bool castrado;
  final bool vacinado;
  final bool vermifugado;
  final String observacoes;
  // Cuidados particulares do animal: remédio contínuo, dieta, deficiência
  final String necessidadesEspeciais;
  final Dono dono;
  // O e-mail da conta que cadastrou o animal; só ela pode editar e mudar o
  // status. Vazio nos animais de exemplo, que ninguém pode alterar
  final String responsavelEmail;
  // A ONG em nome da qual o animal foi publicado; nulo quando a publicação é
  // da própria pessoa. O perfil da ONG lista os animais por este campo
  final String? ongId;
  final List<String> fotos;
  final DateTime publicadoEm;
  // As coordenadas do animal, preenchidas quando o cadastro usou a
  // localização ou o mapa. Ficam nulas quando o endereço foi só digitado
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
    this.responsavelEmail = '',
    this.ongId,
    this.fotos = const [],
    required this.publicadoEm,
    this.latitude,
    this.longitude,
  });

  // Cria o animal a partir do JSON da API ou do cache do aparelho. Os campos
  // de texto ausentes ficam vazios e o status ausente vale "disponível". Só o
  // tipo e a data de publicação são obrigatórios: sem eles, ou com um tipo
  // desconhecido, gera erro. Campo novo no modelo precisa entrar aqui e no
  // toJson
  factory Animal.fromJson(Map<String, dynamic> json) => Animal(
    id: idDaApi(json['id']),
    nome: json['nome'] as String? ?? '',
    especie: json['especie'] as String? ?? '',
    raca: json['raca'] as String? ?? '',
    sexo: json['sexo'] as String? ?? '',
    porte: json['porte'] as String? ?? '',
    idade: json['idade'] as String? ?? '',
    peso: json['peso'] as String? ?? '',
    cor: json['cor'] as String? ?? '',
    rua: json['rua'] as String? ?? '',
    bairro: json['bairro'] as String? ?? '',
    cidade: json['cidade'] as String? ?? '',
    // Os enums são gravados pelo nome do valor ("adocao", "disponivel")
    tipo: TipoRegistro.values.byName(json['tipo'] as String),
    status:
        StatusAnimal.values
            .where((status) => status.name == json['status'])
            .firstOrNull ??
        StatusAnimal.disponivel,
    castrado: json['castrado'] as bool? ?? false,
    vacinado: json['vacinado'] as bool? ?? false,
    vermifugado: json['vermifugado'] as bool? ?? false,
    observacoes: json['observacoes'] as String? ?? '',
    necessidadesEspeciais: json['necessidadesEspeciais'] as String? ?? '',
    // O dono vem como objeto aninhado dentro do animal
    dono: Dono.fromJson(json['dono'] as Map<String, dynamic>? ?? const {}),
    responsavelEmail: json['responsavelEmail'] as String? ?? '',
    ongId: idDaApi(json['ongId']),
    fotos: List<String>.from(json['fotos'] as List? ?? []),
    // A data é gravada como texto no formato ISO 8601
    publicadoEm: DateTime.parse(json['publicadoEm'] as String),
    // `num?` aceita inteiro, decimal ou nulo
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  // Converte o animal no JSON enviado à API e gravado no cache. Precisa
  // espelhar o fromJson: campo que faltar aqui se perde ao salvar
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': idParaApi(id!),
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
    'responsavelEmail': responsavelEmail,
    if (ongId != null) 'ongId': idParaApi(ongId!),
    'fotos': fotos,
    'publicadoEm': publicadoEm.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };

  // A foto de capa, que é a primeira da lista; vazia quando não há fotos
  String get foto => fotos.isEmpty ? '' : fotos.first;

  // Se o animal tem as duas coordenadas e pode ser desenhado no mapa
  bool get temPonto => latitude != null && longitude != null;

  // O identificador usado pelos avistamentos: o id da API ou, quando o
  // animal existe só no aparelho, o nome
  String get chave => id ?? nome;

  // Se o animal já teve desfecho (adotado, encontrado ou resgatado)
  bool get finalizado => status != StatusAnimal.disponivel;

  // O status final possível para o tipo deste registro
  StatusAnimal get desfecho => switch (tipo) {
    TipoRegistro.adocao => StatusAnimal.adotado,
    TipoRegistro.perdido => StatusAnimal.encontrado,
    TipoRegistro.resgate => StatusAnimal.resgatado,
  };

  // O status como aparece na tela. Sem desfecho, cada tipo tem o seu texto
  String get rotuloDoStatus => finalizado
      ? status.rotulo
      : switch (tipo) {
          TipoRegistro.adocao => 'disponível',
          TipoRegistro.perdido => 'procurando',
          TipoRegistro.resgate => 'precisa de ajuda',
        };

  // Se o e-mail informado é o de quem cadastrou o animal, sem diferenciar
  // maiúsculas nem espaços nas pontas
  bool eDoResponsavel(String email) =>
      email.trim().isNotEmpty &&
      responsavelEmail.trim().toLowerCase() == email.trim().toLowerCase();

  // Uma cópia do animal com outro status; o objeto original não muda
  Animal comStatus(StatusAnimal novo) =>
      Animal.fromJson({...toJson(), 'status': novo.name});

  // Sexo, porte e idade, exibidos abaixo do nome no card do feed
  String get resumo =>
      [sexo, 'porte $porte', idade].map(comMaiuscula).join(' · ');

  // Espécie, raça e sexo, exibidos abaixo do nome na ficha do animal. Os
  // campos vazios ficam de fora
  String get identidade => [
    especie,
    raca,
    sexo,
  ].where((campo) => campo.trim().isNotEmpty).map(comMaiuscula).join(' · ');

  // Há quanto tempo o animal foi publicado ("hoje", "ontem", "há 3 dias",
  // "há 2 meses")
  String publicadoHa(DateTime agora) => haQuantosDias(publicadoEm, agora);
}
