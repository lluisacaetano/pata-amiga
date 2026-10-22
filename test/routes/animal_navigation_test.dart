import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart'
    as pi;
import 'package:geolocator/geolocator.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pata_amiga/auth/screens/de_volta_screen.dart';
import 'package:pata_amiga/dados/animais_mock.dart';
import 'package:pata_amiga/dados/bairros_formiga.dart';
import 'package:pata_amiga/dados/racas.dart';
import 'package:pata_amiga/modelos/avistamento.dart';
import 'package:pata_amiga/modelos/camadas_do_mapa.dart';
import 'package:pata_amiga/modelos/filtros_do_feed.dart';
import 'package:pata_amiga/modelos/ong.dart';
import 'package:pata_amiga/modelos/ponto_de_alimentacao.dart';
import 'package:pata_amiga/estado/estado_pata_amiga.dart';
import 'package:pata_amiga/modelos/animal.dart';
import 'package:pata_amiga/provider/usuario_provider.dart';
import 'package:pata_amiga/routes/app_router.dart';
import 'package:pata_amiga/services/alimentacao_service.dart';
import 'package:pata_amiga/services/animal_service.dart';
import 'package:pata_amiga/services/avistamento_service.dart';
import 'package:pata_amiga/services/bairro_service.dart';
import 'package:pata_amiga/services/localizacao_service.dart';
import 'package:pata_amiga/services/ong_service.dart';
import 'package:pata_amiga/telas/cadastrar_ponto.dart';
import 'package:pata_amiga/telas/cadastro_animal.dart';
import 'package:pata_amiga/telas/cadastro_ong.dart';
import 'package:pata_amiga/telas/lista_ongs.dart';
import 'package:pata_amiga/telas/perfil_ong.dart';
import 'package:pata_amiga/telas/detalhes_animal.dart';
import 'package:pata_amiga/telas/tela_mapa.dart';
import 'package:pata_amiga/telas/feed_adocao.dart';
import 'package:pata_amiga/telas/editar_perfil.dart';
import 'package:pata_amiga/telas/perfil_usuario.dart';
import 'package:pata_amiga/telas/registrar_abastecimento.dart';
import 'package:pata_amiga/telas/registrar_avistamento.dart';
import 'package:pata_amiga/widgets/acoes_do_registro.dart';
import 'package:pata_amiga/widgets/avatar_da_ong.dart';
import 'package:pata_amiga/widgets/barra_inferior.dart';
import 'package:pata_amiga/widgets/foto_animal.dart';
import 'package:pata_amiga/widgets/mapa_de_local.dart';
import 'package:pata_amiga/widgets/mascaras.dart';
import 'package:pata_amiga/widgets/painel_de_filtros.dart';
import 'package:pata_amiga/widgets/sino_de_notificacoes.dart';

// Galeria que devolve uma foto, para o cadastro de animal, em que a foto é
// obrigatória
class _GaleriaComUmaFoto extends ImagePickerPlatform {
  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async => [XFile('/tmp/animal-de-teste.jpg')];

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile('/tmp/animal-de-teste.jpg');
}

class _GaleriaVazia extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => null;
}

// API falsa: o feed lê e grava aqui, sem depender do servidor no ar
class _ApiFalsa extends AnimalService {
  _ApiFalsa(List<Animal> animais, {this.fora = false}) : animais = [...animais];

  final List<Animal> animais;
  final bool fora;

  @override
  Future<List<Animal>> buscarAnimais() async {
    if (fora) throw Exception('sem conexão');
    return [...animais];
  }

  @override
  Future<void> criarAnimal(Animal animal) async {
    if (fora) throw Exception('sem conexão');
    animais.add(animal);
  }

  final statusGravados = <StatusAnimal>[];
  final editados = <Animal>[];

  @override
  Future<void> atualizarAnimal(Animal animal) async {
    if (fora) throw Exception('sem conexão');
    editados.add(animal);
  }

  @override
  Future<void> atualizarStatus(Animal animal, StatusAnimal novo) async {
    if (fora) throw Exception('sem conexão');
    statusGravados.add(novo);
  }
}

// Serviço de avistamentos falso: guarda na memória e devolve com id
class _AvistamentosFalsos extends AvistamentoService {
  _AvistamentosFalsos({this.fora = false});

  final bool fora;
  final gravados = <Avistamento>[];

  @override
  Future<List<Avistamento>> buscarTodos() async => [...gravados];

  @override
  Future<Avistamento> registrar(Avistamento avistamento) async {
    if (fora) throw Exception('sem conexão');
    final comId = Avistamento.fromJson({
      ...avistamento.toJson(),
      'id': gravados.length + 1,
    });
    gravados.add(comId);
    return comId;
  }
}

// Serviço de alimentação falso: guarda na memória e devolve com id
class _AlimentacaoFalsa extends AlimentacaoService {
  final pontos = <PontoDeAlimentacao>[];
  final abastecimentos = <Abastecimento>[];

  @override
  Future<PontoDeAlimentacao> cadastrarPonto(PontoDeAlimentacao ponto) async {
    final comId = PontoDeAlimentacao.fromJson({
      ...ponto.toJson(),
      'id': pontos.length + 1,
    });
    pontos.add(comId);
    return comId;
  }

  @override
  Future<Abastecimento> registrarAbastecimento(Abastecimento item) async {
    final comId = Abastecimento.fromJson({
      ...item.toJson(),
      'id': abastecimentos.length + 1,
    });
    abastecimentos.add(comId);
    return comId;
  }
}

// Serviço de ONGs falso: guarda na memória e dá o id na criação
class _OngsFalsas extends OngService {
  _OngsFalsas([List<Ong> ongs = const []]) : ongs = [...ongs];

  final List<Ong> ongs;
  final salvas = <Ong>[];

  @override
  Future<List<Ong>> buscarOngs() async => [...ongs];

  @override
  Future<Ong> buscarOng(int id) async => ongs.firstWhere((ong) => ong.id == id);

  @override
  Future<Ong> salvarOng(Ong ong) async {
    final salva = Ong.fromJson({
      ...ong.toJson(),
      'id': ong.id ?? ongs.length + 1,
    });
    salvas.add(salva);
    ongs
      ..removeWhere((item) => item.id == salva.id)
      ..add(salva);
    return salva;
  }
}

// Onde a pessoa "está", sem GPS de verdade
class _OndeEstou extends LocalizacaoService {
  _OndeEstou(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  Future<({double latitude, double longitude})> posicaoAtual() async =>
      (latitude: latitude, longitude: longitude);
}

// Faz o papel do formulário de cadastro: volta na hora com o animal pronto
class _CadastroPronto extends StatefulWidget {
  const _CadastroPronto(this.animal);

  final Animal animal;

  @override
  State<_CadastroPronto> createState() => _CadastroProntoState();
}

class _CadastroProntoState extends State<_CadastroPronto> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Navigator.pop(context, widget.animal),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

// GPS e endereço falsos, os mesmos do teste de localização: o aparelho
// "está" na Praça Olegário Maciel, no Centro de Formiga
final _naPraca = Position(
  latitude: -20.4642,
  longitude: -45.4267,
  timestamp: DateTime(2026, 10, 19),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class _GpsFalso extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => _naPraca;
}

// O ponto que o serviço devolve para uma rua digitada, diferente da praça
const _latDaRua = -20.4697811;
const _lonDaRua = -45.4216775;

class _EnderecoFalso extends pi.Geocoding with MockPlatformInterfaceMixin {
  _EnderecoFalso(this.bairro, {this.achaRua = true})
    : super.implementation(pi.GeocodingCreationParams());

  final String bairro;
  final bool achaRua;
  static String? ultimoEnderecoBuscado;

  @override
  Future<List<pi.Location>> locationFromAddress(
    String address, {
    Locale? locale,
  }) async {
    ultimoEnderecoBuscado = address;
    if (!achaRua) return [];
    return [
      pi.Location(
        latitude: _latDaRua,
        longitude: _lonDaRua,
        timestamp: DateTime(2026, 10, 19),
      ),
    ];
  }

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    Locale? locale,
  }) async => [
    Placemark(
      thoroughfare: 'Praça Olegário Maciel',
      subThoroughfare: '155',
      subLocality: bairro,
      locality: 'Formiga',
    ),
  ];
}

class _FabricaFalsa extends pi.GeocodingPlatformFactory
    with MockPlatformInterfaceMixin {
  _FabricaFalsa({this.bairro = 'Centro', this.achaRua = true});

  final String bairro;
  final bool achaRua;

  @override
  pi.Geocoding createGeocoding(pi.GeocodingCreationParams params) =>
      _EnderecoFalso(bairro, achaRua: achaRua);
}

