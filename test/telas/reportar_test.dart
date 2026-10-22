import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pata_amiga/routes/app_router.dart';
import 'package:pata_amiga/telas/reportar.dart';
import 'package:pata_amiga/widgets/barra_inferior.dart';

void main() {
  testWidgets('opção Reportar abre a tela de denúncia', (tester) async {
    final rotas = Map<String, WidgetBuilder>.from(AppRoutesConfig.routes)
      ..remove(AppRoutes.welcome);
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: Center(child: Text('Feed')),
          bottomNavigationBar: BarraInferior(),
        ),
        routes: rotas,
      ),
    );

    await tester.tap(find.text('Reportar'));
    await tester.pumpAndSettle();

    expect(find.text('Denunciar situação'), findsOneWidget);
    expect(find.text('Tipo de denúncia'), findsOneWidget);
  });

  testWidgets('campos obrigatórios apresentam erros claros', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportarScreen()));

    final botao = find.text('Enviar denúncia');
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    await tester.tap(botao);
    await tester.pumpAndSettle();

    expect(find.text('Selecione o tipo de denúncia.'), findsOneWidget);
    expect(find.text('Descreva o que aconteceu.'), findsOneWidget);
    expect(
      find.text('Informe o endereço ou local aproximado.'),
      findsOneWidget,
    );
    expect(find.textContaining('Nenhuma denúncia foi enviada'), findsNothing);
  });

  testWidgets('formulário válido não afirma que a denúncia foi salva', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReportarScreen()));

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abandono').last);
    await tester.pumpAndSettle();

    final descricao = find.byKey(const Key('descricao-denuncia'));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.enterText(descricao, 'Animal deixado sem água.');

    final local = find.byKey(const Key('local-denuncia'));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    await tester.enterText(local, 'Rua das Flores, Centro.');

    final botao = find.text('Enviar denúncia');
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    await tester.tap(botao);
    await tester.pump();

    expect(
      find.text(
        'O envio ainda não está disponível. '
        'Nenhuma denúncia foi enviada ou salva.',
      ),
      findsOneWidget,
    );
  });
}
