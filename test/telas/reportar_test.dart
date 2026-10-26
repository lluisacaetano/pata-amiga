// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter_test: ferramentas de teste de widgets e de unidade do Flutter.
import 'package:flutter_test/flutter_test.dart';
// Pacote geocoding: converte coordenadas em endereço e endereço em coordenadas.
import 'package:geocoding/geocoding.dart';
// Pacote geocoding_platform_interface: base do serviço de endereços falso.
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart'
    as pi;
// Pacote plugin_platform_interface: permite registrar implementações falsas.
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// Pacote image_picker_platform_interface: base para substituir a galeria.
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';
// Arquivo denuncia.dart: modelo da denúncia, protocolo e data por extenso.
import 'package:pata_amiga/modelos/denuncia.dart';
// Arquivo app_router.dart: rotas do app.
import 'package:pata_amiga/routes/app_router.dart';
// Arquivo denuncia_service.dart: serviço substituído pelo falso.
import 'package:pata_amiga/services/denuncia_service.dart';
// Arquivo minhas_denuncias.dart: lista das denúncias do aparelho.
import 'package:pata_amiga/telas/minhas_denuncias.dart';
// Arquivo reportar.dart: formulário de denúncia.
import 'package:pata_amiga/telas/reportar.dart';
// Arquivo barra_inferior.dart: barra de navegação com a opção Reportar.
import 'package:pata_amiga/widgets/barra_inferior.dart';

// Serviço de denúncias falso: grava na memória, como a API, e guarda o
// protocolo no aparelho
class _DenunciasFalsas extends DenunciaService {
  final gravadas = <Denuncia>[];

  @override
  Future<Denuncia> registrar(Denuncia denuncia) async {
    final comId = Denuncia.fromJson({
      ...denuncia.toJson(),
      'id': gravadas.length + 1,
    });
    gravadas.add(comId);
    await guardarProtocolo(comId.protocolo);
    return comId;
  }

  @override
  Future<List<Denuncia>> minhasDenuncias() async {
    final protocolos = await protocolosDoAparelho();
    return gravadas.where((d) => protocolos.contains(d.protocolo)).toList();
  }
}

// Galeria falsa que sempre devolve uma foto
class _GaleriaComUmaFoto extends ImagePickerPlatform {
  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async => [XFile('/tmp/denuncia.jpg')];
}

// Serviço de endereços falso: a busca não acha nada e o pino cai sempre na
// Praça Olegário Maciel, no Centro
class _EnderecoFalso extends pi.Geocoding with MockPlatformInterfaceMixin {
  _EnderecoFalso() : super.implementation(pi.GeocodingCreationParams());

  @override
  Future<List<pi.Location>> locationFromAddress(
    String address, {
    Locale? locale,
  }) async => [];

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    Locale? locale,
  }) async => [
    Placemark(
      thoroughfare: 'Praça Olegário Maciel',
      subLocality: 'Centro',
      locality: 'Formiga',
    ),
  ];
}

// Fábrica que entrega o serviço de endereços falso ao pacote geocoding
class _FabricaFalsa extends pi.GeocodingPlatformFactory
    with MockPlatformInterfaceMixin {
  @override
  pi.Geocoding createGeocoding(pi.GeocodingCreationParams params) =>
      _EnderecoFalso();
}

// Abre a tela informada numa janela alta, com as rotas do app e o serviço
// de endereços falso
Future<void> _abrir(WidgetTester tester, Widget tela) async {
  pi.GeocodingPlatformFactory.instance = _FabricaFalsa();
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final rotas = Map<String, WidgetBuilder>.from(AppRoutesConfig.routes)
    ..remove(AppRoutes.welcome);
  await tester.pumpWidget(MaterialApp(home: tela, routes: rotas));
  await tester.pumpAndSettle();
}