void main() {
  testWidgets('feed envia e recebe o animal pela tela de detalhes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final animaisParaAdocao =
        animaisMock
            .where((animal) => animal.tipo == TipoRegistro.adocao)
            .toList()
          ..sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));
    final animalSelecionado = animaisParaAdocao.first;
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);

    await tester.pumpWidget(
      PataAmigaScope(
        notifier: estado,
        child: MaterialApp(
          initialRoute: AppRoutes.feed,
          routes: {
            ...AppRoutesConfig.routes,
            AppRoutes.feed: (_) => FeedAdocao(api: _ApiFalsa(animaisMock)),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cartaoSelecionado = find.text(animalSelecionado.nome.toUpperCase());
    await tester.ensureVisible(cartaoSelecionado);
    await tester.pumpAndSettle();
    await tester.tap(cartaoSelecionado);
    await tester.pumpAndSettle();

    expect(find.text('DETALHES'), findsOneWidget);
    await tester.tap(find.byTooltip('Adicionar aos curtidos'));
    await tester.pump();
    expect(estado.estaCurtido(animalSelecionado.nome), isTrue);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Você voltou dos detalhes de ${animalSelecionado.nome}.'),
      findsOneWidget,
    );
    expect(find.text(animalSelecionado.nome.toUpperCase()), findsOneWidget);

    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Reportar'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    await tester.tap(find.byTooltip('Cadastrar animal'));
    await tester.pumpAndSettle();
    expect(find.text('CADASTRAR ANIMAL'), findsOneWidget);
  });

  // Monta o app já no perfil, numa tela do tamanho de um celular
  Future<void> abrirPerfil(
    WidgetTester tester, {
    required EstadoPataAmiga estado,
    required UsuarioProvider usuario,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: usuario,
        child: PataAmigaScope(
          notifier: estado,
          child: MaterialApp(
            initialRoute: AppRoutes.perfilUsuario,
            routes: AppRoutesConfig.routes,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('perfil abre nos curtidos, remove e desfaz a remoção', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    final animal = animaisMock.first;
    estado.atualizarAnimais([animal]);
    await estado.alternarCurtida(animal.nome);

    await abrirPerfil(tester, estado: estado, usuario: UsuarioProvider());

    expect(find.text(animal.nome.toUpperCase()), findsOneWidget);

    await tester.tap(find.byTooltip('Remover dos curtidos'));
    await tester.pumpAndSettle();
    expect(estado.estaCurtido(animal.nome), isFalse);
    expect(find.text('Nenhum animal curtido ainda'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(estado.estaCurtido(animal.nome), isTrue);
    expect(find.text(animal.nome.toUpperCase()), findsOneWidget);
  });

  testWidgets('curtido adotado sai da lista do perfil', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    final adotado = Animal.fromJson({
      ...animaisMock.first.toJson(),
      'status': StatusAnimal.adotado.name,
    });
    estado.atualizarAnimais([adotado]);
    await estado.alternarCurtida(adotado.nome);

    await abrirPerfil(tester, estado: estado, usuario: UsuarioProvider());

    expect(find.text('Nenhum animal curtido ainda'), findsOneWidget);
  });

  testWidgets('meus registros lista o animal registrado no aparelho', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    final animal = animaisMock.first;
    await estado.registrarCadastro(animal);

    await abrirPerfil(tester, estado: estado, usuario: UsuarioProvider());
    await tester.tap(find.text('Meus registros'));
    await tester.pumpAndSettle();

    expect(find.text(animal.nome.toUpperCase()), findsOneWidget);
    expect(find.text('Publicado há 2 dias'), findsOneWidget);
  });

  testWidgets('editar perfil só salva com mudança e volta ao perfil', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ImagePickerPlatform.instance = _GaleriaVazia();
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    final usuario = UsuarioProvider();
    await usuario.registrarUsuario(
      nome: 'Luisa',
      email: 'luisa@pata.com',
      telefone: '(37) 99999-0000',
    );

    await abrirPerfil(tester, estado: estado, usuario: usuario);
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    expect(find.text('EDITAR PERFIL'), findsOneWidget);

    FilledButton botaoSalvar() =>
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botaoSalvar().onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).first, 'Luisa Araujo');
    await tester.pump();
    expect(botaoSalvar().onPressed, isNotNull);

    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(usuario.usuario.nome, 'Luisa Araujo');
    expect(find.text('MEU PERFIL'), findsOneWidget);
    expect(find.text('Alterações salvas.'), findsOneWidget);
  });

  testWidgets('editar perfil não salva com o nome vazio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    final usuario = UsuarioProvider();
    await usuario.registrarUsuario(
      nome: 'Luisa',
      email: 'luisa@pata.com',
      telefone: '',
    );

    await abrirPerfil(tester, estado: estado, usuario: usuario);
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(usuario.usuario.nome, 'Luisa');
  });

  testWidgets('recepção cumprimenta pelo primeiro nome e segue sozinha', (
    tester,
  ) async {
    var terminou = 0;
    SharedPreferences.setMockInitialValues({});
    final usuario = UsuarioProvider();
    await usuario.registrarUsuario(
      nome: 'Luisa Caetano',
      email: 'luisa@pata.com',
      telefone: '',
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: usuario,
        child: MaterialApp(home: DeVoltaScreen(aoTerminar: () => terminou++)),
      ),
    );

    expect(find.text('Que bom te ver de volta, Luisa!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(terminou, 0);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(terminou, 1);
  });

  testWidgets('um toque pula a recepção uma vez só', (tester) async {
    var terminou = 0;
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UsuarioProvider(),
        child: MaterialApp(home: DeVoltaScreen(aoTerminar: () => terminou++)),
      ),
    );

    expect(find.text('Que bom te ver de volta!'), findsOneWidget);
    await tester.tap(find.byType(DeVoltaScreen));
    expect(terminou, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(terminou, 1);
  });

  // US 05: o animal cadastrado aparece na listagem logo depois de salvo,
  // mesmo vindo de outra aba e com uma busca digitada
  Future<void> cadastrarPeloFeed(
    WidgetTester tester, {
    required _ApiFalsa api,
    required Animal novo,
  }) async {
    SharedPreferences.setMockInitialValues({});
    // Mais largo que um celular: a fonte dos testes é mais larga que a do
    // aparelho, e as linhas do card do feed não encolhem
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);

    await tester.pumpWidget(
      PataAmigaScope(
        notifier: estado,
        child: MaterialApp(
          home: FeedAdocao(api: api),
          routes: {AppRoutes.registerAnimal: (_) => _CadastroPronto(novo)},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Está na aba Adoção, com uma busca que não bate com o animal novo
    await tester.enterText(find.byType(TextField).first, 'thor');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cadastrar animal'));
    await tester.pumpAndSettle();
  }

  Animal perdidoNovo() => Animal.fromJson({
    ...animaisMock.first.toJson(),
    'nome': 'Pipoca',
    'tipo': TipoRegistro.perdido.name,
    'publicadoEm': DateTime.now().toIso8601String(),
  });

  testWidgets('animal salvo na API aparece na hora, na aba do tipo dele', (
    tester,
  ) async {
    final api = _ApiFalsa(animaisMock);
    await cadastrarPeloFeed(tester, api: api, novo: perdidoNovo());

    expect(api.animais.any((animal) => animal.nome == 'Pipoca'), isTrue);
    expect(find.text('PIPOCA'), findsOneWidget);
    expect(find.text('Pipoca foi salvo na API.'), findsOneWidget);
  });

  testWidgets('sem API, o animal fica no aparelho e aparece na hora', (
    tester,
  ) async {
    final api = _ApiFalsa(animaisMock, fora: true);
    await cadastrarPeloFeed(tester, api: api, novo: perdidoNovo());

    expect(find.text('PIPOCA'), findsOneWidget);
    expect(
      find.text(
        'Pipoca foi adicionado só neste aparelho. '
        'Não foi possível enviar à API.',
      ),
      findsOneWidget,
    );
  });

  // A barra inferior faz o mesmo em todas as telas
  Widget appComBarra() => MaterialApp(
    home: const Scaffold(
      body: Text('FEED FALSO'),
      bottomNavigationBar: BarraInferior(),
    ),
    routes: {
      AppRoutes.mapa: (_) => const Scaffold(
        body: Text('MAPA FALSO'),
        bottomNavigationBar: BarraInferior(atual: 1),
      ),
      AppRoutes.perfilUsuario: (_) => const Scaffold(
        body: Text('PERFIL FALSO'),
        bottomNavigationBar: BarraInferior(atual: 3),
      ),
    },
  );

  testWidgets('Mapa abre o mapa a partir de qualquer tela da barra', (
    tester,
  ) async {
    await tester.pumpWidget(appComBarra());
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('PERFIL FALSO'), findsOneWidget);

    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(find.text('MAPA FALSO'), findsOneWidget);
    expect(find.text('Esta tela entra em uma próxima sprint.'), findsNothing);
  });

  testWidgets('Início volta ao feed mesmo com outras telas no caminho', (
    tester,
  ) async {
    await tester.pumpWidget(appComBarra());
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    expect(find.text('FEED FALSO'), findsOneWidget);
    expect(find.text('PERFIL FALSO'), findsNothing);
  });

  // US 20: o cadastro de animal lê quem está logado direto do estado
  Future<void> abrirCadastro(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    // Os campos de contato aparecem depois de escolher o tipo
    await tester.tap(find.text('Perdido'));
    await tester.pumpAndSettle();
  }

  testWidgets('cadastro de animal já vem com o contato de quem está logado', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final usuario = UsuarioProvider();
    await usuario.registrarUsuario(
      nome: 'Luisa Caetano',
      email: 'luisa@pata.com',
      telefone: '(37) 99999-0000',
    );

    await abrirCadastro(
      tester,
      ChangeNotifierProvider.value(
        value: usuario,
        child: const MaterialApp(home: CadastroAnimal()),
      ),
    );

    expect(find.text('Luisa Caetano'), findsOneWidget);
    expect(find.text('(37) 99999-0000'), findsOneWidget);
  });

  testWidgets('sem ninguém logado, o contato do cadastro começa vazio', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await abrirCadastro(tester, const MaterialApp(home: CadastroAnimal()));

    expect(find.text('Luisa Caetano'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  final campoDoBairro = find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        w.decoration?.hintText == 'Digite para buscar o bairro',
  );

  // Digita um pedaço do nome e toca na opção da lista
  Future<void> escolherBairro(WidgetTester tester, String opcao) async {
    await tester.tap(campoDoBairro);
    await tester.pumpAndSettle();
    if (opcao != 'Outro bairro') {
      await tester.enterText(campoDoBairro, opcao.substring(0, 4));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(opcao).last);
    await tester.pumpAndSettle();
  }

  // Fundação do mapa: o cadastro guarda de onde o animal foi registrado
  Future<Animal?> cadastrarPerdido(
    WidgetTester tester, {
    bool usarMira = true,
    String bairroDoGps = 'Centro',
    String? ruaDigitada,
    String? bairroDigitado,
    String? outroBairroDigitado,
    bool enviar = true,
    bool achaRua = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    GeolocatorPlatform.instance = _GpsFalso();
    pi.GeocodingPlatformFactory.instance = _FabricaFalsa(
      bairro: bairroDoGps,
      achaRua: achaRua,
    );
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final usuario = UsuarioProvider();
    await usuario.registrarUsuario(
      nome: 'Luisa',
      email: 'luisa@pata.com',
      telefone: '(37) 99999-0000',
    );

    Animal? devolvido;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: usuario,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                devolvido = await Navigator.push<Animal>(
                  context,
                  MaterialPageRoute(builder: (_) => const CadastroAnimal()),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // A foto é obrigatória: escolhe uma na galeria falsa
    ImagePickerPlatform.instance = _GaleriaComUmaFoto();
    await tester.tap(find.byType(FotoAnimal).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perdido'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, 'Escolher').first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cachorro').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, 'Escolher').first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pequeno').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '2 anos'), '3 anos');
    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Onde e quando sumiu, coleira, se atende pelo nome',
      ),
      'Sumiu perto da praça.',
    );

    if (usarMira) {
      await tester.tap(find.byTooltip('Usar minha localização'));
      await tester.pumpAndSettle();
      expect(find.text('Praça Olegário Maciel, 155'), findsOneWidget);
    }
    final rua = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration?.hintText == 'Informe a rua e o número',
    );
    if (ruaDigitada != null) await tester.enterText(rua, ruaDigitada);
    if (bairroDigitado != null) await escolherBairro(tester, bairroDigitado);
    if (outroBairroDigitado != null) {
      await escolherBairro(tester, 'Outro bairro');
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == 'Informe o nome do bairro',
        ),
        outroBairroDigitado,
      );
    }

    if (!enviar) return null;
    await tester.tap(find.widgetWithText(FilledButton, 'Cadastrar'));
    await tester.pumpAndSettle();
    return devolvido;
  }

  testWidgets(
    'com a mira, o animal sai com rua, bairro, Formiga e a coordenada',
    (tester) async {
      final animal = await cadastrarPerdido(tester);

      expect(animal, isNotNull);
      expect(animal!.rua, 'Praça Olegário Maciel, 155');
      expect(animal.bairro, 'Centro');
      expect(animal.cidade, 'Formiga');
      expect(animal.latitude, -20.4642);
      expect(animal.longitude, -45.4267);
    },
  );

  testWidgets('rua trocada depois da mira usa o ponto da rua nova', (
    tester,
  ) async {
    final animal = await cadastrarPerdido(
      tester,
      ruaDigitada: 'Rua do Expedicionário',
    );

    expect(animal!.rua, 'Rua do Expedicionário');
    expect(animal.latitude, _latDaRua);
    expect(animal.longitude, _lonDaRua);
  });

  testWidgets('sem a mira, o animal é fixado num ponto da rua digitada', (
    tester,
  ) async {
    final animal = await cadastrarPerdido(
      tester,
      usarMira: false,
      // O ponto que o serviço devolve fica mesmo no Quartéis
      bairroDoGps: 'Quartéis',
      ruaDigitada: 'Rua do Expedicionário',
      bairroDigitado: 'Quartéis',
    );

    expect(
      _EnderecoFalso.ultimoEnderecoBuscado,
      'Rua do Expedicionário, Quartéis, Formiga, MG, Brasil',
    );
    expect(animal!.latitude, _latDaRua);
    expect(animal.longitude, _lonDaRua);
  });

  testWidgets('ponto da rua fora do bairro escolhido não vai para o mapa', (
    tester,
  ) async {
    // Rua escrita errado: o serviço devolve um ponto no Centro, mas o bairro
    // escolhido é o Quartéis
    final animal = await cadastrarPerdido(
      tester,
      usarMira: false,
      bairroDoGps: 'Centro',
      ruaDigitada: 'Rua do Expedicionaro',
      bairroDigitado: 'Quartéis',
    );

    expect(animal, isNotNull);
    expect(animal!.rua, 'Rua do Expedicionaro');
    expect(animal.temPonto, isFalse);
  });

  testWidgets('se a rua não for encontrada, o cadastro sai sem ponto', (
    tester,
  ) async {
    final animal = await cadastrarPerdido(
      tester,
      usarMira: false,
      ruaDigitada: 'Rua que não existe',
      bairroDigitado: 'Quartéis',
      achaRua: false,
    );

    expect(animal, isNotNull);
    expect(animal!.temPonto, isFalse);
  });

  testWidgets('a mira já escolhe o bairro da lista', (tester) async {
    final animal = await cadastrarPerdido(tester);

    expect(animal!.bairro, 'Centro');
  });

  testWidgets('bairro do GPS fora da lista vai para Outro com o nome dele', (
    tester,
  ) async {
    final animal = await cadastrarPerdido(tester, bairroDoGps: 'Bairro Novo');

    expect(animal!.bairro, 'Bairro Novo');
    expect(animal.temPonto, isTrue);
  });

  testWidgets('escolher o bairro que o GPS não achou mantém a coordenada', (
    tester,
  ) async {
    final animal = await cadastrarPerdido(
      tester,
      bairroDoGps: '',
      bairroDigitado: 'Rosário',
    );

    expect(animal!.bairro, 'Rosário');
    expect(animal.temPonto, isTrue);
  });

  testWidgets('Outro bairro abre um campo e salva o que foi escrito', (
    tester,
  ) async {
    final animal = await cadastrarPerdido(
      tester,
      usarMira: false,
      ruaDigitada: 'Rua Pedro Mendes, 40',
      outroBairroDigitado: 'Vila Nova',
    );

    expect(animal!.bairro, 'Vila Nova');
    expect(animal.cidade, 'Formiga');
  });

  testWidgets('bairro que não está na lista ainda mostra Outro bairro', (
    tester,
  ) async {
    await cadastrarPerdido(tester, usarMira: false, enviar: false);
    await tester.tap(campoDoBairro);
    await tester.enterText(campoDoBairro, 'xyzw');
    await tester.pumpAndSettle();

    expect(find.text('Outro bairro'), findsOneWidget);
    await tester.tap(find.text('Outro bairro'));
    await tester.pumpAndSettle();
    expect(find.text('QUAL É O BAIRRO?'), findsOneWidget);
  });

  testWidgets('sem rua ou sem bairro o cadastro não sai', (tester) async {
    final semBairro = await cadastrarPerdido(
      tester,
      usarMira: false,
      ruaDigitada: 'Rua Pedro Mendes, 40',
    );
    expect(semBairro, isNull);
    expect(find.text('CADASTRAR ANIMAL'), findsOneWidget);
  });

  // A lista de bairros, testada como lógica pura
  group('bairros de Formiga', () {
    test('a busca ignora maiúsculas e acentos', () {
      expect(filtrarBairros('agua'), contains('Água Vermelha'));
      expect(filtrarBairros('ROSARIO'), contains('Rosário'));
    });

    test('a busca filtra pelo pedaço digitado', () {
      final achados = filtrarBairros('santa');
      expect(achados, contains('Santa Luzia'));
      expect(achados, isNot(contains('Centro')));
    });

    test('o nome do GPS acha o bairro com a grafia da lista', () {
      expect(bairroDaLista('centro'), 'Centro');
      expect(bairroDaLista('Agua Vermelha'), 'Água Vermelha');
      expect(bairroDaLista('Bairro Inventado'), isNull);
    });

    test('cidade no lugar do bairro conta como bairro desconhecido', () {
      expect(bairroDoServico('Formiga', 'Formiga'), '');
      expect(bairroDoServico('Formiga', null), '');
      expect(bairroDoServico('Centro', 'Formiga'), 'Centro');
      expect(bairroDoServico(null, 'Formiga'), '');
    });

    test('a lista está em ordem alfabética e sem repetição', () {
      expect(bairrosDeFormiga.toSet().length, bairrosDeFormiga.length);
      expect(bairrosDeFormiga, contains('Ponte Vila'));
      expect(bairrosDeFormiga, contains("Distrito Empresarial D'Carlos"));
      expect(bairrosDeFormiga, isNot(contains('Pontevila')));
    });
  });

  // A rua aparece na ficha de perdido e resgate, nunca na de adoção
  Future<void> abrirFicha(WidgetTester tester, Animal animal) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    await tester.pumpWidget(
      PataAmigaScope(
        notifier: estado,
        child: MaterialApp(home: DetalhesAnimal(animal: animal)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Animal comRua(TipoRegistro tipo) => Animal.fromJson({
    ...animaisMock.first.toJson(),
    'tipo': tipo.name,
    'rua': 'Praça Olegário Maciel, 155',
    'bairro': 'Centro',
    'cidade': 'Formiga',
  });

  testWidgets('a ficha de perdido mostra a rua', (tester) async {
    await abrirFicha(tester, comRua(TipoRegistro.perdido));
    expect(find.text('Praça Olegário Maciel, 155'), findsOneWidget);
    expect(find.text('Centro, Formiga'), findsOneWidget);
  });

  testWidgets('a ficha de adoção não mostra a rua', (tester) async {
    await abrirFicha(tester, comRua(TipoRegistro.adocao));
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('Formiga'), findsOneWidget);
    expect(find.textContaining('Olegário'), findsNothing);
  });

  group('telefone formatado', () {
    test('telefone sem máscara, como vem da API, sai formatado', () {
      expect(formatarTelefone('13999991111'), '(13) 99999-1111');
      expect(formatarTelefone('3732221234'), '(37) 3222-1234');
    });

    test('o 55 do país sai, e o que já está formatado não muda', () {
      expect(formatarTelefone('5537999990000'), '(37) 99999-0000');
      expect(formatarTelefone('(37) 99999-0000'), '(37) 99999-0000');
    });
  });

  testWidgets('a ficha mostra nome e telefone formatado do responsável', (
    tester,
  ) async {
    await abrirFicha(
      tester,
      Animal.fromJson({
        ...animaisMock.first.toJson(),
        'dono': {'nome': 'João', 'telefone': '13999991111'},
      }),
    );

    expect(find.text('NOME'), findsOneWidget);
    expect(find.text('João'), findsOneWidget);
    expect(find.text('TELEFONE'), findsOneWidget);
    expect(find.text('(13) 99999-1111'), findsOneWidget);
    expect(find.text('13999991111'), findsNothing);
  });

  test('todo animal de exemplo da API tem endereço completo em Formiga', () {
    final banco = jsonDecode(File('api/db.json').readAsStringSync()) as Map;
    final animais = (banco['animais'] as List)
        .map((item) => Animal.fromJson(item as Map<String, dynamic>))
        .toList();

    expect(animais, isNotEmpty);
    for (final animal in animais) {
      expect(animal.rua, isNotEmpty, reason: animal.nome);
      expect(bairrosDeFormiga, contains(animal.bairro), reason: animal.nome);
      expect(animal.cidade, 'Formiga', reason: animal.nome);
      // A caixa que cobre a área urbana de Formiga
      expect(animal.latitude, inInclusiveRange(-20.50, -20.43));
      expect(animal.longitude, inInclusiveRange(-45.47, -45.39));
    }
  });

  // US 08: o mapa mostra perdidos e resgates com localização
  Animal noMapa(String nome, TipoRegistro tipo, {bool comPonto = true}) =>
      Animal.fromJson({
        ...animaisMock.first.toJson(),
        'nome': nome,
        'tipo': tipo.name,
        'rua': 'Rua do Expedicionário',
        'bairro': 'Quartéis',
        'cidade': 'Formiga',
        'latitude': comPonto ? -20.4697 : null,
        'longitude': comPonto ? -45.4216 : null,
      });

  group('camadas do mapa', () {
    final perdido = noMapa('Nina', TipoRegistro.perdido);
    final resgate = noMapa('Mel', TipoRegistro.resgate);
    final adocao = noMapa('Thor', TipoRegistro.adocao);
    final semPonto = noMapa('Bidu', TipoRegistro.perdido, comPonto: false);
    final todos = [perdido, resgate, adocao, semPonto];

    test('adoção nunca vai para o mapa', () {
      expect(
        animaisNoMapa(todos, TipoRegistro.values.toSet()),
        isNot(contains(adocao)),
      );
    });

    test('animal sem coordenada fica fora do mapa', () {
      expect(
        animaisNoMapa(todos, camadasDoMapa.toSet()),
        isNot(contains(semPonto)),
      );
    });

    test('só aparecem as camadas ligadas', () {
      expect(animaisNoMapa(todos, {TipoRegistro.perdido}), [perdido]);
      expect(animaisNoMapa(todos, {TipoRegistro.resgate}), [resgate]);
      expect(animaisNoMapa(todos, {}), isEmpty);
    });
  });

  Future<void> abrirMapa(WidgetTester tester, List<Animal> animais) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    estado.atualizarAnimais(animais);
    await tester.pumpWidget(
      PataAmigaScope(
        notifier: estado,
        child: MaterialApp(
          home: const PaginaMapa(comMapaDeFundo: false),
          routes: {
            AppRoutes.details: AppRoutesConfig.routes[AppRoutes.details]!,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('o mapa mostra perdidos e resgates e desliga cada camada', (
    tester,
  ) async {
    await abrirMapa(tester, [
      noMapa('Nina', TipoRegistro.perdido),
      noMapa('Mel', TipoRegistro.resgate),
      noMapa('Thor', TipoRegistro.adocao),
    ]);

    expect(find.bySemanticsLabel('Nina'), findsOneWidget);
    expect(find.bySemanticsLabel('Mel'), findsOneWidget);
    expect(find.bySemanticsLabel('Thor'), findsNothing);

    await tester.tap(find.text('Perdidos'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Nina'), findsNothing);
    expect(find.bySemanticsLabel('Mel'), findsOneWidget);

    await tester.tap(find.text('Resgate'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Mel'), findsNothing);
    await tester.tap(find.text('Alimentação'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ligue uma camada do filtro para ver os pontos no mapa.'),
      findsOneWidget,
    );
  });

  testWidgets('tocar no pino mostra foto, nome, lugar e leva à ficha', (
    tester,
  ) async {
    await abrirMapa(tester, [noMapa('Nina', TipoRegistro.perdido)]);

    await tester.tap(find.bySemanticsLabel('Nina'));
    await tester.pumpAndSettle();
    expect(find.text('NINA'), findsOneWidget);
    expect(find.text('Rua do Expedicionário, Quartéis'), findsOneWidget);
    expect(find.byType(FotoAnimal), findsOneWidget);

    await tester.tap(find.text('Ver ficha completa'));
    await tester.pumpAndSettle();
    expect(find.text('DETALHES'), findsOneWidget);
  });

  // US 12: registro de avistamento
  Avistamento visto(
    String animal,
    DateTime data, {
    double latitude = -20.47,
    DateTime? registradoEm,
    String bairro = 'Quartéis',
  }) => Avistamento(
    animal: animal,
    data: data,
    latitude: latitude,
    longitude: -45.42,
    rua: 'Rua do Expedicionário',
    bairro: bairro,
    registradoEm: registradoEm ?? data,
  );

  group('avistamentos', () {
    final simba = Animal.fromJson({
      ...animaisMock.first.toJson(),
      'id': 4,
      'nome': 'Simba',
      'tipo': 'perdido',
    });

    test('o avistamento vai e volta da API sem perder nada', () {
      final original = visto('4', DateTime(2026, 10, 18));
      final lido = Avistamento.fromJson(original.toJson());
      expect(lido.animal, '4');
      expect(lido.data, DateTime(2026, 10, 18));
      expect(lido.lugar, 'Rua do Expedicionário, Quartéis');
    });

    test('o último avistamento é o de data mais recente, só do animal', () {
      final todos = [
        visto('4', DateTime(2026, 10, 15), bairro: 'Centro'),
        visto('4', DateTime(2026, 10, 18), bairro: 'Rosário'),
        visto('9', DateTime(2026, 10, 19), bairro: 'Alvorada'),
      ];
      expect(ultimoAvistamento(simba, todos)!.bairro, 'Rosário');
    });

    test('no mesmo dia, vale o que foi registrado por último', () {
      final todos = [
        visto(
          '4',
          DateTime(2026, 10, 18),
          bairro: 'Centro',
          registradoEm: DateTime(2026, 10, 18, 9),
        ),
        visto(
          '4',
          DateTime(2026, 10, 18),
          bairro: 'Rosário',
          registradoEm: DateTime(2026, 10, 18, 15),
        ),
      ];
      expect(ultimoAvistamento(simba, todos)!.bairro, 'Rosário');
    });

    test('a mensagem ao tutor diz quando e onde', () {
      final mensagem = mensagemParaOTutor(
        simba,
        visto('4', DateTime(2026, 10, 19)),
        DateTime(2026, 10, 19, 14),
      );
      expect(
        mensagem,
        'Olá! Vi Simba hoje, perto de Rua do Expedicionário, Quartéis. '
        'Registrei o avistamento no Pata Amiga, com o ponto no mapa.',
      );
    });

    test('no mapa, o perdido aparece no último avistamento', () {
      final semPontoNoCadastro = Animal.fromJson({
        ...simba.toJson(),
        'latitude': null,
        'longitude': null,
      });
      final pinos = pinosDoMapa(
        [semPontoNoCadastro],
        [visto('4', DateTime(2026, 10, 18), latitude: -20.4555)],
        camadasDoMapa.toSet(),
      );
      expect(pinos, hasLength(1));
      expect(pinos.single.latitude, -20.4555);
      expect(pinos.single.ultimo, isNotNull);
    });
  });

  Future<void> abrirFichaComAvistamento(
    WidgetTester tester,
    Animal animal,
    _AvistamentosFalsos servico,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    await tester.pumpWidget(
      PataAmigaScope(
        notifier: estado,
        child: MaterialApp(
          home: DetalhesAnimal(animal: animal),
          routes: {
            AppRoutes.registrarAvistamento: (context) => RegistrarAvistamento(
              animal: ModalRoute.of(context)!.settings.arguments as Animal,
              servico: servico,
            ),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Animal perdidoComPonto() => Animal.fromJson({
    ...animaisMock.first.toJson(),
    'id': 4,
    'nome': 'Simba',
    'tipo': 'perdido',
    'latitude': -20.4750334,
    'longitude': -45.4299570,
  });

  testWidgets('só animal perdido tem o botão de registrar avistamento', (
    tester,
  ) async {
    final servico = _AvistamentosFalsos();
    await abrirFichaComAvistamento(
      tester,
      Animal.fromJson({...animaisMock.first.toJson(), 'tipo': 'adocao'}),
      servico,
    );
    expect(find.text('Registrar avistamento'), findsNothing);

    await abrirFichaComAvistamento(tester, perdidoComPonto(), servico);
    expect(find.text('Registrar avistamento'), findsOneWidget);
    expect(find.textContaining('Ninguém registrou'), findsOneWidget);
  });

  testWidgets('registrar grava o ponto do pino e oferece avisar o tutor', (
    tester,
  ) async {
    final servico = _AvistamentosFalsos();
    await abrirFichaComAvistamento(tester, perdidoComPonto(), servico);

    await tester.tap(find.text('Registrar avistamento'));
    await tester.pumpAndSettle();
    expect(find.text('REGISTRAR AVISTAMENTO'), findsOneWidget);
    expect(find.textContaining('Hoje,'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Registrar avistamento'),
    );
    await tester.pumpAndSettle();

    // Sem arrastar o mapa, o pino fica onde o animal foi cadastrado
    expect(servico.gravados, hasLength(1));
    expect(servico.gravados.single.animal, '4');
    expect(servico.gravados.single.latitude, -20.4750334);
    expect(find.text('Avistamento registrado'), findsOneWidget);
    expect(find.text('Avisar o tutor pelo WhatsApp'), findsOneWidget);

    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();
    expect(find.text('Visto hoje'), findsOneWidget);
  });

  testWidgets('sem conexão, o registro avisa e a tela continua aberta', (
    tester,
  ) async {
    final servico = _AvistamentosFalsos(fora: true);
    await abrirFichaComAvistamento(tester, perdidoComPonto(), servico);

    await tester.tap(find.text('Registrar avistamento'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Registrar avistamento'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível registrar agora. Tente de novo.'),
      findsOneWidget,
    );
    expect(find.text('REGISTRAR AVISTAMENTO'), findsOneWidget);
  });

  testWidgets('escrever o endereço leva o pino até a rua buscada', (
    tester,
  ) async {
    GeolocatorPlatform.instance = _GpsFalso();
    pi.GeocodingPlatformFactory.instance = _FabricaFalsa(bairro: 'Quartéis');
    final servico = _AvistamentosFalsos();
    await abrirFichaComAvistamento(tester, perdidoComPonto(), servico);
    await tester.tap(find.text('Registrar avistamento'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText == 'Buscar endereço (rua e número)',
      ),
      'Rua do Expedicionário',
    );
    await tester.tap(find.byTooltip('Buscar no mapa'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Registrar avistamento'),
    );
    await tester.pumpAndSettle();

    expect(servico.gravados.single.latitude, _latDaRua);
    expect(servico.gravados.single.longitude, _lonDaRua);
  });

  testWidgets('a mira leva o pino até onde a pessoa está', (tester) async {
    GeolocatorPlatform.instance = _GpsFalso();
    pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
    final servico = _AvistamentosFalsos();
    await abrirFichaComAvistamento(tester, perdidoComPonto(), servico);
    await tester.tap(find.text('Registrar avistamento'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Usar minha localização'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Registrar avistamento'),
    );
    await tester.pumpAndSettle();

    // O GPS falso está na Praça Olegário Maciel
    expect(servico.gravados.single.latitude, -20.4642);
    expect(servico.gravados.single.longitude, -45.4267);
  });

  testWidgets('a prévia do mapa na ficha abre o mapa com o animal em foco', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    final simba = perdidoComPonto();
    estado.atualizarAnimais([simba]);
    await tester.pumpWidget(
      PataAmigaScope(
        notifier: estado,
        child: MaterialApp(
          home: DetalhesAnimal(animal: simba),
          routes: {
            AppRoutes.mapa: (context) => PaginaMapa(
              comMapaDeFundo: false,
              focar: ModalRoute.of(context)!.settings.arguments as Animal,
            ),
            AppRoutes.details: AppRoutesConfig.routes[AppRoutes.details]!,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver no mapa'));
    await tester.pumpAndSettle();
    expect(find.text('MAPA'), findsOneWidget);
    // O resumo do animal já abre sozinho
    expect(find.text('SIMBA'), findsOneWidget);
    expect(find.text('Ver ficha completa'), findsOneWidget);
  });

  testWidgets('ficha de adoção não tem prévia do mapa', (tester) async {
    await abrirFicha(
      tester,
      Animal.fromJson({
        ...animaisMock.first.toJson(),
        'tipo': 'adocao',
        'latitude': -20.46,
        'longitude': -45.42,
      }),
    );
    expect(find.text('Ver no mapa'), findsNothing);
  });

  group('bairro pelo ViaCEP', () {
    test('a busca usa só o nome da rua, sem tipo de via nem número', () {
      expect(
        nomeDaRuaParaBusca('Rua do Expedicionário, 155'),
        'do Expedicionário',
      );
      expect(nomeDaRuaParaBusca('Avenida Inhazinha Pires'), 'Inhazinha Pires');
      expect(
        nomeDaRuaParaBusca('Praça São Vicente Ferrer'),
        'São Vicente Ferrer',
      );
    });

    test('rua de um bairro só devolve esse bairro', () {
      final resultados = [
        {'logradouro': 'Rua do Expedicionário', 'bairro': 'Quartéis'},
      ];
      expect(bairroUnicoDaRua(resultados, 'do Expedicionário'), 'Quartéis');
    });

    test('rua que atravessa dois bairros não escolhe nenhum', () {
      final resultados = [
        {'logradouro': 'Rua Presidente Hermes', 'bairro': 'Vila São Vicente'},
        {'logradouro': 'Rua Presidente Hermes', 'bairro': 'Água Vermelha'},
      ];
      expect(bairroUnicoDaRua(resultados, 'Presidente Hermes'), isNull);
    });

    test('resultado de outra rua com nome parecido não conta', () {
      final resultados = [
        {'logradouro': 'Rua Presidente Hermes', 'bairro': 'Vila São Vicente'},
        {'logradouro': 'Rua Presidente Hermes da Fonseca', 'bairro': 'Centro'},
      ];
      expect(
        bairroUnicoDaRua(resultados, 'Presidente Hermes'),
        'Vila São Vicente',
      );
    });
  });

  // US 14: comedouros e bebedouros
  PontoDeAlimentacao ponto({
    int id = 1,
    TipoDePonto tipo = TipoDePonto.comedouro,
  }) => PontoDeAlimentacao(
    id: id,
    tipo: tipo,
    referencia: 'Perto dos bancos',
    rua: 'Praça Ferreira Pires',
    bairro: 'Centro',
    latitude: -20.4613736,
    longitude: -45.432412,
    cadastradoEm: DateTime(2026, 10, 1),
  );

  group('pontos de alimentação', () {
    final hoje = DateTime(2026, 10, 19, 15);
    Abastecimento em(DateTime data, {int ponto = 1}) =>
        Abastecimento(ponto: ponto, data: data, registradoPor: 'Ana');

    test('a situação segue os dias desde o último abastecimento', () {
      expect(
        situacaoDoPonto(em(DateTime(2026, 10, 17)), hoje),
        SituacaoDoPonto.abastecido,
      );
      expect(
        situacaoDoPonto(em(DateTime(2026, 10, 16)), hoje),
        SituacaoDoPonto.abastecerLogo,
      );
      expect(
        situacaoDoPonto(em(DateTime(2026, 10, 13)), hoje),
        SituacaoDoPonto.abastecerLogo,
      );
      expect(
        situacaoDoPonto(em(DateTime(2026, 10, 12)), hoje),
        SituacaoDoPonto.precisa,
      );
      expect(situacaoDoPonto(null, hoje), SituacaoDoPonto.precisa);
    });

    test('o último abastecimento é o mais recente daquele ponto', () {
      final todos = [
        em(DateTime(2026, 10, 12)),
        em(DateTime(2026, 10, 18)),
        em(DateTime(2026, 10, 19), ponto: 2),
      ];
      expect(ultimoAbastecimento(ponto(), todos)!.data, DateTime(2026, 10, 18));
      expect(ultimoAbastecimento(ponto(id: 9), todos), isNull);
    });

    test('o ponto vai e volta da API sem perder nada', () {
      final lido = PontoDeAlimentacao.fromJson(
        ponto(tipo: TipoDePonto.ambos).toJson(),
      );
      expect(lido.tipo, TipoDePonto.ambos);
      expect(lido.lugar, 'Praça Ferreira Pires, Centro');
    });
  });

  Future<_AlimentacaoFalsa> abrirMapaComPontos(
    WidgetTester tester, {
    required bool logado,
    List<Abastecimento> abastecimentos = const [],
    LocalizacaoService? onde,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    estado.atualizarAlimentacao([ponto()], abastecimentos);
    final usuario = UsuarioProvider();
    if (logado) {
      await usuario.registrarUsuario(
        nome: 'Luisa',
        email: 'luisa@pata.com',
        telefone: '',
      );
    }
    final servico = _AlimentacaoFalsa();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: usuario,
        child: PataAmigaScope(
          notifier: estado,
          child: MaterialApp(
            home: Scaffold(
              body: TelaMapa(
                ligadas: const {},
                mostrarAlimentacao: true,
                comMapaDeFundo: false,
                alimentacao: servico,
              ),
            ),
            routes: {
              AppRoutes.registrarAbastecimento: (context) =>
                  RegistrarAbastecimento(
                    ponto:
                        ModalRoute.of(context)!.settings.arguments
                            as PontoDeAlimentacao,
                    servico: servico,
                    localizacao: onde,
                  ),
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return servico;
  }

  testWidgets('o pino do ponto mostra a situação e o último abastecimento', (
    tester,
  ) async {
    await abrirMapaComPontos(
      tester,
      logado: false,
      abastecimentos: [
        Abastecimento(
          ponto: 1,
          data: DateTime.now().subtract(const Duration(days: 4)),
          registradoPor: 'Carla',
        ),
      ],
    );

    await tester.tap(
      find.bySemanticsLabel('Comedouro Praça Ferreira Pires, Centro'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Comedouro'), findsOneWidget);
    expect(find.text('Abastecer logo'), findsOneWidget);
    expect(
      find.text('Último abastecimento há 4 dias, por Carla'),
      findsOneWidget,
    );
    // Sem login, não registra abastecimento nem cadastra ponto
    expect(find.text('Abasteci hoje'), findsNothing);
    expect(find.byTooltip('Cadastrar ponto de alimentação'), findsNothing);
  });

  Future<void> abrirConfirmacao(WidgetTester tester) async {
    await tester.tap(
      find.bySemanticsLabel('Comedouro Praça Ferreira Pires, Centro'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abasteci hoje'));
    await tester.pumpAndSettle();
    expect(find.text('REGISTRAR ABASTECIMENTO'), findsOneWidget);
  }

  testWidgets('no ponto, o abastecimento vale e só uma vez por dia', (
    tester,
  ) async {
    // A pessoa está exatamente no ponto
    final servico = await abrirMapaComPontos(
      tester,
      logado: true,
      onde: _OndeEstou(-20.4613736, -45.432412),
    );
    expect(find.byTooltip('Cadastrar ponto de alimentação'), findsOneWidget);
    await abrirConfirmacao(tester);

    await tester.tap(find.text('Confirmar abastecimento'));
    await tester.pumpAndSettle();
    expect(servico.abastecimentos.single.ponto, 1);
    expect(servico.abastecimentos.single.email, 'luisa@pata.com');

    // De volta ao resumo: abastecido, e o botão não deixa repetir hoje
    expect(find.text('Abastecido'), findsOneWidget);
    expect(find.text('Último abastecimento hoje, por Luisa'), findsOneWidget);
    expect(find.text('Você já registrou hoje'), findsOneWidget);
  });

  testWidgets('longe do ponto, o abastecimento não vale', (tester) async {
    // Praça Olegário Maciel, a mais de 500 m da Praça Ferreira Pires
    final servico = await abrirMapaComPontos(
      tester,
      logado: true,
      onde: _OndeEstou(-20.4642, -45.4267),
    );
    await abrirConfirmacao(tester);

    await tester.tap(find.text('Confirmar abastecimento'));
    await tester.pumpAndSettle();
    expect(
      find.text('Você precisa estar no ponto para registrar o abastecimento.'),
      findsOneWidget,
    );
    expect(servico.abastecimentos, isEmpty);
  });

  group('verificação do abastecimento', () {
    final agora = DateTime(2026, 10, 19, 15);

    test('a distância entre duas praças do Centro passa de 150 m', () {
      final metros = distanciaEmMetros(
        -20.4613736,
        -45.432412,
        -20.4642,
        -45.4267,
      );
      expect(metros, greaterThan(500));
      expect(metros, lessThan(800));
    });

    MotivoDaRecusa? verificar({
      double latitude = -20.4613736,
      double longitude = -45.432412,
      List<Abastecimento> antes = const [],
    }) => verificarAbastecimento(
      latitudeDoPonto: -20.4613736,
      longitudeDoPonto: -45.432412,
      idDoPonto: 1,
      latitudeDaPessoa: latitude,
      longitudeDaPessoa: longitude,
      email: 'luisa@pata.com',
      abastecimentos: antes,
      agora: agora,
    );

    test('perto do ponto, pela primeira vez no dia, vale', () {
      // Uns 50 m ao norte
      expect(verificar(latitude: -20.4609236), isNull);
    });

    test('a mais de 150 m não vale', () {
      expect(verificar(latitude: -20.4600), MotivoDaRecusa.longeDoPonto);
    });

    test('a mesma pessoa não registra o mesmo ponto duas vezes no dia', () {
      final hojeCedo = Abastecimento(
        ponto: 1,
        data: DateTime(2026, 10, 19, 8),
        email: 'luisa@pata.com',
      );
      final deOutraPessoa = Abastecimento(
        ponto: 1,
        data: DateTime(2026, 10, 19, 8),
        email: 'ana@pata.com',
      );
      final ontem = Abastecimento(
        ponto: 1,
        data: DateTime(2026, 10, 18, 8),
        email: 'luisa@pata.com',
      );
      expect(verificar(antes: [hojeCedo]), MotivoDaRecusa.jaRegistrouHoje);
      expect(verificar(antes: [deOutraPessoa, ontem]), isNull);
    });
  });

  testWidgets('cadastrar ponto grava o ponto e o abastecimento de hoje', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    GeolocatorPlatform.instance = _GpsFalso();
    pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    final servico = _AlimentacaoFalsa();
    await tester.pumpWidget(
      PataAmigaScope(
        notifier: estado,
        child: MaterialApp(home: CadastrarPonto(servico: servico)),
      ),
    );
    await tester.pumpAndSettle();

    // Sem tipo, não cadastra
    await tester.tap(find.text('Cadastrar ponto'));
    await tester.pumpAndSettle();
    expect(
      find.text('Escolha se é comedouro, bebedouro ou os dois.'),
      findsOneWidget,
    );
    expect(servico.pontos, isEmpty);

    await tester.tap(find.text('Os dois'));
    await tester.tap(find.byTooltip('Usar minha localização'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar ponto'));
    await tester.pumpAndSettle();

    expect(servico.pontos.single.tipo, TipoDePonto.ambos);
    expect(servico.pontos.single.latitude, -20.4642);
    expect(servico.abastecimentos.single.ponto, servico.pontos.single.id);
    expect(estado.pontos, hasLength(1));
  });

  // Perto de você: o GPS falso está na Praça Olegário Maciel
  group('perto de você', () {
    final pertinho = PontoDeAlimentacao(
      id: 7,
      tipo: TipoDePonto.bebedouro,
      rua: 'Praça Doutor Olinto Fonseca',
      bairro: 'Centro',
      latitude: -20.4651235,
      longitude: -45.4257303,
      cadastradoEm: DateTime(2026, 10, 1),
    );
    final longe = PontoDeAlimentacao(
      id: 8,
      tipo: TipoDePonto.comedouro,
      latitude: -20.4870323,
      longitude: -45.4361244,
      cadastradoEm: DateTime(2026, 10, 1),
    );

    test('fica só o que está a até 1 km, do mais perto ao mais longe', () {
      final ferreira = ponto();
      final itens = pertoDe(
        -20.4642,
        -45.4267,
        animais: const [],
        pontos: [ferreira, longe, pertinho],
      );
      expect(itens.map((item) => item.ponto), [pertinho, ferreira]);
    });

    test('a distância aparece em metros até 1 km e depois em km', () {
      expect(textoDaDistancia(347), '350 m');
      expect(textoDaDistancia(1240), '1,2 km');
    });
  });

  testWidgets('a mira abre o perto de você com o que está nas camadas', (
    tester,
  ) async {
    GeolocatorPlatform.instance = _GpsFalso();
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    estado.atualizarAlimentacao([ponto()], const []);
    estado.atualizarAnimais([perdidoComPonto()]);
    await tester.pumpWidget(
      PataAmigaScope(
        notifier: estado,
        child: const MaterialApp(home: PaginaMapa(comMapaDeFundo: false)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Minha localização'));
    await tester.pumpAndSettle();
    expect(find.text('Perto de você'), findsOneWidget);
    // O comedouro da Praça Ferreira Pires fica a uns 700 m; o Simba, a mais
    // de 1 km, fica de fora
    expect(find.text('Comedouro'), findsOneWidget);
    expect(find.text('Simba'), findsNothing);

    // Desligar a camada tira o ponto da lista
    await tester.tap(find.text('Alimentação'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nada a até 1 km de você nas camadas ligadas.'),
      findsOneWidget,
    );
  });

  group('status do animal (US 03)', () {
    const email = 'luisa@pata.com';

    Animal meu(TipoRegistro tipo, {String status = 'disponivel'}) =>
        Animal.fromJson({
          ...animaisMock.first.toJson(),
          'id': 7,
          'nome': 'Paçoca',
          'tipo': tipo.name,
          'status': status,
          'responsavelEmail': email,
        });

    test('o desfecho e o rótulo seguem o tipo do registro', () {
      expect(meu(TipoRegistro.adocao).desfecho, StatusAnimal.adotado);
      expect(meu(TipoRegistro.perdido).desfecho, StatusAnimal.encontrado);
      expect(meu(TipoRegistro.resgate).desfecho, StatusAnimal.resgatado);
      expect(meu(TipoRegistro.perdido).rotuloDoStatus, 'procurando');
      expect(meu(TipoRegistro.resgate).rotuloDoStatus, 'precisa de ajuda');
      expect(
        meu(TipoRegistro.perdido, status: 'encontrado').rotuloDoStatus,
        'encontrado',
      );
    });

    test('só o e-mail de quem cadastrou é responsável', () {
      final animal = meu(TipoRegistro.adocao);
      expect(animal.eDoResponsavel('Luisa@Pata.com '), isTrue);
      expect(animal.eDoResponsavel('outra@pata.com'), isFalse);
      expect(animal.eDoResponsavel(''), isFalse);
      expect(animaisMock.first.eDoResponsavel(''), isFalse);
    });

    test('animal com desfecho sai dos pinos do mapa', () {
      final perdido = Animal.fromJson({
        ...meu(TipoRegistro.perdido).toJson(),
        'latitude': -20.4642,
        'longitude': -45.4267,
      });
      final ligadas = camadasDoMapa.toSet();
      expect(pinosDoMapa([perdido], const [], ligadas), hasLength(1));
      expect(
        pinosDoMapa(
          [perdido.comStatus(StatusAnimal.encontrado)],
          const [],
          ligadas,
        ),
        isEmpty,
      );
    });

    Future<_ApiFalsa> abrirMinhaFicha(
      WidgetTester tester,
      EstadoPataAmiga estado,
      Animal animal, {
      String logado = email,
      bool fora = false,
    }) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final usuario = UsuarioProvider();
      await usuario.carregarUsuario(logado);
      final api = _ApiFalsa([animal], fora: fora);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: usuario,
          child: PataAmigaScope(
            notifier: estado,
            child: MaterialApp(
              home: DetalhesAnimal(animal: animal, api: api),
              routes: {
                AppRoutes.registerAnimal: (context) => CadastroAnimal(
                  base: ModalRoute.of(context)!.settings.arguments as Animal?,
                ),
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return api;
    }

    Future<void> tocarNoControle(WidgetTester tester, String texto) async {
      final botao = find.text(texto);
      await tester.ensureVisible(botao);
      await tester.pumpAndSettle();
      await tester.tap(botao);
      await tester.pumpAndSettle();
    }

    testWidgets('só quem cadastrou vê o controle de status', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      await abrirMinhaFicha(
        tester,
        estado,
        meu(TipoRegistro.adocao),
        logado: 'outra@pata.com',
      );
      expect(find.text('Você cadastrou este animal'), findsNothing);
      expect(find.text('Marcar como adotado'), findsNothing);
    });

    testWidgets('cadastro do aparelho sem e-mail também mostra o controle', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final antigo = Animal.fromJson({
        ...meu(TipoRegistro.perdido).toJson(),
        'id': null,
        'responsavelEmail': '',
      });
      await estado.registrarCadastro(antigo);
      await abrirMinhaFicha(tester, estado, antigo);
      expect(find.text('Você cadastrou este animal'), findsOneWidget);

      // Sem estar nos cadastros do aparelho, não
      final deOutro = Animal.fromJson({...antigo.toJson(), 'nome': 'Bolinha'});
      expect(estado.podeMudarStatus(deOutro, email), isFalse);
    });

    test('animal da API no e-mail de quem está logado entra nos cadastros', () {
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final deOutro = Animal.fromJson({
        ...meu(TipoRegistro.adocao).toJson(),
        'id': 8,
        'nome': 'Bolinha',
        'responsavelEmail': 'outra@pata.com',
      });
      estado.atualizarAnimais([meu(TipoRegistro.adocao), deOutro]);
      expect(estado.cadastrosDe(email).map((animal) => animal.nome), [
        'Paçoca',
      ]);
      expect(estado.cadastrosDe('ninguem@pata.com'), isEmpty);
    });

    testWidgets('marcar como adotado confirma, grava e tira do feed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final animal = meu(TipoRegistro.adocao);
      estado.atualizarAnimais([animal]);
      final api = await abrirMinhaFicha(tester, estado, animal);

      expect(find.text('Você cadastrou este animal'), findsOneWidget);
      await tocarNoControle(tester, 'Marcar como adotado');
      expect(find.text('Marcar Paçoca como adotado?'), findsOneWidget);

      // Cancelar não muda nada
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(api.statusGravados, isEmpty);

      await tocarNoControle(tester, 'Marcar como adotado');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(api.statusGravados, [StatusAnimal.adotado]);
      expect(estado.atual(animal).status, StatusAnimal.adotado);
      expect(find.text('Voltar para disponível'), findsOneWidget);
      expect(
        estado.animais.where((item) => !item.finalizado),
        isEmpty,
        reason: 'o feed só mostra quem não tem desfecho',
      );

      // E dá para desfazer
      await tocarNoControle(tester, 'Voltar para disponível');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(estado.atual(animal).status, StatusAnimal.disponivel);
      expect(find.text('Marcar como adotado'), findsOneWidget);
    });

    testWidgets('perdido vira encontrado', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final animal = meu(TipoRegistro.perdido);
      estado.atualizarAnimais([animal]);
      final api = await abrirMinhaFicha(tester, estado, animal);

      await tocarNoControle(tester, 'Marcar como encontrado');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(api.statusGravados, [StatusAnimal.encontrado]);
      expect(find.text('Voltar para procurando'), findsOneWidget);
    });

    testWidgets('sem conexão, o status não muda e avisa', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final animal = meu(TipoRegistro.adocao);
      estado.atualizarAnimais([animal]);
      await abrirMinhaFicha(tester, estado, animal, fora: true);

      await tocarNoControle(tester, 'Marcar como adotado');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Não foi possível mudar agora. Tente de novo.'),
        findsOneWidget,
      );
      expect(estado.atual(animal).status, StatusAnimal.disponivel);
    });

    testWidgets('resgatado oferece publicar para adoção com os dados', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final animal = meu(TipoRegistro.resgate);
      estado.atualizarAnimais([animal]);
      await abrirMinhaFicha(tester, estado, animal);

      await tocarNoControle(tester, 'Marcar como resgatado');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(find.text('Resgate concluído'), findsOneWidget);

      // O botão do painel, que fica por cima do botão do quadro
      await tester.tap(
        find.widgetWithText(FilledButton, 'Publicar para adoção').last,
      );
      await tester.pumpAndSettle();
      expect(find.text('PUBLICAR PARA ADOÇÃO'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Paçoca'), findsOneWidget);
    });

    testWidgets('a oferta pode ser recusada e continua no quadro', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final animal = meu(TipoRegistro.resgate);
      estado.atualizarAnimais([animal]);
      await abrirMinhaFicha(tester, estado, animal);

      await tocarNoControle(tester, 'Marcar como resgatado');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agora não'));
      await tester.pumpAndSettle();
      expect(find.text('Voltar para precisa de ajuda'), findsOneWidget);
      expect(find.text('Publicar para adoção'), findsOneWidget);
    });
  });

  group('meus registros (US 09)', () {
    const email = 'luisa@pata.com';

    Animal registro(
      String nome,
      TipoRegistro tipo, {
      int? id,
      String status = 'disponivel',
      String responsavel = email,
    }) => Animal.fromJson({
      ...animaisMock.first.toJson(),
      'id': id,
      'nome': nome,
      'tipo': tipo.name,
      'status': status,
      'responsavelEmail': responsavel,
      'rua': 'Praça Olegário Maciel, 155',
      'bairro': 'Centro',
      'observacoes': 'Muito dócil com crianças',
      'dono': {'nome': 'Luisa', 'telefone': '13999991111'},
      'latitude': -20.4642,
      'longitude': -45.4267,
    });

    Future<_ApiFalsa> abrirRegistros(
      WidgetTester tester,
      EstadoPataAmiga estado, {
      bool fora = false,
    }) async {
      tester.view.physicalSize = const Size(1200, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final usuario = UsuarioProvider();
      await usuario.carregarUsuario(email);
      final api = _ApiFalsa(const [], fora: fora);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: usuario,
          child: PataAmigaScope(
            notifier: estado,
            child: MaterialApp(
              home: PerfilUsuario(api: api),
              routes: {
                AppRoutes.registerAnimal: (context) {
                  final argumento = ModalRoute.of(context)!.settings.arguments;
                  return CadastroAnimal(
                    base: argumento is Animal ? argumento : null,
                    editando: argumento is EdicaoDoRegistro
                        ? argumento.animal
                        : null,
                    api: api,
                  );
                },
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meus registros'));
      await tester.pumpAndSettle();
      return api;
    }

    Future<void> escolherNoMenu(
      WidgetTester tester,
      String nome,
      String opcao,
    ) async {
      await tester.tap(find.byTooltip('Opções de $nome'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(opcao).last);
      await tester.pumpAndSettle();
    }

    testWidgets('separa os registros por situação e esconde grupo vazio', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarAnimais([
        registro('Paçoca', TipoRegistro.adocao, id: 1),
        registro('Bolinha', TipoRegistro.adocao, id: 2, status: 'adotado'),
        registro('Simba', TipoRegistro.perdido, id: 3, status: 'encontrado'),
      ]);
      await abrirRegistros(tester, estado);

      expect(find.text('Em aberto'), findsOneWidget);
      expect(find.text('Adotados'), findsOneWidget);
      expect(find.text('Encontrados'), findsOneWidget);
      expect(find.text('Resgatados'), findsNothing);
      // Cada animal fica abaixo do título do seu grupo
      expect(
        tester.getTopLeft(find.text('BOLINHA')).dy,
        greaterThan(tester.getTopLeft(find.text('Adotados')).dy),
      );
      expect(
        tester.getTopLeft(find.text('BOLINHA')).dy,
        lessThan(tester.getTopLeft(find.text('Encontrados')).dy),
      );
    });

    testWidgets('encerrar pelo menu leva o registro para o grupo do desfecho', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarAnimais([registro('Paçoca', TipoRegistro.adocao, id: 1)]);
      final api = await abrirRegistros(tester, estado);
      expect(find.text('Adotados'), findsNothing);

      await escolherNoMenu(tester, 'Paçoca', 'Marcar como adotado');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(api.statusGravados, [StatusAnimal.adotado]);
      expect(find.text('Adotados'), findsOneWidget);
      expect(find.text('Em aberto'), findsNothing);

      // E o menu oferece desfazer
      await escolherNoMenu(tester, 'Paçoca', 'Voltar para disponível');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(find.text('Em aberto'), findsOneWidget);
    });

    testWidgets('editar abre o registro inteiro e grava o que mudou', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final original = registro(
        'Paçoca',
        TipoRegistro.perdido,
        id: 7,
        status: 'encontrado',
      );
      estado.atualizarAnimais([original]);
      final api = await abrirRegistros(tester, estado);

      await escolherNoMenu(tester, 'Paçoca', 'Editar registro');
      expect(find.text('EDITAR REGISTRO'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Paçoca'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Praça Olegário Maciel, 155'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextField, 'Muito dócil com crianças'),
        findsOneWidget,
      );
      // As fotos que o registro já tem entram no bloco de fotos do cadastro,
      // com a primeira como capa
      expect(find.text('Capa'), findsOneWidget);
      expect(find.text('Fotos publicadas'), findsNothing);
      // A API guarda só os dígitos, mas o campo mostra a máscara
      expect(find.widgetWithText(TextField, '(13) 99999-1111'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Paçoca'),
        'Paçoquinha',
      );
      final salvar = find.text('Salvar alterações');
      await tester.ensureVisible(salvar);
      await tester.pumpAndSettle();
      await tester.tap(salvar);
      await tester.pumpAndSettle();

      expect(find.text('EDITAR REGISTRO'), findsNothing);
      expect(find.text('PAÇOQUINHA'), findsOneWidget);
      expect(find.text('Alterações salvas.'), findsOneWidget);
      // O que o formulário não mostra continua igual
      final gravado = api.editados.single;
      expect(gravado.id, 7);
      expect(gravado.status, StatusAnimal.encontrado);
      expect(gravado.tipo, TipoRegistro.perdido);
      expect(gravado.responsavelEmail, email);
      expect(gravado.publicadoEm, original.publicadoEm);
      expect(gravado.latitude, -20.4642);
    });

    testWidgets('sem conexão, a edição avisa e a tela continua aberta', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarAnimais([registro('Paçoca', TipoRegistro.adocao, id: 1)]);
      await abrirRegistros(tester, estado, fora: true);

      await escolherNoMenu(tester, 'Paçoca', 'Editar registro');
      final salvar = find.text('Salvar alterações');
      await tester.ensureVisible(salvar);
      await tester.pumpAndSettle();
      await tester.tap(salvar);
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível salvar as alterações. Tente de novo.'),
        findsOneWidget,
      );
      expect(find.text('EDITAR REGISTRO'), findsOneWidget);
    });

    testWidgets('cadastro de outra conta no aparelho não tem o menu', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      await estado.registrarCadastro(
        registro('Bolinha', TipoRegistro.adocao, responsavel: 'outra@pata.com'),
      );
      await abrirRegistros(tester, estado);

      expect(find.text('BOLINHA'), findsOneWidget);
      expect(find.byTooltip('Opções de Bolinha'), findsNothing);
    });

    testWidgets('a ficha também abre a edição', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1200, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final animal = registro('Paçoca', TipoRegistro.adocao, id: 1);
      estado.atualizarAnimais([animal]);
      final usuario = UsuarioProvider();
      await usuario.carregarUsuario(email);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: usuario,
          child: PataAmigaScope(
            notifier: estado,
            child: MaterialApp(
              home: DetalhesAnimal(animal: animal, api: _ApiFalsa(const [])),
              routes: {
                AppRoutes.registerAnimal:
                    AppRoutesConfig.routes[AppRoutes.registerAnimal]!,
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editar = find.text('Editar registro');
      await tester.ensureVisible(editar);
      await tester.pumpAndSettle();
      await tester.tap(editar);
      await tester.pumpAndSettle();
      expect(find.text('EDITAR REGISTRO'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Paçoca'), findsOneWidget);
    });
  });

  group('filtros do feed (US 06)', () {
    Animal bicho(
      String nome, {
      String especie = 'cachorro',
      String porte = 'médio',
      String sexo = 'macho',
      String raca = '',
      String bairro = 'Centro',
      bool castrado = false,
      bool vacinado = false,
      String tipo = 'adocao',
    }) => Animal.fromJson({
      ...animaisMock.first.toJson(),
      'id': null,
      'nome': nome,
      'tipo': tipo,
      'status': 'disponivel',
      'especie': especie,
      'porte': porte,
      'sexo': sexo,
      'raca': raca,
      'bairro': bairro,
      'castrado': castrado,
      'vacinado': vacinado,
      'vermifugado': false,
    });

    final thor = bicho(
      'Thor',
      porte: 'grande',
      raca: 'labrador',
      castrado: true,
      vacinado: true,
    );
    final mel = bicho(
      'Mel',
      especie: 'gato',
      porte: 'pequeno',
      sexo: 'fêmea',
      raca: 'vira-lata',
      bairro: 'Água Vermelha',
      vacinado: true,
    );
    final bob = bicho('Bob', raca: 'SRD');

    test('a raça escrita de jeitos diferentes vira uma só', () {
      expect(racaPadrao('vira-lata'), semRacaDefinida);
      expect(racaPadrao(' SRD '), semRacaDefinida);
      expect(racaPadrao('labrador'), 'Labrador Retriever');
      expect(racaPadrao('LAPERM'), 'LaPerm');
      expect(racaPadrao('pastor DE  shetland'), 'Pastor de Shetland');
      expect(racaPadrao(''), '');
      expect(racasDoFeed([thor, mel, bob]), [
        semRacaDefinida,
        'Labrador Retriever',
      ]);
    });

    test('opções no mesmo grupo somam; grupos diferentes se combinam', () {
      final cachorroSemRaca = const FiltrosDoFeed()
          .alternar(GrupoDeFiltro.especie, 'cachorro')
          .alternar(GrupoDeFiltro.raca, semRacaDefinida);
      expect([thor, mel, bob].where(cachorroSemRaca.combina), [bob]);

      final pequenoOuGrande = const FiltrosDoFeed()
          .alternar(GrupoDeFiltro.porte, 'pequeno')
          .alternar(GrupoDeFiltro.porte, 'grande');
      expect([thor, mel, bob].where(pequenoOuGrande.combina), [thor, mel]);
    });

    test('na saúde, marcar dois cuidados pede os dois', () {
      final vacinado = const FiltrosDoFeed().alternar(
        GrupoDeFiltro.saude,
        'vacinado',
      );
      expect([thor, mel, bob].where(vacinado.combina), [thor, mel]);
      final vacinadoECastrado = vacinado.alternar(
        GrupoDeFiltro.saude,
        'castrado',
      );
      expect([thor, mel, bob].where(vacinadoECastrado.combina), [thor]);
    });

    test('os bairros saem do feed em ordem, sem tropeçar no acento', () {
      final zona = bicho('Zeca', bairro: 'Vila Ferreira');
      expect(opcoesDe(GrupoDeFiltro.bairro, [zona, mel, thor]), [
        'Água Vermelha',
        'Centro',
        'Vila Ferreira',
      ]);
    });

    test('a raça escrita acha a opção da lista da espécie', () {
      expect(racaDaLista('cachorro', 'labrador'), 'Labrador Retriever');
      expect(racaDaLista('cachorro', 'Spitz Alemão'), 'Lulu da Pomerânia');
      expect(racaDaLista('Gato', 'vira-lata'), semRacaDefinida);
      expect(racaDaLista('gato', 'siames'), 'Siamês');
      expect(racaDaLista('gato', 'Labrador'), isNull);
      expect(racaDaLista('cachorro', 'Raça Inventada'), isNull);
      expect(racaDaLista(null, 'Labrador'), isNull);
      // Todo nome da lista sai igual pela padronização do filtro
      for (final raca in [...racasDeCachorro, ...racasDeGato]) {
        expect(racaPadrao(raca), raca);
      }
    });

    testWidgets('a raça é escolhida da lista da espécie e some ao trocá-la', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: CadastroAnimal()));
      await tester.tap(find.text('Adoção'));
      await tester.pumpAndSettle();

      Finder campoDaRaca(String dica) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == dica,
      );
      // Sem espécie, a raça espera
      expect(
        tester
            .widget<TextField>(campoDaRaca('Escolha a espécie primeiro'))
            .enabled,
        isFalse,
      );

      Future<void> escolherEspecie(String especie) async {
        final menu = find.byType(DropdownButtonFormField<String>).first;
        await tester.ensureVisible(menu);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text(especie).last);
        await tester.pumpAndSettle();
      }

      await escolherEspecie('Cachorro');
      await tester.enterText(campoDaRaca('Digite para buscar a raça'), 'lab');
      await tester.pumpAndSettle();
      expect(find.text('Outra raça'), findsOneWidget);
      await tester.tap(find.text('Labrador Retriever').last);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextField, 'Labrador Retriever'),
        findsOneWidget,
      );

      // Gato não tem Labrador: a raça escolhida sai
      await escolherEspecie('Gato');
      expect(
        find.widgetWithText(TextField, 'Labrador Retriever'),
        findsNothing,
      );
    });

    final rex = bicho('Rex', tipo: 'perdido');
    final tom = bicho('Tom', especie: 'gato', tipo: 'perdido');

    Future<void> abrirFeed(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1200, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      await tester.pumpWidget(
        PataAmigaScope(
          notifier: estado,
          child: MaterialApp(
            home: FeedAdocao(api: _ApiFalsa([thor, mel, bob, rex, tom])),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder campo(String dica) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == dica,
    );

    // Digita no select e escolhe a opção na lista, como no cadastro
    Future<void> escolherNoSelect(
      WidgetTester tester,
      String dica,
      String digitado,
      String opcao,
    ) async {
      await tester.ensureVisible(campo(dica));
      // Tocar abre a lista mesmo sem digitar nada
      await tester.tap(campo(dica));
      await tester.pumpAndSettle();
      if (digitado.isNotEmpty) await tester.enterText(campo(dica), digitado);
      await tester.pumpAndSettle();
      await tester.tap(find.text(opcao).last);
      await tester.pumpAndSettle();
    }

    testWidgets('o painel conta, aplica, tira um filtro e limpa todos', (
      tester,
    ) async {
      await abrirFeed(tester);
      expect(find.text('THOR'), findsOneWidget);

      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Mostrar 3 animais'), findsOneWidget);

      await tester.tap(find.text('Cachorro'));
      await tester.pumpAndSettle();
      expect(find.text('Mostrar 2 animais'), findsOneWidget);
      await escolherNoSelect(
        tester,
        'Digite para buscar a raça',
        'sem',
        semRacaDefinida,
      );
      // Marcar não muda o feed até confirmar
      expect(find.text('Mostrar 1 animal'), findsOneWidget);

      await tester.tap(find.text('Mostrar 1 animal'));
      await tester.pumpAndSettle();
      expect(find.text('BOB'), findsOneWidget);
      expect(find.text('THOR'), findsNothing);
      expect(find.text('MEL'), findsNothing);
      // O botão diz quantos filtros estão ligados
      expect(
        find.descendant(
          of: find.byTooltip('Filtros'),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      // Tirar só a espécie traz a gata sem raça de volta. A espécie vem
      // antes da raça na faixa
      expect(find.widgetWithText(InputChip, 'Cachorro'), findsOneWidget);
      await tester.tap(find.byTooltip('Tirar o filtro').first);
      await tester.pumpAndSettle();
      expect(find.text('BOB'), findsOneWidget);
      expect(find.text('MEL'), findsOneWidget);
      expect(find.text('THOR'), findsNothing);

      await tester.tap(find.text('Limpar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('THOR'), findsOneWidget);
      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('o select de raça do filtro só tem raças cadastradas', (
      tester,
    ) async {
      await abrirFeed(tester);
      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(campo('Digite para buscar a raça'));
      await tester.pumpAndSettle();
      expect(find.text('Labrador Retriever'), findsOneWidget);
      expect(find.text('Beagle'), findsNothing);
      // As fixas ficam no rodapé
      expect(find.text(semRacaDefinida), findsOneWidget);
      expect(find.text('Todas as raças'), findsOneWidget);

      await tester.tap(find.text('Labrador Retriever'));
      await tester.pumpAndSettle();
      expect(find.text('Mostrar 1 animal'), findsOneWidget);
      // "Todas as raças" desliga o filtro de raça
      await escolherNoSelect(
        tester,
        'Digite para buscar a raça',
        '',
        'Todas as raças',
      );
      // A espécie marcada junto com o Labrador continua: são os 2 cachorros
      expect(find.text('Mostrar 2 animais'), findsOneWidget);
    });

    testWidgets('escolher a raça marca a espécie; trocar a espécie a apaga', (
      tester,
    ) async {
      await abrirFeed(tester);
      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();

      SegmentedButton<String> abaDaEspecie() => tester
          .widgetList<SegmentedButton<String>>(
            find.byType(SegmentedButton<String>),
          )
          .first;
      expect(abaDaEspecie().selected, isEmpty);

      await escolherNoSelect(
        tester,
        'Digite para buscar a raça',
        'lab',
        'Labrador Retriever',
      );
      expect(abaDaEspecie().selected, {'cachorro'});
      // A lista se refaz com a espécie: a gata sem raça some do rodapé
      await tester.tap(campo('Digite para buscar a raça'));
      await tester.pumpAndSettle();
      expect(find.text(semRacaDefinida), findsOneWidget);

      await tester.tap(find.text('Gato'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cachorro'));
      await tester.pumpAndSettle();
      expect(abaDaEspecie().selected, {'gato'});
      expect(
        find.widgetWithText(InputChip, 'Labrador Retriever'),
        findsNothing,
      );
    });

    testWidgets('dá para escolher mais de uma raça no filtro', (tester) async {
      await abrirFeed(tester);
      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();

      await escolherNoSelect(
        tester,
        'Digite para buscar a raça',
        'lab',
        'Labrador Retriever',
      );
      // O campo volta vazio, e a escolhida vira uma etiqueta
      expect(
        find.widgetWithText(InputChip, 'Labrador Retriever'),
        findsOneWidget,
      );
      expect(find.text('Mostrar 1 animal'), findsOneWidget);

      await escolherNoSelect(
        tester,
        'Digite para buscar a raça',
        '',
        semRacaDefinida,
      );
      expect(find.widgetWithText(InputChip, semRacaDefinida), findsOneWidget);
      // Labrador ou sem raça, entre os cachorros que o Labrador marcou
      expect(find.text('Mostrar 2 animais'), findsOneWidget);

      // Tirar na etiqueta desmarca
      await tester.tap(find.byTooltip('Tirar Labrador Retriever'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(InputChip, 'Labrador Retriever'),
        findsNothing,
      );
      expect(find.text('Mostrar 1 animal'), findsOneWidget);
    });

    testWidgets('os filtros continuam valendo ao trocar de aba', (
      tester,
    ) async {
      await abrirFeed(tester);
      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gato'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mostrar 1 animal'));
      await tester.pumpAndSettle();
      expect(find.text('MEL'), findsOneWidget);
      expect(find.text('THOR'), findsNothing);

      await tester.tap(find.text('Perdidos'));
      await tester.pumpAndSettle();
      // Na outra aba, o filtro continua ligado e só o gato perdido aparece
      expect(find.widgetWithText(InputChip, 'Gato'), findsOneWidget);
      expect(find.text('TOM'), findsOneWidget);
      expect(find.text('REX'), findsNothing);

      // E o painel, aberto aqui, já conta pela aba de perdidos
      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Mostrar 1 animal'), findsOneWidget);
    });

    testWidgets('sem nenhum animal que combine, o feed oferece limpar', (
      tester,
    ) async {
      await abrirFeed(tester);
      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gato'));
      await tester.pumpAndSettle();
      // A gata é da Água Vermelha: no Centro não há nenhum gato
      await escolherNoSelect(
        tester,
        'Digite para buscar o bairro',
        'Centro',
        'Centro',
      );
      expect(find.text('Nenhum animal combina'), findsOneWidget);

      await tester.tap(find.text('Nenhum animal combina'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum animal com esses filtros.'), findsOneWidget);

      await tester.tap(find.text('Limpar filtros').last);
      await tester.pumpAndSettle();
      expect(find.text('THOR'), findsOneWidget);
    });
  });

  group('perfil de ONG (US 13)', () {
    const emailDaOng = 'ong@example.org';

    Ong ongDeExemplo({int? id = 1, String email = emailDaOng}) => Ong(
      id: id,
      nome: 'Abrigo Focinhos (exemplo)',
      descricao: 'Resgata cães e gatos.',
      politicaDeAdocao: 'Visita e termo de adoção.',
      telefone: '13999997777',
      chavePix: 'doacoes@example.org',
      rua: 'Praça São Vicente Férrer',
      bairro: 'Centro',
      latitude: -20.4647,
      longitude: -45.4264,
      responsavelEmail: email,
      criadaEm: DateTime(2026, 10, 1),
    );

    Animal daOng(
      String nome,
      DateTime publicado, {
      String status = 'disponivel',
    }) => Animal.fromJson({
      ...animaisMock.first.toJson(),
      'nome': nome,
      'status': status,
      'responsavelEmail': emailDaOng,
      'ongId': 1,
      'publicadoEm': publicado.toIso8601String(),
    });

    Future<void> montar(
      WidgetTester tester, {
      required EstadoPataAmiga estado,
      required Widget tela,
      String email = 'luisa@pata.com',
    }) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final usuario = UsuarioProvider();
      await usuario.registrarUsuario(
        nome: 'Luisa',
        email: email,
        telefone: '37999990000',
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: usuario,
          child: PataAmigaScope(
            notifier: estado,
            child: MaterialApp(
              home: tela,
              routes: {...AppRoutesConfig.routes}..remove(AppRoutes.welcome),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    test('a ONG vai e volta da API sem perder nada', () {
      final ong = ongDeExemplo();
      final volta = Ong.fromJson(ong.toJson());
      expect(volta.toJson(), ong.toJson());
      // Antes de existir na API, a ONG vai sem id
      expect(ongDeExemplo(id: null).toJson().containsKey('id'), isFalse);
    });

    test('as iniciais pulam as ligações e o que está entre parênteses', () {
      expect(iniciaisDa('Abrigo Focinhos (exemplo)'), 'AF');
      expect(iniciaisDa('Associação dos Amigos dos Animais'), 'AA');
      expect(iniciaisDa(''), isEmpty);
    });

    test('a ONG é achada pelo e-mail de quem a criou, sem ligar para '
        'maiúsculas', () {
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarOngs([ongDeExemplo()]);
      expect(estado.ongDe(' ONG@Example.org ')?.nome, contains('Focinhos'));
      expect(estado.ongDe('luisa@pata.com'), isNull);
      expect(estado.ongDe(''), isNull);
    });

    test('editar troca a ONG em vez de criar outra', () {
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarOngs([ongDeExemplo()]);
      estado.salvarOng(
        Ong.fromJson({...ongDeExemplo().toJson(), 'nome': 'Novo nome'}),
      );
      expect(estado.ongs.single.nome, 'Novo nome');
    });

    test('o animal cadastrado por último é o primeiro da ONG', () {
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarAnimais([
        daOng('Antigo', DateTime(2026, 10, 1)),
        animaisMock.first,
        daOng('Do meio', DateTime(2026, 10, 5)),
      ]);
      estado.atualizarAnimais([
        ...estado.animais,
        daOng('Novo', DateTime(2026, 10, 22)),
      ]);
      expect(estado.animaisDa(ongDeExemplo()).map((animal) => animal.nome), [
        'Novo',
        'Do meio',
        'Antigo',
      ]);
    });

    testWidgets('a lista do menu abre o perfil, com os animais e o Pix', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarAnimais([
        daOng('Thor', DateTime(2026, 10, 10)),
        daOng('Amora', DateTime(2026, 10, 13)),
        daOng('Mel', DateTime(2026, 10, 2), status: 'adotado'),
        Animal.fromJson({
          ...daOng('Fred', DateTime(2026, 10, 12)).toJson(),
          'tipo': 'resgate',
        }),
      ]);
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (chamada) async {
          if (chamada.method == 'Clipboard.setData') {
            copiado = (chamada.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      await montar(
        tester,
        estado: estado,
        tela: ListaOngs(
          servico: _OngsFalsas([
            ongDeExemplo(),
            Ong.fromJson({
              ...ongDeExemplo(id: 2).toJson(),
              'nome': 'Órfãos de Patas',
            }),
            Ong.fromJson({...ongDeExemplo(id: 3).toJson(), 'nome': 'Zoo Lar'}),
          ]),
        ),
      );

      expect(find.text('Abrigo Focinhos (exemplo)'), findsOneWidget);
      expect(find.text('3 animais em aberto'), findsOneWidget);

      // Em ordem alfabética, com o "Ó" junto do "O", antes do "Z"
      double topo(String nome) => tester.getTopLeft(find.text(nome)).dy;
      expect(
        topo('Abrigo Focinhos (exemplo)'),
        lessThan(topo('Órfãos de Patas')),
      );
      expect(topo('Órfãos de Patas'), lessThan(topo('Zoo Lar')));

      // A busca é pelo nome, sem ligar para acentos; o bairro não conta
      await tester.enterText(find.byType(TextField), 'orfaos');
      await tester.pumpAndSettle();
      expect(find.text('Órfãos de Patas'), findsOneWidget);
      expect(find.text('Abrigo Focinhos (exemplo)'), findsNothing);
      await tester.enterText(find.byType(TextField), 'centro');
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma ONG com esse nome.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'focinhos');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrigo Focinhos (exemplo)'));
      await tester.pumpAndSettle();
      expect(find.text('Para adoção'), findsOneWidget);
      expect(find.text('Resgates'), findsOneWidget);
      expect(find.text('Perdidos'), findsNothing);
      expect(find.text('AMORA'), findsOneWidget);
      expect(find.text('THOR'), findsOneWidget);
      expect(find.text('Já encontraram um desfecho'), findsOneWidget);
      // Quem não criou a ONG não vê o editar
      expect(find.byTooltip('Editar perfil da ONG'), findsNothing);

      await tester.tap(find.text('Copiar'));
      await tester.pumpAndSettle();
      expect(copiado, 'doacoes@example.org');
      expect(
        find.text(
          'Chave Pix copiada. Cole no aplicativo do seu banco para doar.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('só quem criou a ONG vê o editar no perfil dela', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
      final ong = ongDeExemplo();
      estado.atualizarOngs([ong]);
      await montar(
        tester,
        estado: estado,
        tela: PerfilOng(ong: ong),
        email: emailDaOng,
      );
      expect(find.byTooltip('Editar perfil da ONG'), findsOneWidget);

      await tester.tap(find.byTooltip('Editar perfil da ONG'));
      await tester.pumpAndSettle();
      expect(find.text('EDITAR PERFIL DA ONG'), findsOneWidget);
      expect(find.text('Abrigo Focinhos (exemplo)'), findsWidgets);
    });

    testWidgets('criar a ONG pede os obrigatórios e a liga a quem criou', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final servico = _OngsFalsas();
      await montar(
        tester,
        estado: estado,
        tela: CadastroOng(servico: servico),
      );
      // O telefone já vem de quem está logado
      final telefone = find.byWidgetPredicate(
        (widget) =>
            widget is EditableText &&
            widget.controller.text == '(37) 99999-0000',
      );
      expect(telefone, findsOneWidget);
      await tester.enterText(telefone, '');
      await tester.ensureVisible(find.text('Criar perfil da ONG'));
      await tester.tap(find.text('Criar perfil da ONG'));
      await tester.pumpAndSettle();
      // Nome, descrição, política, telefone e Pix: só a foto é opcional
      expect(find.text('Campo obrigatório'), findsNWidgets(5));
      expect(
        find.text('Preencha os campos obrigatórios marcados em vermelho.'),
        findsOneWidget,
      );
      expect(servico.salvas, isEmpty);

      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'Lar dos Bichos');
      await tester.enterText(campos.at(1), 'Abrigo de cães idosos.');
      await tester.enterText(campos.at(2), 'Visita e termo de adoção.');
      await tester.enterText(campos.at(3), '37988887777');
      await tester.enterText(campos.at(4), 'pix@example.org');
      await tester.ensureVisible(find.text('Criar perfil da ONG'));
      await tester.tap(find.text('Criar perfil da ONG'));
      await tester.pumpAndSettle();

      final salva = servico.salvas.single;
      expect(salva.nome, 'Lar dos Bichos');
      expect(salva.telefone, '37988887777');
      expect(salva.chavePix, 'pix@example.org');
      expect(salva.responsavelEmail, 'luisa@pata.com');
      expect(estado.ongDe('luisa@pata.com')?.id, salva.id);
    });

    testWidgets('quem já tem ONG abre o cadastro editando a que existe', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarOngs([ongDeExemplo(email: 'luisa@pata.com')]);
      final servico = _OngsFalsas([ongDeExemplo(email: 'luisa@pata.com')]);
      await montar(
        tester,
        estado: estado,
        tela: CadastroOng(servico: servico),
      );
      expect(find.text('EDITAR PERFIL DA ONG'), findsOneWidget);
      await tester.ensureVisible(find.text('Salvar alterações'));
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();
      // Gravou por cima da mesma ONG, sem criar outra
      expect(servico.salvas.single.id, 1);
      expect(servico.ongs, hasLength(1));
    });

    testWidgets('a ONG criada em outro aparelho impede criar a segunda', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      // O app ainda não sabe da ONG; só a API sabe
      final servico = _OngsFalsas([ongDeExemplo(email: 'luisa@pata.com')]);
      await montar(
        tester,
        estado: estado,
        tela: CadastroOng(servico: servico),
      );
      expect(find.text('PERFIL DA ONG'), findsOneWidget);
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'Segunda ONG');
      await tester.enterText(campos.at(1), 'Outra descrição.');
      await tester.enterText(campos.at(2), 'Visita e termo de adoção.');
      await tester.enterText(campos.at(4), 'pix@example.org');
      await tester.ensureVisible(find.text('Criar perfil da ONG'));
      await tester.tap(find.text('Criar perfil da ONG'));
      await tester.pumpAndSettle();

      expect(servico.salvas, isEmpty);
      expect(
        find.textContaining('Sua conta já faz parte da ONG Abrigo Focinhos'),
        findsOneWidget,
      );
      // O formulário passa a editar a que existe, com os dados dela
      expect(find.text('EDITAR PERFIL DA ONG'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is EditableText &&
              widget.controller.text == 'Abrigo Focinhos (exemplo)',
        ),
        findsOneWidget,
      );
    });

    test('pedir, aprovar e recusar mudam quem faz parte', () {
      const maria = PessoaDaOng(
        email: 'maria@pata.com',
        nome: 'Maria',
        telefone: '37988880000',
      );
      const joao = PessoaDaOng(
        email: 'joao@pata.com',
        nome: 'João',
        telefone: '37988880000',
      );
      final ong = ongDeExemplo().comPedidoDe(maria).comPedidoDe(joao);
      expect(ong.pediuEntrada('MARIA@pata.com'), isTrue);
      expect(ong.fazParte('maria@pata.com'), isFalse);
      // Pedir de novo não repete o pedido
      expect(ong.comPedidoDe(maria).pedidos, hasLength(2));

      final depois = ong
          .respondendo('maria@pata.com', aprovar: true)
          .respondendo('joao@pata.com', aprovar: false);
      expect(depois.fazParte('maria@pata.com'), isTrue);
      expect(depois.fazParte('joao@pata.com'), isFalse);
      expect(depois.pedidos, isEmpty);
      // Os membros vão e voltam da API
      expect(Ong.fromJson(depois.toJson()).membros.single.nome, 'Maria');
    });

    test('nomes iguais sem ligar para maiúsculas, acentos e espaços', () {
      final ong = ongDeExemplo();
      expect(ong.temNome('  abrigo focinhos   (EXEMPLO) '), isTrue);
      expect(
        Ong.fromJson({...ong.toJson(), 'nome': 'Abrigo São Francisco'})
            .temNome('abrigo sao francisco'),
        isTrue,
      );
      expect(ong.temNome('Abrigo Focinhos de Formiga'), isFalse);
    });

    testWidgets('quem criou a ONG vê o pedido no sino e aprova', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final comPedido = ongDeExemplo(email: 'luisa@pata.com').comPedidoDe(
        PessoaDaOng(
          email: 'maria@pata.com',
          nome: 'Maria',
          telefone: '37988880000',
        ),
      );
      final servico = _OngsFalsas([comPedido]);
      await montar(
        tester,
        estado: estado,
        tela: Scaffold(
          appBar: AppBar(
            actions: [
              SinoDeNotificacoes(email: 'luisa@pata.com', servico: servico),
            ],
          ),
        ),
      );
      expect(find.byTooltip('1 notificação'), findsOneWidget);

      await tester.tap(find.byTooltip('1 notificação'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          ' quer fazer parte de Abrigo Focinhos (exemplo).',
          findRichText: true,
        ),
        findsNothing,
      );
      expect(
        find.textContaining('quer fazer parte de', findRichText: true),
        findsOneWidget,
      );
      // O e-mail não aparece; o "Ver perfil" mostra quem é a pessoa
      expect(find.text('maria@pata.com'), findsNothing);
      await tester.tap(find.text('Toque para ver o perfil.'));
      await tester.pumpAndSettle();
      expect(find.text('M'), findsWidgets);
      expect(find.text('(37) 98888-0000'), findsOneWidget);
      expect(find.text('Conversar no WhatsApp'), findsOneWidget);
      // Sem animais publicados, a seção nem aparece
      expect(find.textContaining('publicado'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aprovar'));
      await tester.pumpAndSettle();

      expect(servico.salvas.single.fazParte('maria@pata.com'), isTrue);
      expect(estado.ongDe('maria@pata.com')?.id, 1);
      expect(
        find.text('Maria agora faz parte de Abrigo Focinhos (exemplo).'),
        findsOneWidget,
      );
    });

    testWidgets('quem não criou a ONG não vê o sino', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final servico = _OngsFalsas([
        ongDeExemplo().comPedidoDe(
          PessoaDaOng(
            email: 'maria@pata.com',
            nome: 'Maria',
            telefone: '37988880000',
          ),
        ),
      ]);
      await montar(
        tester,
        estado: estado,
        tela: Scaffold(
          appBar: AppBar(
            actions: [
              SinoDeNotificacoes(email: 'luisa@pata.com', servico: servico),
            ],
          ),
        ),
      );
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('no editar perfil, quem faz parte escolhe a ONG e pede', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final servico = _OngsFalsas([
        Ong.fromJson({...ongDeExemplo().toJson(), 'nome': 'Lar dos Bichos'}),
        Ong.fromJson({...ongDeExemplo(id: 2).toJson(), 'nome': 'Abrigo Amigo'}),
      ]);
      await montar(
        tester,
        estado: estado,
        tela: EditarPerfil(ongs: servico),
      );
      await tester.ensureVisible(find.text('Sim'));
      await tester.tap(find.text('Sim'));
      await tester.pumpAndSettle();
      // O select com busca, como o do bairro
      final campo = find.widgetWithText(TextField, 'Digite para buscar a ONG');
      await tester.ensureVisible(campo);
      await tester.tap(campo);
      await tester.pumpAndSettle();

      // Em ordem alfabética
      final amigo = tester.getTopLeft(find.text('Abrigo Amigo')).dy;
      final lar = tester.getTopLeft(find.text('Lar dos Bichos')).dy;
      expect(amigo, lessThan(lar));

      await tester.tap(find.text('Lar dos Bichos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      final pedida = servico.salvas.single;
      expect(pedida.nome, 'Lar dos Bichos');
      expect(pedida.pediuEntrada('luisa@pata.com'), isTrue);
      // Pedir não dá acesso: só a aprovação
      expect(estado.ongDe('luisa@pata.com'), isNull);
      expect(estado.ongPedidaPor('luisa@pata.com')?.nome, 'Lar dos Bichos');
    });

    testWidgets('quem entrou por aprovação não edita a ONG', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final ong = ongDeExemplo()
          .comPedidoDe(
            PessoaDaOng(
              email: 'luisa@pata.com',
              nome: 'Luisa',
              telefone: '37988880000',
            ),
          )
          .respondendo('luisa@pata.com', aprovar: true);
      estado.atualizarOngs([ong]);
      await montar(tester, estado: estado, tela: const PerfilUsuario());
      // A ONG aparece no cabeçalho, como vínculo da pessoa
      await tester.tap(find.text('Abrigo Focinhos (exemplo)'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Editar perfil da ONG'), findsNothing);
    });

    testWidgets('não cria ONG com o nome de outra', (tester) async {
      SharedPreferences.setMockInitialValues({});
      pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final servico = _OngsFalsas([ongDeExemplo()]);
      await montar(
        tester,
        estado: estado,
        tela: CadastroOng(servico: servico),
      );
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'abrigo focinhos (EXEMPLO)');
      await tester.enterText(campos.at(1), 'Outra descrição.');
      await tester.enterText(campos.at(2), 'Visita e termo de adoção.');
      await tester.enterText(campos.at(4), 'pix@example.org');
      await tester.ensureVisible(find.text('Criar perfil da ONG'));
      await tester.tap(find.text('Criar perfil da ONG'));
      await tester.pumpAndSettle();
      expect(find.text('Já existe uma ONG com esse nome.'), findsOneWidget);
      expect(servico.salvas, isEmpty);

      // Mudar o nome tira o aviso e deixa criar
      await tester.enterText(campos.at(0), 'Abrigo Focinhos de Formiga');
      await tester.pumpAndSettle();
      expect(find.text('Já existe uma ONG com esse nome.'), findsNothing);
      await tester.ensureVisible(find.text('Criar perfil da ONG'));
      await tester.tap(find.text('Criar perfil da ONG'));
      await tester.pumpAndSettle();
      expect(servico.salvas.single.nome, 'Abrigo Focinhos de Formiga');
    });

    testWidgets('voltar com algo preenchido pergunta antes de sair', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      await montar(
        tester,
        estado: estado,
        tela: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.cadastroOng),
            child: const Text('Abrir'),
          ),
        ),
      );
      // Sem mudança, volta direto
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Abrir'), findsOneWidget);
      expect(find.text('Sair sem salvar?'), findsNothing);

      // Com o nome escrito, pergunta; continuar editando fica na tela
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Lar dos Bichos');
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Sair sem salvar?'), findsOneWidget);
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();
      expect(find.text('PERFIL DA ONG'), findsOneWidget);
      expect(find.text('Lar dos Bichos'), findsOneWidget);

      // Sair sem salvar volta e perde o que foi escrito
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair sem salvar'));
      await tester.pumpAndSettle();
      expect(find.text('Abrir'), findsOneWidget);
    });

    for (final (nome, rota, campo) in [
      ('editar perfil', AppRoutes.editarPerfil, 'Luisa Araujo'),
      ('cadastro de animal', AppRoutes.registerAnimal, 'Thor'),
    ]) {
      testWidgets('$nome também pergunta antes de sair sem salvar', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final estado = EstadoPataAmiga();
        addTearDown(estado.dispose);
        await montar(
          tester,
          estado: estado,
          tela: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.pushNamed(context, rota),
              child: const Text('Abrir'),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();
        expect(find.text('Abrir'), findsOneWidget);

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, campo);
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();
        expect(find.text('Sair sem salvar?'), findsOneWidget);
        await tester.tap(find.text('Sair sem salvar'));
        await tester.pumpAndSettle();
        expect(find.text('Abrir'), findsOneWidget);
      });
    }

    testWidgets('quem entrou na ONG transfere o próprio animal para ela', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final ong = ongDeExemplo()
          .comPedidoDe(
            PessoaDaOng(
              email: 'luisa@pata.com',
              nome: 'Luisa',
              telefone: '37988880000',
            ),
          )
          .respondendo('luisa@pata.com', aprovar: true);
      estado.atualizarOngs([ong]);
      final meu = Animal.fromJson({
        ...animaisMock.first.toJson(),
        'id': 9,
        'nome': 'Pipoca',
        // Já com desfecho: transferir vale para qualquer cadastro
        'status': 'encontrado',
        'responsavelEmail': 'luisa@pata.com',
      });
      estado.atualizarAnimais([meu]);
      final api = _ApiFalsa(const []);
      await montar(
        tester,
        estado: estado,
        tela: PerfilUsuario(api: api),
      );
      await tester.tap(find.text('Meus registros'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('transferir o cadastro para a ONG'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Opções de Pipoca'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transferir para Abrigo Focinhos (exemplo)'));
      await tester.pumpAndSettle();
      expect(
        find.text('Transferir Pipoca para Abrigo Focinhos (exemplo)?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      final enviado = api.editados.single;
      expect(enviado.ongId, 1);
      expect(enviado.dono.nome, 'Abrigo Focinhos (exemplo)');
      expect(enviado.responsavelEmail, 'luisa@pata.com');
      // Sai de Meus registros e passa a ser da ONG
      expect(estado.cadastrosDe('luisa@pata.com'), isEmpty);
      expect(estado.animaisDa(ong).single.nome, 'Pipoca');
    });

    testWidgets('mexer só no pino do mapa também pergunta antes de sair', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      GeolocatorPlatform.instance = _GpsFalso();
      pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      await montar(
        tester,
        estado: estado,
        tela: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.cadastroOng),
            child: const Text('Abrir'),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      // A mira leva o pino para onde a pessoa está
      await tester.ensureVisible(find.byTooltip('Usar minha localização'));
      await tester.tap(find.byTooltip('Usar minha localização'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Sair sem salvar?'), findsOneWidget);
    });

    testWidgets('o mapa de marcar o local começa travado', (tester) async {
      var arrastou = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapaDeLocal(
              controlador: MapController(),
              inicio: centroDeFormiga,
              aoArrastar: (_) => arrastou = true,
              aoUsarMinhaLocalizacao: () {},
            ),
          ),
        ),
      );
      expect(find.text('Destravar o mapa'), findsOneWidget);
      await tester.drag(find.byType(FlutterMap), const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(arrastou, isFalse);

      await tester.tap(find.text('Destravar o mapa'));
      await tester.pump();
      expect(find.text('Travar o mapa'), findsOneWidget);
      await tester.drag(find.byType(FlutterMap), const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(arrastou, isTrue);
    });

    test('o filtro de ONG traz só os animais das ONGs marcadas', () {
      final daUm = daOng('Thor', DateTime(2026, 10, 10));
      final daDois = Animal.fromJson({
        ...daOng('Amora', DateTime(2026, 10, 11)).toJson(),
        'ongId': 2,
      });
      final pessoal = animaisMock.first;
      final filtros = const FiltrosDoFeed().alternar(GrupoDeFiltro.ong, '1');
      expect(filtros.combina(daUm), isTrue);
      expect(filtros.combina(daDois), isFalse);
      expect(filtros.combina(pessoal), isFalse);
      expect(filtros.alternar(GrupoDeFiltro.ong, '2').combina(daDois), isTrue);
    });

    testWidgets('o painel filtra por ONG, marca todas e desmarca todas', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ongs = [
        Ong.fromJson({...ongDeExemplo(id: 2).toJson(), 'nome': 'Zoo Lar'}),
        ongDeExemplo(),
        // Sem animais no feed, não aparece no select
        Ong.fromJson({...ongDeExemplo(id: 3).toJson(), 'nome': 'Vazia'}),
      ];
      final animais = [
        daOng('Thor', DateTime(2026, 10, 10)),
        Animal.fromJson({
          ...daOng('Amora', DateTime(2026, 10, 11)).toJson(),
          'ongId': 2,
        }),
      ];
      FiltrosDoFeed? aplicados;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    aplicados = await showModalBottomSheet<FiltrosDoFeed>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => PainelDeFiltros(
                        inicial: const FiltrosDoFeed(),
                        animais: animais,
                        contar: (filtros) =>
                            animais.where(filtros.combina).length,
                        ongs: ongs,
                      ),
                    ),
                child: const Text('Filtros'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();

      final campo = find.widgetWithText(TextField, 'Digite para buscar a ONG');
      await tester.ensureVisible(campo);
      await tester.tap(campo);
      await tester.pumpAndSettle();
      // Em ordem alfabética, só as que têm animais
      expect(find.text('Vazia'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Abrigo Focinhos (exemplo)')).dy,
        lessThan(tester.getTopLeft(find.text('Zoo Lar')).dy),
      );

      await tester.tap(find.text('Selecionar todas'));
      await tester.pumpAndSettle();
      expect(find.text('Mostrar 2 animais'), findsOneWidget);

      await tester.tap(campo);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desmarcar todas'));
      await tester.pumpAndSettle();
      await tester.tap(campo);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zoo Lar').last);
      await tester.pumpAndSettle();
      expect(find.text('Mostrar 1 animal'), findsOneWidget);

      await tester.tap(find.text('Mostrar 1 animal'));
      await tester.pumpAndSettle();
      expect(aplicados?.de(GrupoDeFiltro.ong), {'2'});
    });

    test('não aprova quem já faz parte de outra ONG', () async {
      const bia = PessoaDaOng(email: 'bia@pata.com', nome: 'Bia', telefone: '');
      final outra = Ong.fromJson({
        ...ongDeExemplo(id: 2).toJson(),
        'nome': 'Outra',
        'responsavelEmail': 'bia@pata.com',
      });
      final servico = _OngsFalsas([ongDeExemplo().comPedidoDe(bia), outra]);
      await expectLater(
        servico.responderPedido(ongDeExemplo(), bia.email, aprovar: true),
        throwsA(isA<JaFazParteDeOutra>()),
      );
      // Recusar continua possível
      final recusada = await servico.responderPedido(
        ongDeExemplo(),
        bia.email,
        aprovar: false,
      );
      expect(recusada.pedidos, isEmpty);
    });

    testWidgets('quem espera resposta de uma ONG não cria outra', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final servico = _OngsFalsas([
        ongDeExemplo().comPedidoDe(
          PessoaDaOng(email: 'luisa@pata.com', nome: 'Luisa', telefone: ''),
        ),
      ]);
      await montar(
        tester,
        estado: estado,
        tela: CadastroOng(servico: servico),
      );
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'Lar dos Bichos');
      await tester.enterText(campos.at(1), 'Abrigo de cães idosos.');
      await tester.enterText(campos.at(2), 'Visita e termo de adoção.');
      await tester.enterText(campos.at(4), 'pix@example.org');
      await tester.ensureVisible(find.text('Criar perfil da ONG'));
      await tester.tap(find.text('Criar perfil da ONG'));
      await tester.pumpAndSettle();
      expect(servico.salvas, isEmpty);
      expect(
        find.textContaining('Você pediu para entrar em Abrigo Focinhos'),
        findsOneWidget,
      );
    });

    Future<void> abrirSino(
      WidgetTester tester,
      EstadoPataAmiga estado,
      _OngsFalsas servico,
      String email,
    ) async {
      await montar(
        tester,
        estado: estado,
        email: email,
        tela: Scaffold(
          appBar: AppBar(
            actions: [SinoDeNotificacoes(email: email, servico: servico)],
          ),
        ),
      );
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
    }

    testWidgets('o pedido de quem já está em outra ONG avisa e não aprova', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      const bia = PessoaDaOng(email: 'bia@pata.com', nome: 'Bia', telefone: '');
      final servico = _OngsFalsas([
        ongDeExemplo(email: 'luisa@pata.com').comPedidoDe(bia),
        Ong.fromJson({
          ...ongDeExemplo(id: 2).toJson(),
          'nome': 'Outra ONG',
          'responsavelEmail': 'bia@pata.com',
        }),
      ]);
      await abrirSino(tester, estado, servico, 'luisa@pata.com');
      expect(find.text('Notificações'), findsOneWidget);
      expect(find.textContaining('Já faz parte de Outra ONG'), findsOneWidget);
      final aprovar = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Aprovar'),
      );
      expect(aprovar.onPressed, isNull);
    });

    testWidgets('quem pediu para entrar vê no sino que o pedido aguarda', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final servico = _OngsFalsas([
        ongDeExemplo().comPedidoDe(
          PessoaDaOng(email: 'luisa@pata.com', nome: 'Luisa', telefone: ''),
        ),
      ]);
      await abrirSino(tester, estado, servico, 'luisa@pata.com');
      expect(
        find.text(
          'Seu pedido para entrar em Abrigo Focinhos (exemplo) aguarda '
          'aprovação.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('não dá para criar outra ONG'),
        findsOneWidget,
      );
    });

    testWidgets('o membro sai da ONG pelo editar perfil; quem criou não', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final ong = ongDeExemplo()
          .comPedidoDe(
            PessoaDaOng(email: 'luisa@pata.com', nome: 'Luisa', telefone: ''),
          )
          .respondendo('luisa@pata.com', aprovar: true);
      final servico = _OngsFalsas([ong]);
      estado.atualizarOngs([ong]);
      await montar(
        tester,
        estado: estado,
        tela: EditarPerfil(ongs: servico),
      );
      await tester.ensureVisible(find.text('Sair da ONG'));
      await tester.tap(find.text('Sair da ONG'));
      await tester.pumpAndSettle();
      expect(find.text('Sair de Abrigo Focinhos (exemplo)?'), findsOneWidget);
      await tester.tap(find.text('Sair da ONG').last);
      await tester.pumpAndSettle();
      expect(servico.salvas.single.fazParte('luisa@pata.com'), isFalse);
      expect(estado.ongDe('luisa@pata.com'), isNull);
      // Sem ONG, volta a pergunta
      expect(
        find.text('Você faz parte de alguma ONG ou abrigo?'),
        findsOneWidget,
      );
    });

    testWidgets('quem criou a ONG não tem a opção de sair', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarOngs([ongDeExemplo(email: 'luisa@pata.com')]);
      await montar(tester, estado: estado, tela: const EditarPerfil());
      expect(find.text('Você administra'), findsOneWidget);
      // A admin sai, mas só passando a ONG para um membro; sem membros,
      // o painel explica que é preciso aprovar alguém antes
      await tester.ensureVisible(find.text('Sair da ONG'));
      await tester.tap(find.text('Sair da ONG'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ninguém para administrar Abrigo Focinhos (exemplo)'),
        findsOneWidget,
      );
      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();
      expect(estado.ongDe('luisa@pata.com'), isNotNull);
    });

    testWidgets('a admin passa a ONG para um membro e sai', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final ong = ongDeExemplo(email: 'luisa@pata.com')
          .comPedidoDe(
            const PessoaDaOng(email: 'bia@pata.com', nome: 'Bia Souza'),
          )
          .respondendo('bia@pata.com', aprovar: true);
      final servico = _OngsFalsas([ong]);
      estado.atualizarOngs([ong]);
      await montar(
        tester,
        estado: estado,
        tela: EditarPerfil(ongs: servico),
      );
      await tester.ensureVisible(find.text('Sair da ONG'));
      await tester.tap(find.text('Sair da ONG'));
      await tester.pumpAndSettle();
      expect(
        find.text('Quem vai administrar Abrigo Focinhos (exemplo)?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Bia Souza'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Passar a ONG e sair'));
      await tester.pumpAndSettle();

      final depois = servico.salvas.single;
      expect(depois.eDoResponsavel('bia@pata.com'), isTrue);
      expect(depois.fazParte('luisa@pata.com'), isFalse);
      expect(depois.membros, isEmpty);
      expect(estado.ongDe('luisa@pata.com'), isNull);
    });

    testWidgets('quem criou vê as pessoas da ONG e remove uma', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final ong = ongDeExemplo(email: 'luisa@pata.com')
          .comPedidoDe(
            PessoaDaOng(
              email: 'bia@pata.com',
              nome: 'Bia Souza',
              telefone: '37988887777',
            ),
          )
          .respondendo('bia@pata.com', aprovar: true);
      final servico = _OngsFalsas([ong]);
      estado.atualizarOngs([ong]);
      await montar(
        tester,
        estado: estado,
        tela: PerfilOng(ong: ong, servico: servico),
      );
      await tester.ensureVisible(find.text('Membros'));
      expect(find.text('Administra a ONG'), findsOneWidget);
      expect(find.text('Bia Souza'), findsOneWidget);
      expect(find.text('(37) 98888-7777'), findsOneWidget);

      await tester.ensureVisible(find.text('Remover'));
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();
      expect(find.text('Remover Bia Souza da ONG?'), findsOneWidget);
      await tester.tap(find.text('Remover').last);
      await tester.pumpAndSettle();
      expect(servico.salvas.single.fazParte('bia@pata.com'), isFalse);
      expect(estado.ongDe('bia@pata.com'), isNull);
    });

    testWidgets('quem não criou a ONG não vê as pessoas dela', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final ong = ongDeExemplo();
      estado.atualizarOngs([ong]);
      await montar(
        tester,
        estado: estado,
        tela: PerfilOng(ong: ong),
      );
      expect(find.text('Membros'), findsNothing);
    });

    test('qualquer pessoa da ONG cuida dos animais da ONG', () {
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final ong = ongDeExemplo()
          .comPedidoDe(const PessoaDaOng(email: 'bia@pata.com', nome: 'Bia'))
          .respondendo('bia@pata.com', aprovar: true);
      estado.atualizarOngs([ong]);
      // Cadastrado pela admin, em nome da ONG
      final thor = daOng('Thor', DateTime(2026, 10, 10));
      expect(estado.podeMudarStatus(thor, emailDaOng), isTrue);
      expect(estado.podeMudarStatus(thor, 'bia@pata.com'), isTrue);
      // Quem não faz parte não mexe
      expect(estado.podeMudarStatus(thor, 'joao@pata.com'), isFalse);
    });

    test('só os pedidos das ONGs que a pessoa administra contam', () {
      final minha = ongDeExemplo(email: 'luisa@pata.com')
          .comPedidoDe(const PessoaDaOng(email: 'bia@pata.com', nome: 'Bia'));
      final deOutra = ongDeExemplo(id: 2)
          .comPedidoDe(const PessoaDaOng(email: 'caio@pata.com', nome: 'Caio'));
      expect(notificacoesPara([minha, deOutra], 'luisa@pata.com'), {
        'pedido:1:bia@pata.com',
      });
    });

    testWidgets('com o app aberto, pedido novo faz o celular vibrar', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      var vibrou = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (chamada) async {
          if (chamada.method == 'HapticFeedback.vibrate') vibrou++;
          return null;
        },
      );
      final servico = _OngsFalsas([ongDeExemplo(email: 'luisa@pata.com')]);
      await montar(
        tester,
        estado: estado,
        tela: FeedAdocao(api: _ApiFalsa(animaisMock), ongs: servico),
      );
      // Sem pedido novo, nada
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(vibrou, 0);

      // Chegou um pedido: na próxima conferência, vibra e o sino conta
      servico.ongs[0] = servico.ongs[0].comPedidoDe(
        const PessoaDaOng(email: 'bia@pata.com', nome: 'Bia'),
      );
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(vibrou, 1);
      expect(estado.ongs.single.pedidos.single.nome, 'Bia');
    });

    test('quem saiu da ONG deixa de cuidar dos animais dela', () {
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      // A Bia cadastrou o Thor em nome da ONG e depois foi removida
      final thor = Animal.fromJson({
        ...daOng('Thor', DateTime(2026, 10, 10)).toJson(),
        'responsavelEmail': 'bia@pata.com',
      });
      estado.atualizarOngs([ongDeExemplo()]);
      expect(estado.podeMudarStatus(thor, 'bia@pata.com'), isFalse);
      expect(estado.podeMudarStatus(thor, emailDaOng), isTrue);
    });

    testWidgets('o animal pessoal de quem faz parte da ONG não leva à ONG', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarOngs([ongDeExemplo()]);
      final pessoal = Animal.fromJson({
        ...daOng('Pipoca', DateTime(2026, 10, 12)).toJson()..remove('ongId'),
      });
      await montar(
        tester,
        estado: estado,
        tela: DetalhesAnimal(animal: pessoal),
      );
      expect(find.text('Ver perfil da ONG'), findsNothing);
    });

    test('o horário do pedido vai e volta da API', () {
      final quando = DateTime(2026, 10, 22, 9, 30);
      final ong = ongDeExemplo().comPedidoDe(
        PessoaDaOng(email: 'bia@pata.com', nome: 'Bia', em: quando),
      );
      expect(Ong.fromJson(ong.toJson()).pedidos.single.em, quando);
      // Sem horário informado, o pedido ganha o de agora
      final agora = ongDeExemplo()
          .comPedidoDe(const PessoaDaOng(email: 'caio@pata.com', nome: 'Caio'))
          .pedidos
          .single
          .em;
      expect(agora, isNotNull);
    });

    test(
      'responder a um pedido que não existe mais avisa em vez de fingir',
      () {
        final servico = _OngsFalsas([ongDeExemplo()]);
        expect(
          servico.responderPedido(
            ongDeExemplo(),
            'bia@pata.com',
            aprovar: true,
          ),
          throwsA(isA<PedidoNaoExiste>()),
        );
        expect(
          servico.passarAdministracao(ongDeExemplo(), 'bia@pata.com'),
          throwsA(isA<NaoEMembro>()),
        );
      },
    );

    test('quem já pediu para entrar numa ONG não pede em outra', () {
      const bia = PessoaDaOng(email: 'bia@pata.com', nome: 'Bia');
      final servico = _OngsFalsas([
        ongDeExemplo().comPedidoDe(bia),
        Ong.fromJson({...ongDeExemplo(id: 2).toJson(), 'nome': 'Outra'}),
      ]);
      expect(
        servico.pedirEntrada(servico.ongs[1], bia),
        throwsA(isA<JaFazParteDeOutra>()),
      );
    });

    testWidgets('editar um animal da ONG não o tira da ONG', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarOngs([ongDeExemplo(email: 'luisa@pata.com')]);
      final thor = Animal.fromJson({
        ...daOng('Thor', DateTime(2026, 10, 10)).toJson(),
        'id': 1,
        'rua': 'Praça Olegário Maciel, 155',
        'bairro': 'Centro',
        'latitude': -20.4642,
        'longitude': -45.4267,
      });
      final api = _ApiFalsa(const []);
      await montar(
        tester,
        estado: estado,
        tela: CadastroAnimal(editando: thor, api: api),
      );
      expect(find.text('PUBLICAR COMO'), findsNothing);
      await tester.ensureVisible(find.text('Salvar alterações'));
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();
      expect(api.editados.single.ongId, 1);
    });

    testWidgets('o Início também pergunta antes de largar um formulário', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      await montar(
        tester,
        estado: estado,
        tela: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.registerAnimal),
            child: const Text('Abrir'),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Thor');
      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();
      expect(find.text('Sair sem salvar?'), findsOneWidget);
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();
      expect(find.text('CADASTRAR ANIMAL'), findsOneWidget);
    });

    testWidgets('quem pediu recebe no sino se foi aprovado ou recusado', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      const luisa = PessoaDaOng(email: 'luisa@pata.com', nome: 'Luisa');
      final aprovada = ongDeExemplo()
          .comPedidoDe(luisa)
          .respondendo(luisa.email, aprovar: true);
      final recusada = Ong.fromJson({
        ...ongDeExemplo(id: 2).toJson(),
        'nome': 'Outra ONG',
      }).comPedidoDe(luisa).respondendo(luisa.email, aprovar: false);
      expect(aprovada.avisoPara(luisa.email)?.tipo, TipoDeAviso.aprovado);
      expect(recusada.avisoPara(luisa.email)?.tipo, TipoDeAviso.recusado);
      // O aviso vai e volta da API
      expect(
        Ong.fromJson(aprovada.toJson()).avisoPara(luisa.email)?.tipo,
        TipoDeAviso.aprovado,
      );

      final servico = _OngsFalsas([aprovada, recusada]);
      await abrirSino(tester, estado, servico, luisa.email);
      expect(
        find.text(
          'Seu pedido foi aprovado: você agora faz parte de Abrigo Focinhos '
          '(exemplo).',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Seu pedido para entrar em Outra ONG não foi aprovado.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Entendi').last);
      await tester.pumpAndSettle();
      expect(servico.salvas, hasLength(1));
    });

    testWidgets('quem é removido recebe o aviso no sino e dispensa', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final ong = ongDeExemplo()
          .comPedidoDe(
            const PessoaDaOng(email: 'luisa@pata.com', nome: 'Luisa'),
          )
          .respondendo('luisa@pata.com', aprovar: true)
          .removendo('luisa@pata.com');
      expect(ong.fazParte('luisa@pata.com'), isFalse);
      final servico = _OngsFalsas([ong]);
      await abrirSino(tester, estado, servico, 'luisa@pata.com');
      expect(
        find.text('Você não faz mais parte de Abrigo Focinhos (exemplo).'),
        findsOneWidget,
      );
      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();
      expect(servico.salvas.single.foiRemovida('luisa@pata.com'), isFalse);
      // Pedir de novo também apaga o aviso antigo
      expect(
        ong
            .comPedidoDe(
              const PessoaDaOng(email: 'luisa@pata.com', nome: 'Luisa'),
            )
            .foiRemovida('luisa@pata.com'),
        isFalse,
      );
    });

    testWidgets('a ONG aparece no cabeçalho do perfil e abre o perfil dela', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      await montar(tester, estado: estado, tela: const PerfilUsuario());
      // Sem ONG, o cabeçalho não mostra vínculo nenhum
      expect(find.textContaining('Abrigo'), findsNothing);

      estado.atualizarOngs([
        ongDeExemplo(id: 2).comPedidoDe(
          PessoaDaOng(email: 'luisa@pata.com', nome: 'Luisa', telefone: ''),
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Aguardando Abrigo Focinhos (exemplo)'), findsOneWidget);

      estado.atualizarOngs([ongDeExemplo(email: 'luisa@pata.com')]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrigo Focinhos (exemplo)'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Editar perfil da ONG'), findsOneWidget);
    });

    testWidgets('o editar perfil leva a criar o perfil de uma ONG', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      await montar(tester, estado: estado, tela: const EditarPerfil());
      await tester.ensureVisible(find.text('Criar o perfil de uma ONG'));
      await tester.tap(find.text('Criar o perfil de uma ONG'));
      await tester.pumpAndSettle();
      expect(find.text('PERFIL DA ONG'), findsOneWidget);
    });

    testWidgets('a ficha do animal da ONG leva ao perfil dela', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarOngs([ongDeExemplo()]);
      final animal = daOng('Thor', DateTime(2026, 10, 10));
      await montar(
        tester,
        estado: estado,
        tela: DetalhesAnimal(animal: animal),
      );
      await tester.ensureVisible(find.text('Ver perfil da ONG'));
      await tester.tap(find.text('Ver perfil da ONG'));
      await tester.pumpAndSettle();
      expect(find.text('Para adoção'), findsNothing);
      expect(find.text('Resgata cães e gatos.'), findsOneWidget);
    });

    testWidgets('a ficha de quem não é ONG não tem o atalho', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarOngs([ongDeExemplo()]);
      await montar(
        tester,
        estado: estado,
        tela: DetalhesAnimal(animal: animaisMock.first),
      );
      expect(find.text('Ver perfil da ONG'), findsNothing);
    });

    testWidgets('quem faz parte da ONG escolhe em nome de quem publica', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      estado.atualizarOngs([ongDeExemplo(email: 'luisa@pata.com')]);
      await montar(tester, estado: estado, tela: const CadastroAnimal());
      await tester.tap(find.text('Adoção'));
      await tester.pumpAndSettle();

      Finder campo(String texto) => find.byWidgetPredicate(
        (widget) => widget is EditableText && widget.controller.text == texto,
      );
      // Começa em nome da ONG, com o contato dela
      await tester.scrollUntilVisible(
        find.text('PUBLICAR COMO'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(campo('Abrigo Focinhos (exemplo)'), findsOneWidget);
      expect(campo('(13) 99999-7777'), findsOneWidget);

      // "Eu" troca para o contato da pessoa
      await tester.tap(find.text('Eu'));
      await tester.pumpAndSettle();
      expect(campo('Luisa'), findsOneWidget);
      expect(campo('37999990000'), findsOneWidget);
    });

    test('o animal da ONG não aparece também em Meus registros', () {
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      final daOngDela = Animal.fromJson({
        ...daOng('Thor', DateTime(2026, 10, 10)).toJson(),
        'responsavelEmail': 'luisa@pata.com',
      });
      final pessoal = Animal.fromJson({
        ...daOng('Pipoca', DateTime(2026, 10, 12)).toJson()..remove('ongId'),
        'responsavelEmail': 'luisa@pata.com',
      });
      estado.atualizarAnimais([daOngDela, pessoal]);
      final ong = ongDeExemplo(email: 'luisa@pata.com');
      expect(estado.cadastrosDe('luisa@pata.com').map((a) => a.nome), [
        'Pipoca',
      ]);
      expect(estado.animaisDa(ong).map((a) => a.nome), ['Thor']);
    });

    testWidgets('o menu tem ONGs entre Reportar e Perfil', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estado = EstadoPataAmiga();
      addTearDown(estado.dispose);
      await montar(
        tester,
        estado: estado,
        tela: const Scaffold(bottomNavigationBar: BarraInferior()),
      );
      final itens = tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .items
          .map((item) => item.label)
          .toList();
      expect(itens, ['Início', 'Mapa', 'Reportar', 'ONGs', 'Perfil']);

      await tester.tap(find.text('ONGs'));
      await tester.pumpAndSettle();
      expect(find.text('ONGS E ABRIGOS'), findsOneWidget);
    });
  });
}
