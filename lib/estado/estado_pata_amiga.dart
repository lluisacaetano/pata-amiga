// Biblioteca dart:async: unawaited, para regravar sem esperar.
import 'dart:async';
// Biblioteca dart:convert: converte texto JSON em objetos e vice-versa.
import 'dart:convert';

// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';

// Arquivo alertas_de_animais.dart: notificações de perdidos e avistamentos.
import '../modelos/alertas_de_animais.dart';
// Arquivo animal.dart: modelo do animal.
import '../modelos/animal.dart';
// Arquivo avisos_de_denuncia.dart: notificações de denúncias.
import '../modelos/avisos_de_denuncia.dart';
// Arquivo avistamento.dart: modelo do avistamento de animal perdido.
import '../modelos/avistamento.dart';
// Arquivo denuncia.dart: denúncias usadas nas notificações.
import '../modelos/denuncia.dart';
// Arquivo ong.dart: modelo da ONG e dos avisos aos membros.
import '../modelos/ong.dart';
// Arquivo ponto_de_alimentacao.dart: pontos e abastecimentos.
import '../modelos/ponto_de_alimentacao.dart';

// Estado compartilhado entre as telas: animais do feed, curtidas, cadastros
// feitos neste aparelho, avistamentos, pontos de alimentação, ONGs e as
// notificações de animais. As curtidas, os cadastros locais e as
// notificações dispensadas ficam salvos no aparelho
class EstadoPataAmiga extends ChangeNotifier {
  // Chaves de gravação no aparelho
  static const _chaveCurtidos = 'curtidos';
  static const _chaveMeusCadastros = 'meus_cadastros';
  static const _chaveAlertasDispensados = 'alertas_dispensados';

  // Chaves dos animais curtidos ([Animal.chave]: o id ou, no animal só
  // local, o nome)
  final Set<String> _curtidos = {};
  List<Animal> _animais = [];
  final List<Animal> _meusCadastros = [];
  // Evita notificar depois do dispose, quando uma leitura termina tarde
  bool _descartado = false;

  bool estaCurtido(String chave) => _curtidos.contains(chave);

  List<Animal> get meusCadastros => List.unmodifiable(_meusCadastros);

  // Animais carregados pelo feed, compartilhados com as outras telas
  List<Animal> get animais => _animais;

  // Última posição conhecida do aparelho, usada para notificar os animais
  // perdidos na região; nula enquanto não houver permissão de localização
  ({double latitude, double longitude})? _posicao;
  ({double latitude, double longitude})? get posicao => _posicao;

  void atualizarPosicao(({double latitude, double longitude}) posicao) {
    _posicao = posicao;
    notifyListeners();
  }

  // Notificações de animais dispensadas, no formato "e-mail|chave", para
  // cada conta do aparelho ter as suas
  final Set<String> _alertasDispensados = {};

  // Notificações de animais ainda não dispensadas pelo e-mail
  List<AlertaDeAnimal> alertasPara(String email) => alertasDeAnimais(
    animais: [..._animais, ..._meusCadastros],
    avistamentos: _avistamentos,
    email: email,
    posicao: _posicao,
    dispensadas: _dispensadasPor(email),
    agora: DateTime.now(),
  );

  // As chaves das notificações que o e-mail já dispensou
  Set<String> _dispensadasPor(String email) {
    final prefixo = '${email.trim().toLowerCase()}|';
    return {
      for (final item in _alertasDispensados)
        if (item.startsWith(prefixo)) item.substring(prefixo.length),
    };
  }

  // Denúncias recebidas pela organização de quem está logado e denúncias
  // feitas neste aparelho, buscadas pelo feed para as notificações
  List<Denuncia> _denunciasDaOrganizacao = [];
  List<Denuncia> _minhasDenuncias = [];

  void atualizarDenuncias({
    required List<Denuncia> daOrganizacao,
    required List<Denuncia> minhas,
  }) {
    _denunciasDaOrganizacao = List.of(daOrganizacao);
    _minhasDenuncias = List.of(minhas);
    notifyListeners();
  }

  // Notificações de denúncias ainda não dispensadas pelo e-mail
  List<AvisoDeDenuncia> avisosDeDenunciaPara(String email) => avisosDeDenuncia(
    daOrganizacao: _denunciasDaOrganizacao,
    minhas: _minhasDenuncias,
    dispensadas: _dispensadasPor(email),
    agora: DateTime.now(),
  );

