import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pata_amiga/auth/screens/de_volta_screen.dart';
import 'package:pata_amiga/dados/animais_mock.dart';
import 'package:pata_amiga/estado/estado_pata_amiga.dart';
import 'package:pata_amiga/modelos/animal.dart';
import 'package:pata_amiga/provider/usuario_provider.dart';
import 'package:pata_amiga/routes/app_router.dart';
import 'package:pata_amiga/services/animal_service.dart';
import 'package:pata_amiga/telas/feed_adocao.dart';
import 'package:pata_amiga/widgets/barra_inferior.dart';

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
}
