import 'package:flutter_test/flutter_test.dart';

import 'package:pata_amiga/main.dart';

void main() {
  testWidgets('o aplicativo abre no feed de adoção', (tester) async {
    await tester.pumpWidget(const AplicativoPataAmiga());

    expect(find.text('adoção'), findsOneWidget);
    expect(find.text('pesquisar'), findsOneWidget);
  });
}
