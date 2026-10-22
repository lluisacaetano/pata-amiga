import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pata_amiga/routes/route_names.dart';
import 'package:pata_amiga/telas/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingStorage', () {
    test('considera que o onboarding ainda não foi visto por padrão', () async {
      expect(await OnboardingStorage.jaViu(), isFalse);
    });

    test('persiste que o onboarding foi visto', () async {
      await OnboardingStorage.marcarComoVisto();

      expect(await OnboardingStorage.jaViu(), isTrue);
    });
  });

  group('navegarAposAutenticacao', () {
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

    testWidgets('abre o onboarding na primeira autenticação', (tester) async {
      await abrirDestino(tester);

      expect(find.text('Destino onboarding'), findsOneWidget);
      expect(find.text('Destino feed'), findsNothing);
    });

    testWidgets('abre o feed depois que o onboarding já foi visto', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_visto': true});

      await abrirDestino(tester);

      expect(find.text('Destino feed'), findsOneWidget);
      expect(find.text('Destino onboarding'), findsNothing);
    });
  });

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