  // Tira a notificação de animal do sino do e-mail
  Future<void> dispensarAlerta(String email, AlertaDeAnimal alerta) =>
      dispensarNotificacao(email, alerta.chave);

  // Tira a notificação da [chave] do sino do e-mail e salva a escolha no
  // aparelho
  Future<void> dispensarNotificacao(String email, String chave) async {
    _alertasDispensados.add('${email.trim().toLowerCase()}|$chave');
    notifyListeners();
    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setStringList(
      _chaveAlertasDispensados,
      _alertasDispensados.toList(),
    );
  }

  // Avistamentos de animais perdidos; o mais recente define o pino no mapa
  List<Avistamento> _avistamentos = [];
  List<Avistamento> get avistamentos => List.unmodifiable(_avistamentos);

  void atualizarAvistamentos(List<Avistamento> avistamentos) {
    _avistamentos = List.of(avistamentos);
    notifyListeners();
  }

  // Comedouros, bebedouros e seus abastecimentos, para a camada do mapa
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

  // ONGs e abrigos, usados na lista de ONGs, nos perfis e na ficha do animal
  List<Ong> _ongs = [];
  List<Ong> get ongs => List.unmodifiable(_ongs);

  void atualizarOngs(List<Ong> ongs) {
    _ongs = List.of(ongs);
    notifyListeners();
  }

  // Acrescenta a ONG nova ou substitui a de mesmo id pela versão atualizada
  void salvarOng(Ong ong) {
    final indice = _ongs.indexWhere((item) => item.id == ong.id);
    _ongs = indice >= 0
        ? [for (final item in _ongs) item.id == ong.id ? ong : item]
        : [..._ongs, ong];
    notifyListeners();
  }

  // ONG de que o e-mail faz parte (como administrador ou membro aprovado),
  // ou null. Cada conta pertence a no máximo uma ONG
  Ong? ongDe(String email) {
    for (final ong in _ongs) {
      if (ong.fazParte(email)) return ong;
    }
    return null;
  }

  // Avisos pendentes das ONGs para o e-mail (pedido aprovado, recusado ou
  // remoção), até a pessoa dispensá-los
  List<(Ong, AvisoDaOng)> avisosPara(String email) => [
    for (final ong in _ongs)
      if (ong.avisoPara(email) case final aviso?) (ong, aviso),
  ];

  // ONG em que o e-mail pediu para entrar e ainda aguarda resposta
  Ong? ongPedidaPor(String email) {
    for (final ong in _ongs) {
      if (ong.pediuEntrada(email)) return ong;
    }
    return null;
  }

