import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pata_amiga/dados/animais_mock.dart';
import 'package:pata_amiga/estado/estado_pata_amiga.dart';
import 'package:pata_amiga/modelos/animal.dart';
import 'package:pata_amiga/routes/app_router.dart';

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
          routes: AppRoutesConfig.routes,
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
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(find.text('Esta tela entra em uma próxima sprint.'), findsOneWidget);

    await tester.tap(find.byTooltip('Cadastrar animal'));
    await tester.pumpAndSettle();
    expect(find.text('Cadastrar animal'), findsOneWidget);
  });
}
