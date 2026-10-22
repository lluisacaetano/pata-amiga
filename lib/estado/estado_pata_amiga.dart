import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/animal.dart';
import '../modelos/avistamento.dart';
import '../modelos/ong.dart';
import '../modelos/ponto_de_alimentacao.dart';

class EstadoPataAmiga extends ChangeNotifier {
  // Chave usada para gravar as curtidas no armazenamento do aparelho
  static const _chaveCurtidos = 'curtidos';
  static const _chaveMeusCadastros = 'meus_cadastros';

  // Guarda o nome dos animais que o usuário curtiu
  final Set<String> _curtidos = {};
  List<Animal> _animais = [];
  final List<Animal> _meusCadastros = [];
  bool _descartado = false;

  bool estaCurtido(String nome) => _curtidos.contains(nome);

  List<Animal> get meusCadastros => List.unmodifiable(_meusCadastros);

  // Os animais que o feed carregou, para as telas que também os mostram
  List<Animal> get animais => _animais;

  // Os avistamentos de animais perdidos, que movem o pino no mapa
  List<Avistamento> _avistamentos = [];
  List<Avistamento> get avistamentos => List.unmodifiable(_avistamentos);

  void atualizarAvistamentos(List<Avistamento> avistamentos) {
    _avistamentos = List.of(avistamentos);
    notifyListeners();
  }

  // Os comedouros e bebedouros e quem os abasteceu, para a camada do mapa
  List<PontoDeAlimentacao> _pontos = [];
  List<Abastecimento> _abastecimentos = [];
  List<PontoDeAlimentacao> get pontos => List.unmodifiable(_pontos);
  List<Abastecimento> get abastecimentos => List.unmodifiable(_abastecimentos);

  void atualizarAlimentacao(
    List<PontoDeAlimentacao> pontos,
    List<Abastecimento> abastecimentos,
  ) {
    _pontos = List.of(pontos);
    _abastecimentos = List.of(abastecimentos);
    notifyListeners();
  }

  void adicionarPonto(PontoDeAlimentacao ponto) {
    _pontos = [..._pontos, ponto];
    notifyListeners();
  }

  void adicionarAbastecimento(Abastecimento abastecimento) {
    _abastecimentos = [..._abastecimentos, abastecimento];
    notifyListeners();
  }

  // As ONGs e abrigos, para a lista do menu, o perfil e a ficha do animal
  List<Ong> _ongs = [];
  List<Ong> get ongs => List.unmodifiable(_ongs);

  void atualizarOngs(List<Ong> ongs) {
    _ongs = List.of(ongs);
    notifyListeners();
  }

  // Põe a ONG criada ou troca a editada pela versão nova
  void salvarOng(Ong ong) {
    final indice = _ongs.indexWhere((item) => item.id == ong.id);
    _ongs = indice >= 0
        ? [for (final item in _ongs) item.id == ong.id ? ong : item]
        : [..._ongs, ong];
    notifyListeners();
  }

  // A ONG de que essa pessoa faz parte, ou null: cada conta tem no máximo
  // uma, criada por ela ou em que o pedido para entrar foi aprovado
  Ong? ongDe(String email) {
    for (final ong in _ongs) {
      if (ong.fazParte(email)) return ong;
    }
    return null;
  }

  // Os avisos das ONGs para essa pessoa (aprovado, recusado, removido),
  // enquanto ela não os dispensa
  List<(Ong, AvisoDaOng)> avisosPara(String email) => [
    for (final ong in _ongs)
      if (ong.avisoPara(email) case final aviso?) (ong, aviso),
  ];

  // A ONG em que essa pessoa pediu para entrar e ainda espera resposta
  Ong? ongPedidaPor(String email) {
    for (final ong in _ongs) {
      if (ong.pediuEntrada(email)) return ong;
    }
    return null;
  }

