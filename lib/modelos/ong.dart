// Arquivo json_da_api.dart: leitura e gravação do id da API.
import 'json_da_api.dart';
// Arquivo texto.dart: comparação de nomes sem acentos.
import 'texto.dart';

// Uma pessoa ligada à ONG: membro ou alguém que pediu para entrar. Como as
// contas ficam só no aparelho de cada pessoa, a ONG guarda o nome e o
// telefone junto do e-mail, para a administração saber quem é
class PessoaDaOng {
  final String email;
  final String nome;
  final String telefone;
  // Quando a pessoa pediu para entrar; ordena as notificações
  final DateTime? em;

  const PessoaDaOng({
    required this.email,
    required this.nome,
    this.telefone = '',
    this.em,
  });
}

// Os avisos que a ONG deixa para uma pessoa no sino de notificações: pedido
// aprovado, pedido recusado ou remoção. O aviso fica até ser dispensado
enum TipoDeAviso { aprovado, recusado, removido }

// Um aviso da ONG para uma pessoa, identificada pelo e-mail
class AvisoDaOng {
  final String email;
  final TipoDeAviso tipo;
  final DateTime? em;

  const AvisoDaOng({required this.email, required this.tipo, this.em});
}

// O que a organização faz. Só [denuncias] muda o funcionamento do app: a
// organização passa a receber denúncias de maus-tratos
enum FinalidadeDaOng { adocao, perdidos, resgate, denuncias }

extension RotuloDaFinalidade on FinalidadeDaOng {
  // Texto exibido no cadastro e nas etiquetas do perfil
  String get rotulo => switch (this) {
    FinalidadeDaOng.adocao => 'Adoção',
    FinalidadeDaOng.perdidos => 'Perdidos',
    FinalidadeDaOng.resgate => 'Resgate',
    FinalidadeDaOng.denuncias => 'Recebe denúncias',
  };
}

// Finalidades de uma ONG gravada antes de o campo existir: as três abas do
// feed, sem receber denúncias
const finalidadesPadrao = {
  FinalidadeDaOng.adocao,
  FinalidadeDaOng.perdidos,
  FinalidadeDaOng.resgate,
};

// Uma ONG ou abrigo. A conta que cria o perfil passa a administrá-lo
// (responsavelEmail), e os animais da ONG são os publicados com o ongId dela.
// O app não verifica se a conta pertence de fato a uma organização
class Ong {
  // O id gerado pela API, sempre em texto
  final String? id;
  final String nome;
  final String descricao;
  final String politicaDeAdocao;
  final String telefone;
  // Apenas exibida no perfil; o app não processa doações
  final String chavePix;
  final String foto;
  final String rua;
  final String bairro;
  final double? latitude;
  final double? longitude;
  final String responsavelEmail;
  final DateTime criadaEm;
  // O que a organização faz; pelo menos uma finalidade
  final Set<FinalidadeDaOng> finalidades;
  // Os membros, além de quem administra; podem publicar em nome da ONG
  final List<PessoaDaOng> membros;
  // Os pedidos de entrada aguardando resposta da administração
  final List<PessoaDaOng> pedidos;
  // Os avisos ainda não dispensados, no máximo um por pessoa
  final List<AvisoDaOng> avisos;

  const Ong({
    this.id,
    required this.nome,
    required this.descricao,
    this.politicaDeAdocao = '',
    required this.telefone,
    this.chavePix = '',
    this.foto = '',
    this.rua = '',
    this.bairro = '',
    this.latitude,
    this.longitude,
    required this.responsavelEmail,
    required this.criadaEm,
    this.finalidades = finalidadesPadrao,
    this.membros = const [],
    this.pedidos = const [],
    this.avisos = const [],
  });

  // Se a organização recebe denúncias de maus-tratos pelo app
  bool get recebeDenuncias => finalidades.contains(FinalidadeDaOng.denuncias);

  // Se a ONG tem as duas coordenadas para aparecer no mapa
  bool get temLocal => latitude != null && longitude != null;

  // O e-mail sem espaços nas pontas e em minúsculas, para comparação
  static String _limpo(String email) => email.trim().toLowerCase();

  // O nome normalizado para comparação: sem maiúsculas, acentos e espaços
  // repetidos. "Abrigo São Francisco" e "abrigo sao  francisco" são iguais
  static String nomeComparavel(String nome) => semAcento(nome);

  // Se a ONG tem esse nome, pela comparação normalizada
  bool temNome(String outro) => nomeComparavel(nome) == nomeComparavel(outro);