  // Animais publicados em nome da ONG, do mais novo para o mais antigo.
  // Os publicados em nome próprio por membros da ONG não entram
  List<Animal> animaisDa(Ong ong) =>
      _animais
          .where((animal) => ong.id != null && animal.ongId == ong.id)
          .toList()
        ..sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));

  void adicionarAvistamento(Avistamento avistamento) {
    _avistamentos = [..._avistamentos, avistamento];
    notifyListeners();
  }

  // Animais curtidos que ainda estão ativos (os finalizados saem da lista)
  List<Animal> get animaisCurtidos => _animais
      .where((animal) => _curtidos.contains(animal.chave) && !animal.finalizado)
      .toList(growable: false);

  void atualizarAnimais(List<Animal> animais) {
    _animais = List.unmodifiable(animais);
    _converterCurtidasPorNome();
    notifyListeners();
  }

  // Curtidas gravadas pelo nome do animal (formato anterior) passam a usar a
  // chave do animal de mesmo nome que já tem id, e a lista é regravada
  void _converterCurtidasPorNome() {
    final chaves = {for (final animal in _animais) animal.chave};
    var mudou = false;
    for (final curtida in _curtidos.toList()) {
      if (chaves.contains(curtida)) continue;
      final doMesmoNome = _animais.where((animal) => animal.nome == curtida);
      if (doMesmoNome.isEmpty) continue;
      _curtidos
        ..remove(curtida)
        ..addAll(doMesmoNome.map((animal) => animal.chave));
      mudou = true;
    }
    if (mudou) unawaited(_salvarCurtidos());
  }

  Future<void> _salvarCurtidos() async {
    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setStringList(_chaveCurtidos, _curtidos.toList());
  }

  // Substitui um animal pela versão nova no feed e nos cadastros locais, e
  // regrava os cadastros no aparelho. [chaveAntiga] localiza o animal quando
  // a edição mudou a chave (no animal só local, a chave é o nome)
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

  // Versão mais recente do animal no feed ou nos cadastros locais; útil
  // quando a tela recebeu uma cópia que já foi alterada
  Animal atual(Animal animal) => _animais.firstWhere(
    (item) => item.chave == animal.chave,
    orElse: () => _meusCadastros.firstWhere(
      (item) => item.chave == animal.chave,
      orElse: () => animal,
    ),
  );

  // Cadastros do e-mail: os feitos neste aparelho e os da API registrados
  // nele, sem repetição, do mais novo para o mais antigo. Os publicados em
  // nome de uma ONG ficam só no perfil da ONG
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

  // Troca o telefone de contato em todos os cadastros do e-mail (os mesmos
  // de [cadastrosDe]), para o número novo do perfil valer nos anúncios já
  // publicados. Devolve os animais alterados, para serem gravados na API
  Future<List<Animal>> trocarTelefoneDosCadastros(
    String email,
    String telefone,
  ) async {
    final digitos = telefone.replaceAll(RegExp(r'\D'), '');
    final alterados = [
      for (final animal in cadastrosDe(email))
        if (animal.dono.telefone.replaceAll(RegExp(r'\D'), '') != digitos)
          animal.comTelefoneDoDono(digitos),
    ];
    for (final animal in alterados) {
      await substituirAnimal(animal);
    }
    return alterados;
  }

  // Diz se o e-mail pode alterar o status do animal:
  // - animal de ONG: qualquer pessoa que faça parte dela hoje;
  // - animal com responsável registrado: só esse responsável;
  // - animal sem e-mail registrado: quem o cadastrou neste aparelho
  bool podeMudarStatus(Animal animal, String email) {
    if (animal.ongId != null) return ongDe(email)?.id == animal.ongId;
    if (animal.responsavelEmail.trim().isNotEmpty) {
      return animal.eDoResponsavel(email);
    }
    return email.trim().isNotEmpty &&
        _meusCadastros.any((item) => item.chave == animal.chave);
  }

  // Lê do aparelho as curtidas, os cadastros locais e as notificações
  // dispensadas. Se os cadastros salvos estiverem corrompidos, a lista local
  // é zerada
  Future<void> carregarCurtidos() async {
    final armazenamento = await SharedPreferences.getInstance();
    if (_descartado) return;
    _curtidos
      ..clear()
      ..addAll(armazenamento.getStringList(_chaveCurtidos) ?? const []);
    _alertasDispensados
      ..clear()
      ..addAll(
        armazenamento.getStringList(_chaveAlertasDispensados) ?? const [],
      );
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

  // Põe o animal no topo dos cadastros locais (substituindo o de mesma
  // chave) e salva a lista no aparelho
  Future<void> registrarCadastro(Animal animal) async {
    _meusCadastros.removeWhere((registro) => registro.chave == animal.chave);
    _meusCadastros.insert(0, animal);
    notifyListeners();

    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setString(
      _chaveMeusCadastros,
      jsonEncode(_meusCadastros.map((registro) => registro.toJson()).toList()),
    );
  }

  // Curte ou descurte o animal da chave e salva as curtidas no aparelho
  Future<void> alternarCurtida(String chave) async {
    if (!_curtidos.add(chave)) _curtidos.remove(chave);
    notifyListeners();
    await _salvarCurtidos();
  }

  // Remove a curtida, se existir, e salva as curtidas no aparelho
  Future<void> removerCurtida(String chave) async {
    if (!_curtidos.remove(chave)) return;
    notifyListeners();
    await _salvarCurtidos();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}

// Disponibiliza o [EstadoPataAmiga] para a árvore de widgets e reconstrói
// quem depende dele a cada notificação
class PataAmigaScope extends InheritedNotifier<EstadoPataAmiga> {
  const PataAmigaScope({
    super.key,
    required EstadoPataAmiga notifier,
    required super.child,
  }) : super(notifier: notifier);

  // Lê o estado sem se inscrever nas mudanças (útil no initState e em
  // callbacks). Devolve null quando não há escopo acima
  static EstadoPataAmiga? talvez(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PataAmigaScope>()?.notifier;

  // Lê o estado e reconstrói o widget quando ele mudar, como [of], mas
  // devolve null quando não há escopo acima (telas montadas sozinhas)
  static EstadoPataAmiga? ouvindo(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PataAmigaScope>()?.notifier;

  // Lê o estado e reconstrói o widget sempre que ele mudar
  static EstadoPataAmiga of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PataAmigaScope>();
    assert(scope != null, 'PataAmigaScope não encontrado na árvore.');
    return scope!.notifier!;
  }
}
