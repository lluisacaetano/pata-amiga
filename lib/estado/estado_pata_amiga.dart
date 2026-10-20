import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/animal.dart';
import '../modelos/avistamento.dart';
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

  void adicionarAvistamento(Avistamento avistamento) {
    _avistamentos = [..._avistamentos, avistamento];
    notifyListeners();
  }

  List<Animal> get animaisCurtidos => _animais
      .where(
        (animal) =>
            _curtidos.contains(animal.nome) &&
            animal.status != StatusAnimal.adotado,
      )
      .toList(growable: false);

  void atualizarAnimais(List<Animal> animais) {
    _animais = List.unmodifiable(animais);
    notifyListeners();
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
  static EstadoPataAmiga? talvez(BuildContext context) => context
      .getInheritedWidgetOfExactType<PataAmigaScope>()
      ?.notifier;

  static EstadoPataAmiga of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PataAmigaScope>();
    assert(scope != null, 'PataAmigaScope não encontrado na árvore.');
    return scope!.notifier!;
  }
}
