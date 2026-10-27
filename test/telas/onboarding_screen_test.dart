// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter_test: ferramentas de teste de widgets e de unidade do Flutter.
import 'package:flutter_test/flutter_test.dart';
// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';

// Arquivo route_names.dart: nomes das rotas de navegação.
import 'package:pata_amiga/routes/route_names.dart';
// Arquivo onboarding_screen.dart: apresentação inicial e seu registro.
import 'package:pata_amiga/telas/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Cada teste começa com o armazenamento do aparelho vazio
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Registro, no aparelho, de que a apresentação já foi vista
  group('OnboardingStorage', () {
    // Sem registro, a apresentação conta como não vista
    test('considera que o onboarding ainda não foi visto por padrão', () async {
      expect(await OnboardingStorage.jaViu(), isFalse);
    });

    // Marcar como visto fica gravado no aparelho
    test('persiste que o onboarding foi visto', () async {
      await OnboardingStorage.marcarComoVisto();

      expect(await OnboardingStorage.jaViu(), isTrue);
    });
  });

  // Destino depois do login: apresentação na primeira vez, feed depois
  group('navegarAposAutenticacao', () {
    // Toca num botão que chama a navegação pós-login e espera o destino
    Future<void> abrirDestino(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => navegarAposAutenticacao(context),
                child: const Text('Continuar'),
              ),
            ),
          ),
          routes: {
            AppRoutes.onboarding: (_) =>
                const Scaffold(body: Text('Destino onboarding')),
            AppRoutes.feed: (_) => const Scaffold(body: Text('Destino feed')),
          },
        ),
      );
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
    }

    // Na primeira entrada, o destino é a apresentação
    testWidgets('abre o onboarding na primeira autenticação', (tester) async {
      await abrirDestino(tester);

      expect(find.text('Destino onboarding'), findsOneWidget);
      expect(find.text('Destino feed'), findsNothing);
    });

    // Com a apresentação já vista, o destino é o feed
    testWidgets('abre o feed depois que o onboarding já foi visto', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_visto': true});

      await abrirDestino(tester);

      expect(find.text('Destino feed'), findsOneWidget);
      expect(find.text('Destino onboarding'), findsNothing);
    });
  });

  // Pular a apresentação grava que ela foi vista e encerra a tela
  testWidgets('pular marca o onboarding como visto e chama onFinish', (
    tester,
  ) async {
    var finalizado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(onFinish: () => finalizado = true),
      ),
    );

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    expect(finalizado, isTrue);
    expect(await OnboardingStorage.jaViu(), isTrue);
  });
}