  // Os animais publicados em nome da ONG, do mais novo para o mais antigo:
  // o recém-cadastrado é sempre o primeiro. Os que a pessoa publicou em nome
  // próprio não entram, mesmo sendo da mesma conta
  List<Animal> animaisDa(Ong ong) =>
      _animais
          .where((animal) => ong.id != null && animal.ongId == ong.id)
          .toList()
        ..sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));

  void adicionarAvistamento(Avistamento avistamento) {
    _avistamentos = [..._avistamentos, avistamento];
    notifyListeners();
  }

  List<Animal> get animaisCurtidos => _animais
      .where((animal) => _curtidos.contains(animal.nome) && !animal.finalizado)
      .toList(growable: false);

  void atualizarAnimais(List<Animal> animais) {
    _animais = List.unmodifiable(animais);
    notifyListeners();
  }

  // Troca um animal pela versão nova (o status mudou), no feed e nos
  // cadastros do usuário, e grava os cadastros no aparelho
  // Na edição, o nome pode mudar, e o animal só do aparelho é achado pelo
  // nome: por isso dá para dizer qual era a chave antes
  Future<void> substituirAnimal(Animal novo, {String? chaveAntiga}) async {
    final chave = chaveAntiga ?? novo.chave;
    _animais = [
      for (final animal in _animais) animal.chave == chave ? novo : animal,
    ];
    final indice = _meusCadastros.indexWhere((animal) => animal.chave == chave);
    if (indice >= 0) _meusCadastros[indice] = novo;
    notifyListeners();
    if (indice >= 0) {
      final armazenamento = await SharedPreferences.getInstance();
      await armazenamento.setString(
        _chaveMeusCadastros,
        jsonEncode(
          _meusCadastros.map((registro) => registro.toJson()).toList(),
        ),
      );
    }
  }

  // A versão mais nova de um animal: a tela pode ter recebido uma cópia antiga
  Animal atual(Animal animal) => _animais.firstWhere(
    (item) => item.chave == animal.chave,
    orElse: () => _meusCadastros.firstWhere(
      (item) => item.chave == animal.chave,
      orElse: () => animal,
    ),
  );

  // Os cadastros de quem está logado: os feitos neste aparelho e os da API
  // registrados no e-mail dele, do mais novo para o mais antigo. Os
  // publicados em nome de uma ONG ficam só no perfil dela, para não
  // aparecerem duas vezes
  List<Animal> cadastrosDe(String email) {
    final chaves = _meusCadastros.map((animal) => animal.chave).toSet();
    return [
        ..._meusCadastros,
        ..._animais.where(
          (animal) =>
              !chaves.contains(animal.chave) && animal.eDoResponsavel(email),
        ),
      ].where((animal) => animal.ongId == null).toList()
      ..sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));
  }

  // Quem pode mudar o status: o e-mail de quem cadastrou ou, nos cadastros
  // gravados antes de o app guardar o e-mail, quem os fez neste aparelho
  bool podeMudarStatus(Animal animal, String email) {
    // O animal da ONG é de toda a ONG: quem faz parte dela, admin ou membro,
    // cuida de qualquer um, mesmo os que outra pessoa cadastrou
    // Quem saiu ou foi removido da ONG deixa de cuidar dos animais dela,
    // mesmo dos que cadastrou
    if (animal.ongId != null) return ongDe(email)?.id == animal.ongId;
    if (animal.responsavelEmail.trim().isNotEmpty) {
      return animal.eDoResponsavel(email);
    }
    return email.trim().isNotEmpty &&
        _meusCadastros.any((item) => item.chave == animal.chave);
  }

  Future<void> carregarCurtidos() async {
    final armazenamento = await SharedPreferences.getInstance();
    if (_descartado) return;
    _curtidos
      ..clear()
      ..addAll(armazenamento.getStringList(_chaveCurtidos) ?? const []);
    final registrosSalvos = armazenamento.getString(_chaveMeusCadastros);
    if (registrosSalvos != null) {
      try {
        final registros = jsonDecode(registrosSalvos) as List;
        _meusCadastros
          ..clear()
          ..addAll(
            registros.map(
              (registro) => Animal.fromJson(registro as Map<String, dynamic>),
            ),
          );
      } on FormatException {
        _meusCadastros.clear();
      } on TypeError {
        _meusCadastros.clear();
      }
    }
    notifyListeners();
  }

  Future<void> registrarCadastro(Animal animal) async {
    _meusCadastros.removeWhere((registro) => registro.nome == animal.nome);
    _meusCadastros.insert(0, animal);
    notifyListeners();

    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setString(
      _chaveMeusCadastros,
      jsonEncode(_meusCadastros.map((registro) => registro.toJson()).toList()),
    );
  }

  Future<void> alternarCurtida(String nome) async {
    if (!_curtidos.add(nome)) _curtidos.remove(nome);
    notifyListeners();

    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setStringList(_chaveCurtidos, _curtidos.toList());
  }

  Future<void> removerCurtida(String nome) async {
    if (!_curtidos.remove(nome)) return;
    notifyListeners();

    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setStringList(_chaveCurtidos, _curtidos.toList());
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}

class PataAmigaScope extends InheritedNotifier<EstadoPataAmiga> {
  const PataAmigaScope({
    super.key,
    required EstadoPataAmiga notifier,
    required super.child,
  }) : super(notifier: notifier);

  // Para quem só precisa ler uma vez, como no initState, sem passar a ouvir
  // as mudanças; devolve null se a tela estiver fora do escopo
  static EstadoPataAmiga? talvez(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PataAmigaScope>()?.notifier;

  static EstadoPataAmiga of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PataAmigaScope>();
    assert(scope != null, 'PataAmigaScope não encontrado na árvore.');
    return scope!.notifier!;
  }
}
