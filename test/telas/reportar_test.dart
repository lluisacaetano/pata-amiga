import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart'
    as pi;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pata_amiga/modelos/denuncia.dart';
import 'package:pata_amiga/routes/app_router.dart';
import 'package:pata_amiga/services/denuncia_service.dart';
import 'package:pata_amiga/telas/minhas_denuncias.dart';
import 'package:pata_amiga/telas/reportar.dart';
import 'package:pata_amiga/widgets/barra_inferior.dart';

// Serviço falso: grava na memória, como a API, e guarda o protocolo
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

class _GaleriaComUmaFoto extends ImagePickerPlatform {
  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async => [XFile('/tmp/denuncia.jpg')];
}

// O serviço de endereços do aparelho, falso: o pino cai sempre no Centro
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

class _FabricaFalsa extends pi.GeocodingPlatformFactory
    with MockPlatformInterfaceMixin {
  @override
  pi.Geocoding createGeocoding(pi.GeocodingCreationParams params) =>
      _EnderecoFalso();
}

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
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  testWidgets('sem os obrigatórios, a denúncia não é registrada', (
    tester,
  ) async {
    final servico = _DenunciasFalsas();
    await _abrir(tester, ReportarScreen(servico: servico));

    await tester.tap(find.text('Registrar denúncia'));
    await tester.pumpAndSettle();

    expect(
      find.text('Preencha os campos obrigatórios marcados em vermelho.'),
      findsOneWidget,
    );
    expect(find.text('Campo obrigatório'), findsNWidgets(2));
    expect(find.text('Adicione pelo menos uma foto.'), findsOneWidget);
    expect(servico.gravadas, isEmpty);

    // Sem nome e telefone no perfil, identificada não sai; anônima, sim
    const semContato =
        'Seu perfil está sem nome ou telefone. Complete o perfil ou envie '
        'sem se identificar.';
    expect(find.text(semContato), findsOneWidget);
    await tester.tap(find.text('Enviar sem me identificar'));
    await tester.pumpAndSettle();
    expect(find.text(semContato), findsNothing);
  });

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
    expect(denuncia.mensagemParaOCanal, isNot(contains('Dani Teste')));
    expect(Denuncia.fromJson(json).protocolo, 'PA-20261022-0001');
  });

  test('o protocolo leva a data e quatro dígitos', () {
    expect(
      Denuncia.novoProtocolo(DateTime(2026, 10, 22)),
      matches(RegExp(r'^PA-20261022-\d{4}$')),
    );
  });

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

  testWidgets('a foto entra pela galeria', (tester) async {
    ImagePickerPlatform.instance = _GaleriaComUmaFoto();
    await _abrir(tester, ReportarScreen(servico: _DenunciasFalsas()));
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Remover foto'), findsOneWidget);
  });
}