  // Se a pessoa faz parte da ONG: quem administra ou um membro
  bool fazParte(String email) =>
      eDoResponsavel(email) ||
      membros.any((pessoa) => _limpo(pessoa.email) == _limpo(email));

  // Se a pessoa tem um pedido de entrada pendente
  bool pediuEntrada(String email) =>
      email.trim().isNotEmpty &&
      pedidos.any((pessoa) => _limpo(pessoa.email) == _limpo(email));

  // Cópia da ONG com outras listas de membros ou de pedidos
  Ong _com({List<PessoaDaOng>? membros, List<PessoaDaOng>? pedidos}) =>
      Ong.fromJson({
        ...toJson(),
        'membros': _pessoasEmJson(membros ?? this.membros),
        'pedidos': _pessoasEmJson(pedidos ?? this.pedidos),
      });

  // Acrescenta o pedido de entrada da pessoa. Quem já faz parte ou já pediu
  // não gera pedido novo
  Ong comPedidoDe(PessoaDaOng pessoa) =>
      fazParte(pessoa.email) || pediuEntrada(pessoa.email)
      ? this
      : _com(
          pedidos: [
            ...pedidos,
            PessoaDaOng(
              email: pessoa.email,
              nome: pessoa.nome,
              telefone: pessoa.telefone,
              em: pessoa.em ?? DateTime.now(),
            ),
          ],
          // Um pedido novo apaga o aviso anterior da pessoa
        ).semAviso(pessoa.email);

  // Responde ao pedido: aprovar move a pessoa para os membros, recusar
  // apenas remove o pedido. Nos dois casos, deixa um aviso para ela
  Ong respondendo(String email, {required bool aprovar}) {
    final pedido = pedidos.where(
      (pessoa) => _limpo(pessoa.email) == _limpo(email),
    );
    if (pedido.isEmpty) return this;
    return _com(
      pedidos: [
        for (final pessoa in pedidos)
          if (_limpo(pessoa.email) != _limpo(email)) pessoa,
      ],
      membros: aprovar ? [...membros, pedido.first] : membros,
    ).comAviso(
      pedido.first.email,
      aprovar ? TipoDeAviso.aprovado : TipoDeAviso.recusado,
    );
  }

  // O aviso deixado para a pessoa, ou null se não houver
  AvisoDaOng? avisoPara(String email) => email.trim().isEmpty
      ? null
      : avisos
            .where((aviso) => _limpo(aviso.email) == _limpo(email))
            .firstOrNull;

  // Se a pessoa foi removida e ainda não dispensou o aviso
  bool foiRemovida(String email) =>
      avisoPara(email)?.tipo == TipoDeAviso.removido;

  // Deixa um aviso para a pessoa, substituindo o anterior
  Ong comAviso(String email, TipoDeAviso tipo) => Ong.fromJson({
    ...toJson(),
    'avisos': _avisosEmJson([
      ...avisos.where((aviso) => _limpo(aviso.email) != _limpo(email)),
      AvisoDaOng(email: email, tipo: tipo, em: DateTime.now()),
    ]),
  });

  // Remove um membro e deixa o aviso de remoção. Quem administra não pode
  // ser removido
  Ong removendo(String email) => fazParte(email) && !eDoResponsavel(email)
      ? semAPessoa(email).comAviso(email, TipoDeAviso.removido)
      : this;

  // Apaga o aviso deixado para a pessoa
  Ong semAviso(String email) => Ong.fromJson({
    ...toJson(),
    'avisos': _avisosEmJson([
      for (final aviso in avisos)
        if (_limpo(aviso.email) != _limpo(email)) aviso,
    ]),
  });

  // Os avisos no formato JSON
  static List<Map<String, String>> _avisosEmJson(List<AvisoDaOng> avisos) => [
    for (final aviso in avisos)
      {
        'email': aviso.email,
        'tipo': aviso.tipo.name,
        if (aviso.em != null) 'em': aviso.em!.toIso8601String(),
      },
  ];

  // Lê os avisos do JSON, descartando os de tipo desconhecido
  static List<AvisoDaOng> _avisos(Object? lista) => [
    for (final item in (lista as List?) ?? const [])
      if (TipoDeAviso.values
              .where((tipo) => tipo.name == (item as Map)['tipo'])
              .firstOrNull
          case final tipo?)
        AvisoDaOng(
          email: (item as Map)['email'] as String? ?? '',
          tipo: tipo,
          em: DateTime.tryParse(item['em'] as String? ?? ''),
        ),
  ];

