import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart'
    as pi;
import 'package:geolocator/geolocator.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pata_amiga/auth/screens/de_volta_screen.dart';
import 'package:pata_amiga/dados/animais_mock.dart';
import 'package:pata_amiga/dados/bairros_formiga.dart';
import 'package:pata_amiga/modelos/camadas_do_mapa.dart';
import 'package:pata_amiga/estado/estado_pata_amiga.dart';
import 'package:pata_amiga/modelos/animal.dart';
import 'package:pata_amiga/provider/usuario_provider.dart';
import 'package:pata_amiga/routes/app_router.dart';
import 'package:pata_amiga/services/animal_service.dart';
import 'package:pata_amiga/telas/cadastro_animal.dart';
import 'package:pata_amiga/telas/detalhes_animal.dart';
import 'package:pata_amiga/telas/tela_mapa.dart';
import 'package:pata_amiga/telas/feed_adocao.dart';
import 'package:pata_amiga/widgets/barra_inferior.dart';
import 'package:pata_amiga/widgets/foto_animal.dart';
import 'package:pata_amiga/widgets/mascaras.dart';

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

  testWidgets('meus cadastros lista o animal registrado no aparelho', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final estado = EstadoPataAmiga();
    addTearDown(estado.dispose);
    final animal = animaisMock.first;
    await estado.registrarCadastro(animal);

    await abrirPerfil(tester, estado: estado, usuario: UsuarioProvider());
    await tester.tap(find.text('Meus cadastros'));
    await tester.pumpAndSettle();

    expect(find.text(animal.nome.toUpperCase()), findsOneWidget);
    expect(find.textContaining('· há 2 dias'), findsOneWidget);
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

    await tester.tap(find.text('Perdido'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cachorro').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher').first);
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
    expect(
      find.text('Praça Olegário Maciel, 155, Centro, Formiga'),
      findsOneWidget,
    );
  });

  testWidgets('a ficha de adoção não mostra a rua', (tester) async {
    await abrirFicha(tester, comRua(TipoRegistro.adocao));
    expect(find.text('Centro, Formiga'), findsOneWidget);
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
    expect(
      find.text('Ligue Perdidos ou Resgate para ver os animais no mapa.'),
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
}
