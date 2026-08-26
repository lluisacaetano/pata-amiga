import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pata_amiga/main.dart';

void main() {
  testWidgets('o feed abre na aba de adoção', (tester) async {
    await tester.pumpWidget(const AplicativoPataAmiga());

    expect(find.text('DORA'), findsOneWidget);
    expect(find.text('THOR'), findsOneWidget);
    // Bidu está cadastrado como perdido, então não aparece nesta aba.
    expect(find.text('BIDU'), findsNothing);
  });

  testWidgets('curtir preenche o coração do card', (tester) async {
    await tester.pumpWidget(const AplicativoPataAmiga());

    expect(find.byIcon(Icons.favorite), findsNothing);

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('trocar de aba recarrega o feed', (tester) async {
    await tester.pumpWidget(const AplicativoPataAmiga());

    await tester.tap(find.text('perdidos'));
    await tester.pump();

    expect(find.text('BIDU'), findsOneWidget);
    expect(find.text('DORA'), findsNothing);
  });

  testWidgets('tocar no card abre os detalhes do animal', (tester) async {
    await tester.pumpWidget(const AplicativoPataAmiga());

    await tester.tap(find.text('DORA'));
    await tester.pumpAndSettle();

    expect(find.text('disponível'), findsOneWidget);
    expect(find.text('ESPÉCIE:'), findsOneWidget);

    // O botão fica no fim da ficha, então é preciso rolar até ele.
    await tester.scrollUntilVisible(
      find.text('CONVERSAR NO WHATSAPP'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('CONVERSAR NO WHATSAPP'), findsOneWidget);
  });
}
