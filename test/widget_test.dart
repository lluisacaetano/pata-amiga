import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pata_amiga/main.dart';

void main() {
  testWidgets('o aplicativo abre na aba de adoção', (tester) async {
    await tester.pumpWidget(const AplicativoPataAmiga());

    expect(find.text('DORA'), findsOneWidget);
    // Bidu está cadastrado como perdido, então não aparece nesta aba
    expect(find.text('BIDU'), findsNothing);
  });

  testWidgets('trocar de aba recarrega o feed', (tester) async {
    await tester.pumpWidget(const AplicativoPataAmiga());

    await tester.tap(find.text('Perdidos'));
    await tester.pump();

    expect(find.text('BIDU'), findsOneWidget);
    expect(find.text('DORA'), findsNothing);
  });

  testWidgets('curtir preenche o coração do card', (tester) async {
    await tester.pumpWidget(const AplicativoPataAmiga());

    expect(find.byIcon(Icons.favorite), findsNothing);

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