void main() {
  // Cada teste começa sem protocolos guardados no aparelho
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // O item Reportar da barra abre o formulário com o quadro da lei
  testWidgets('opção Reportar abre a tela de denúncia', (tester) async {
    await _abrir(
      tester,
      const Scaffold(
        body: Center(child: Text('Feed')),
        bottomNavigationBar: BarraInferior(),
      ),
    );
    await tester.tap(find.text('Reportar'));
    await tester.pumpAndSettle();

    expect(find.text('DENUNCIAR MAUS-TRATOS'), findsOneWidget);
    expect(find.text('Maus-tratos a animais é crime'), findsOneWidget);
    expect(find.text('Lei nº 9.605/1998, art. 32'), findsOneWidget);
  });

  // Sem os campos obrigatórios e sem foto, nada é enviado
  testWidgets('sem os obrigatórios, a denúncia não é registrada', (
    tester,
  ) async {
    final servico = _DenunciasFalsas();
    await _abrir(tester, ReportarScreen(servico: servico));

    await tester.tap(find.text('Registrar denúncia'));
    await tester.pumpAndSettle();

    // O erro aparece nos campos (organização, tipo e descrição), sem
    // SnackBar
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Campo obrigatório'), findsNWidgets(3));
    expect(find.text('Adicione pelo menos uma foto.'), findsOneWidget);
    expect(servico.gravadas, isEmpty);

    // O anonimato é uma escolha, ligada de início
    expect(find.text('Denunciar de forma anônima'), findsOneWidget);
  });

  // A denúncia anônima não envia nome nem telefone de quem denunciou
  test('a anônima não leva quem denunciou para a API', () {
    final denuncia = Denuncia(
      protocolo: 'PA-20261022-0001',
      tipo: TipoDeDenuncia.abandono,
      descricao: 'Cachorro amarrado sem água.',
      rua: 'Rua Pará de Minas',
      bairro: 'Centro',
      anonima: true,
      denuncianteNome: 'Dani Teste',
      denuncianteTelefone: '37999990000',
      registradaEm: DateTime(2026, 10, 22),
    );
    final json = denuncia.toJson();
    expect(json['denuncianteNome'], '');
    expect(json['denuncianteTelefone'], '');
    expect(denuncia.mensagemParaOCanal, contains('Denúncia anônima'));
    expect(denuncia.mensagemParaOCanal, contains('sigilo'));
    expect(denuncia.mensagemParaOCanal, isNot(contains('Dani Teste')));
    expect(Denuncia.fromJson(json).protocolo, 'PA-20261022-0001');
  });

  // O protocolo segue o formato PA-AAAAMMDD-NNNN
  test('o protocolo leva a data e quatro dígitos', () {
    expect(
      Denuncia.novoProtocolo(DateTime(2026, 10, 22)),
      matches(RegExp(r'^PA-20261022-\d{4}$')),
    );
  });

  // A denúncia registrada aparece em Minhas denúncias com a situação
  testWidgets('a denúncia registrada aparece em Minhas denúncias', (
    tester,
  ) async {
    final servico = _DenunciasFalsas();
    final registrada = await servico.registrar(
      Denuncia(
        protocolo: 'PA-20261022-0042',
        tipo: TipoDeDenuncia.mausTratos,
        descricao: 'Gato ferido.',
        rua: 'Rua Pará de Minas',
        bairro: 'Centro',
        fotos: const ['/tmp/denuncia.jpg'],
        registradaEm: DateTime(2026, 10, 22),
      ),
    );
    expect(registrada.situacao, SituacaoDaDenuncia.recebida);
    await _abrir(tester, MinhasDenuncias(servico: servico));
    expect(find.text('Protocolo PA-20261022-0042'), findsOneWidget);
    expect(find.text('Recebida'), findsOneWidget);
  });

  // A foto escolhida na galeria entra no formulário, com o botão de remover
  testWidgets('a foto entra pela galeria', (tester) async {
    ImagePickerPlatform.instance = _GaleriaComUmaFoto();
    await _abrir(tester, ReportarScreen(servico: _DenunciasFalsas()));
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Remover foto'), findsOneWidget);
  });

  // A data do registro aparece como hoje, ontem ou a data completa
  test('a data do registro sai como se fala', () {
    final agora = DateTime(2026, 10, 22, 18);
    expect(quandoFoi(DateTime(2026, 10, 22, 14, 19), agora), 'hoje às 14:19');
    expect(quandoFoi(DateTime(2026, 10, 21, 9, 5), agora), 'ontem às 09:05');
    expect(
      quandoFoi(DateTime(2026, 10, 2, 8, 0), agora),
      '02/10/2026 às 08:00',
    );
  });

  // A busca encontra pelo protocolo, ignora hífens e espaços e avisa quando
  // não acha
  testWidgets('a busca acha a denúncia pelo protocolo, sem hífen', (
    tester,
  ) async {
    final servico = _DenunciasFalsas();
    for (final (protocolo, tipo) in [
      ('PA-20261022-0042', TipoDeDenuncia.mausTratos),
      ('PA-20261022-7777', TipoDeDenuncia.abandono),
    ]) {
      await servico.registrar(
        Denuncia(
          protocolo: protocolo,
          tipo: tipo,
          descricao: 'Relato.',
          rua: 'Rua Pará de Minas',
          bairro: 'Centro',
          registradaEm: DateTime(2026, 10, 22),
        ),
      );
    }
    await _abrir(tester, MinhasDenuncias(servico: servico));

    await tester.enterText(find.byType(TextField), '7777');
    await tester.pumpAndSettle();
    expect(find.text('Protocolo PA-20261022-7777'), findsOneWidget);
    expect(find.text('Protocolo PA-20261022-0042'), findsNothing);

    await tester.enterText(find.byType(TextField), 'pa 20261022 0042');
    await tester.pumpAndSettle();
    expect(find.text('Protocolo PA-20261022-0042'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '9999');
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma denúncia com esse protocolo.'), findsOneWidget);
  });

  // Tocar na denúncia abre os detalhes com o relato e o aviso de anonimato
  testWidgets('tocar na denúncia abre os detalhes', (tester) async {
    final servico = _DenunciasFalsas();
    await servico.registrar(
      Denuncia(
        protocolo: 'PA-20261022-0042',
        tipo: TipoDeDenuncia.negligencia,
        descricao: 'Cachorro sem água no quintal.',
        rua: 'Rua Pará de Minas',
        bairro: 'Centro',
        anonima: true,
        registradaEm: DateTime(2026, 10, 22),
      ),
    );
    await _abrir(tester, MinhasDenuncias(servico: servico));
    await tester.tap(find.text('Protocolo PA-20261022-0042'));
    await tester.pumpAndSettle();

    expect(find.text('DETALHES'), findsOneWidget);
    expect(find.text('NEGLIGÊNCIA'), findsOneWidget);
    expect(find.text('Cachorro sem água no quintal.'), findsOneWidget);
    expect(find.text('Rua Pará de Minas'), findsOneWidget);
    expect(
      find.text(
        'Denúncia anônima: o registro não inclui o nome nem o telefone de quem denunciou.',
      ),
      findsOneWidget,
    );
  });
}
