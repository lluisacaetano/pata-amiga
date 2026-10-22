// Uma pessoa ligada à ONG: quem pediu para entrar ou quem já faz parte. As
// contas ficam no aparelho, então a ONG guarda o nome e o telefone junto do
// e-mail, para quem aprova saber quem é
class PessoaDaOng {
  final String email;
  final String nome;
  final String telefone;
  // Quando pediu para entrar, para as notificações saírem em ordem de tempo
  final DateTime? em;

  const PessoaDaOng({
    required this.email,
    required this.nome,
    this.telefone = '',
    this.em,
  });
}

// O que a ONG avisa a uma pessoa pelo sino: o pedido aprovado, o pedido
// recusado ou que ela foi removida. Fica até a pessoa dispensar
enum TipoDeAviso { aprovado, recusado, removido }

class AvisoDaOng {
  final String email;
  final TipoDeAviso tipo;
  final DateTime? em;

  const AvisoDaOng({required this.email, required this.tipo, this.em});
}

// Uma ONG ou abrigo. Quem cria o perfil é uma pessoa logada, que passa a
// administrá-la (responsavelEmail); os animais da ONG são os publicados com o
// ongId dela. O app não confere se a conta é mesmo de uma ONG; isso seria do
// parceiro institucional (premissa (a) da Sprint 0)
class Ong {
  final int? id;
  final String nome;
  final String descricao;
  final String politicaDeAdocao;
  final String telefone;
  // Só é exibida: o app não processa doações (premissa da Sprint 0)
  final String chavePix;
  final String foto;
  final String rua;
  final String bairro;
  final double? latitude;
  final double? longitude;
  final String responsavelEmail;
  final DateTime criadaEm;
  // Quem faz parte, além da admin: publica em nome da ONG e cuida dos animais
  final List<PessoaDaOng> membros;
  // Quem pediu para entrar e espera a aprovação da admin
  final List<PessoaDaOng> pedidos;
  // Os avisos que as pessoas ainda não dispensaram, um por pessoa
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
    this.membros = const [],
    this.pedidos = const [],
    this.avisos = const [],
  });

  bool get temLocal => latitude != null && longitude != null;

  static String _limpo(String email) => email.trim().toLowerCase();

  // O nome como se compara: sem maiúsculas, acentos e espaços a mais. Assim
  // "Abrigo São Francisco" e "abrigo sao  francisco" são a mesma ONG
  static String nomeComparavel(String nome) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    final limpo = nome.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return [
      for (final letra in limpo.split(''))
        de.contains(letra) ? para[de.indexOf(letra)] : letra,
    ].join();
  }

  bool temNome(String outro) => nomeComparavel(nome) == nomeComparavel(outro);

  // Faz parte: a admin ou quem teve o pedido aprovado
  bool fazParte(String email) =>
      eDoResponsavel(email) ||
      membros.any((pessoa) => _limpo(pessoa.email) == _limpo(email));

  bool pediuEntrada(String email) =>
      email.trim().isNotEmpty &&
      pedidos.any((pessoa) => _limpo(pessoa.email) == _limpo(email));

  Ong _com({List<PessoaDaOng>? membros, List<PessoaDaOng>? pedidos}) =>
      Ong.fromJson({
        ...toJson(),
        'membros': _pessoasEmJson(membros ?? this.membros),
        'pedidos': _pessoasEmJson(pedidos ?? this.pedidos),
      });

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
          // Pedir de novo apaga o aviso antigo de remoção
        ).semAviso(pessoa.email);

  // Aprovar tira dos pedidos e põe nos membros; recusar só tira
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

  // O aviso que a ONG deixou para essa pessoa, se houver
  AvisoDaOng? avisoPara(String email) => email.trim().isEmpty
      ? null
      : avisos
            .where((aviso) => _limpo(aviso.email) == _limpo(email))
            .firstOrNull;

  bool foiRemovida(String email) =>
      avisoPara(email)?.tipo == TipoDeAviso.removido;

  // Um aviso novo para a pessoa substitui o anterior
  Ong comAviso(String email, TipoDeAviso tipo) => Ong.fromJson({
    ...toJson(),
    'avisos': _avisosEmJson([
      ...avisos.where((aviso) => _limpo(aviso.email) != _limpo(email)),
      AvisoDaOng(email: email, tipo: tipo, em: DateTime.now()),
    ]),
  });

  // A admin remove: a pessoa sai e fica o aviso para ela
  Ong removendo(String email) => fazParte(email) && !eDoResponsavel(email)
      ? semAPessoa(email).comAviso(email, TipoDeAviso.removido)
      : this;

  // A pessoa dispensou o aviso
  Ong semAviso(String email) => Ong.fromJson({
    ...toJson(),
    'avisos': _avisosEmJson([
      for (final aviso in avisos)
        if (_limpo(aviso.email) != _limpo(email)) aviso,
    ]),
  });

  static List<Map<String, String>> _avisosEmJson(List<AvisoDaOng> avisos) => [
    for (final aviso in avisos)
      {
        'email': aviso.email,
        'tipo': aviso.tipo.name,
        if (aviso.em != null) 'em': aviso.em!.toIso8601String(),
      },
  ];

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

  // Sair da ONG ou desistir do pedido: a pessoa sai das duas listas
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

  // A admin passa a ONG para um membro e sai: o membro vira a admin,
  // com o editar, a chave Pix e os pedidos
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

  static List<PessoaDaOng> _pessoas(Object? lista) => [
    for (final item in (lista as List?) ?? const [])
      PessoaDaOng(
        email: (item as Map)['email'] as String? ?? '',
        nome: item['nome'] as String? ?? '',
        telefone: item['telefone'] as String? ?? '',
        em: DateTime.tryParse(item['em'] as String? ?? ''),
      ),
  ];

  // A mesma regra do animal: e-mail sem ligar para maiúsculas e espaços
  bool eDoResponsavel(String email) =>
      email.trim().isNotEmpty &&
      responsavelEmail.trim().toLowerCase() == email.trim().toLowerCase();

  factory Ong.fromJson(Map<String, dynamic> json) => Ong(
    id: (json['id'] as num?)?.toInt(),
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
    membros: _pessoas(json['membros']),
    pedidos: _pessoas(json['pedidos']),
    avisos: _avisos(json['avisos']),
  );

  // Sem o id quando ainda não existe: quem dá o id é a API
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
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
    'membros': _pessoasEmJson(membros),
    'pedidos': _pessoasEmJson(pedidos),
    'avisos': _avisosEmJson(avisos),
  };
}
