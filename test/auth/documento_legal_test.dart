import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pata_amiga/auth/screens/cadastro_screen.dart';
import 'package:pata_amiga/routes/app_router.dart';

void main() {
  testWidgets('cadastro abre a Política de Privacidade', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const RegisterScreen(),
        routes: {
          AppRoutes.terms: AppRoutesConfig.routes[AppRoutes.terms]!,
          AppRoutes.privacy: AppRoutesConfig.routes[AppRoutes.privacy]!,
        },
      ),
    );

    await tester.ensureVisible(find.text('Política de Privacidade'));
    await tester.tap(find.text('Política de Privacidade'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('O cadastro solicita nome, e-mail e telefone'),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Política de Privacidade'), findsWidgets);
    expect(
      find.textContaining('O cadastro solicita nome, e-mail e telefone'),
      findsOneWidget,
    );
  });

  testWidgets('cadastro abre os Termos de Uso', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const RegisterScreen(),
        routes: {
          AppRoutes.terms: AppRoutesConfig.routes[AppRoutes.terms]!,
          AppRoutes.privacy: AppRoutesConfig.routes[AppRoutes.privacy]!,
        },
      ),
    );

    await tester.ensureVisible(find.text('Termos de Uso'));
    await tester.tap(find.text('Termos de Uso'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Você é responsável pela exatidão'),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Termos de Uso'), findsWidgets);
    expect(
      find.textContaining('Você é responsável pela exatidão'),
      findsOneWidget,
    );
  });
}