  // Tira a pessoa dos membros e dos pedidos (saída ou desistência)
  Ong semAPessoa(String email) => _com(
    membros: [
      for (final pessoa in membros)
        if (_limpo(pessoa.email) != _limpo(email)) pessoa,
    ],
    pedidos: [
      for (final pessoa in pedidos)
        if (_limpo(pessoa.email) != _limpo(email)) pessoa,
    ],
  );

  // Transfere a administração para um membro. Ele deixa a lista de membros
  // e passa a ser o responsável; quem administrava sai da ONG
  Ong passandoPara(String email) {
    final novo = membros.where(
      (pessoa) => _limpo(pessoa.email) == _limpo(email),
    );
    if (novo.isEmpty) return this;
    return Ong.fromJson({
      ...toJson(),
      'responsavelEmail': novo.first.email,
      'membros': _pessoasEmJson([
        for (final pessoa in membros)
          if (_limpo(pessoa.email) != _limpo(email)) pessoa,
      ]),
    });
  }

  // As pessoas no formato JSON
  static List<Map<String, String>> _pessoasEmJson(List<PessoaDaOng> pessoas) =>
      [
        for (final pessoa in pessoas)
          {
            'email': pessoa.email,
            'nome': pessoa.nome,
            'telefone': pessoa.telefone,
            if (pessoa.em != null) 'em': pessoa.em!.toIso8601String(),
          },
      ];

  // Lê as pessoas do JSON; campos ausentes ficam vazios
  static List<PessoaDaOng> _pessoas(Object? lista) => [
    for (final item in (lista as List?) ?? const [])
      PessoaDaOng(
        email: (item as Map)['email'] as String? ?? '',
        nome: item['nome'] as String? ?? '',
        telefone: item['telefone'] as String? ?? '',
        em: DateTime.tryParse(item['em'] as String? ?? ''),
      ),
  ];

  // Se o e-mail é o de quem administra, sem diferenciar maiúsculas nem
  // espaços nas pontas
  bool eDoResponsavel(String email) =>
      email.trim().isNotEmpty &&
      responsavelEmail.trim().toLowerCase() == email.trim().toLowerCase();

  // Lê as finalidades gravadas, ignorando valores desconhecidos. Sem o
  // campo, ou sem nenhuma finalidade válida, vale o padrão
  static Set<FinalidadeDaOng> _finalidades(Object? valor) {
    final lidas = {
      if (valor is List)
        for (final item in valor)
          for (final finalidade in FinalidadeDaOng.values)
            if (finalidade.name == item) finalidade,
    };
    return lidas.isEmpty ? finalidadesPadrao : lidas;
  }

  // Cria a ONG a partir do JSON da API; campos ausentes recebem um padrão
  factory Ong.fromJson(Map<String, dynamic> json) => Ong(
    id: idDaApi(json['id']),
    nome: json['nome'] as String? ?? '',
    descricao: json['descricao'] as String? ?? '',
    politicaDeAdocao: json['politicaDeAdocao'] as String? ?? '',
    telefone: json['telefone'] as String? ?? '',
    chavePix: json['chavePix'] as String? ?? '',
    foto: json['foto'] as String? ?? '',
    rua: json['rua'] as String? ?? '',
    bairro: json['bairro'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    responsavelEmail: json['responsavelEmail'] as String? ?? '',
    criadaEm:
        DateTime.tryParse(json['criadaEm'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    finalidades: _finalidades(json['finalidades']),
    membros: _pessoas(json['membros']),
    pedidos: _pessoas(json['pedidos']),
    avisos: _avisos(json['avisos']),
  );

  // Converte a ONG no JSON da API. Sem id, a ONG ainda não foi criada e a
  // API gera o id
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': idParaApi(id!),
    'nome': nome,
    'descricao': descricao,
    'politicaDeAdocao': politicaDeAdocao,
    'telefone': telefone,
    'chavePix': chavePix,
    'foto': foto,
    'rua': rua,
    'bairro': bairro,
    'latitude': latitude,
    'longitude': longitude,
    'responsavelEmail': responsavelEmail,
    'criadaEm': criadaEm.toIso8601String(),
    'finalidades': [for (final finalidade in finalidades) finalidade.name],
    'membros': _pessoasEmJson(membros),
    'pedidos': _pessoasEmJson(pedidos),
    'avisos': _avisosEmJson(avisos),
  };
}
