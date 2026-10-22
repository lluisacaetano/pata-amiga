import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pata_amiga/estado/estado_pata_amiga.dart';
import 'package:pata_amiga/main.dart';
import 'package:pata_amiga/provider/preferencias_aplicativo_provider.dart';
import 'package:pata_amiga/provider/usuario_provider.dart';
import 'package:pata_amiga/routes/app_router.dart';
import 'package:pata_amiga/telas/configuracoes_acessibilidade.dart';
import 'package:pata_amiga/telas/configuracoes_aparencia.dart';
import 'package:pata_amiga/telas/perfil_usuario.dart';
import 'package:pata_amiga/tema/cores.dart';

Widget _aplicativoDeTeste(
  PreferenciasAplicativoProvider preferencias,
  Widget tela,
) => ChangeNotifierProvider.value(
  value: preferencias,
  child: Consumer<PreferenciasAplicativoProvider>(
    builder: (context, preferencias, _) => MaterialApp(
      theme: temaPataAmiga(),
      darkTheme: temaPataAmiga(brilho: Brightness.dark),
      themeMode: switch (preferencias.tema) {
        PreferenciaTema.claro => ThemeMode.light,
        PreferenciaTema.escuro => ThemeMode.dark,
        PreferenciaTema.sistema => ThemeMode.system,
      },
      home: tela,
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('carrega e persiste tema e tamanho do texto', () async {
    final preferencias = PreferenciasAplicativoProvider();
    await preferencias.carregar();
    await preferencias.definirTema(PreferenciaTema.escuro);
    await preferencias.definirTamanhoTexto(TamanhoTexto.extragrande);

    final restauradas = PreferenciasAplicativoProvider();
    await restauradas.carregar();

    expect(restauradas.tema, PreferenciaTema.escuro);
    expect(restauradas.tamanhoTexto, TamanhoTexto.extragrande);
    expect(restauradas.escalaTexto, 1.4);
  });

  testWidgets('aplica acessibilidade à árvore inteira do aplicativo', (
    tester,
  ) async {
    final preferencias = PreferenciasAplicativoProvider();
    await preferencias.carregar();
    await preferencias.definirTamanhoTexto(TamanhoTexto.grande);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UsuarioProvider(),
        child: ChangeNotifierProvider.value(
          value: preferencias,
          child: const AplicativoPataAmiga(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final contexto = tester.element(find.text('Pata Amiga'));
    final media = MediaQuery.of(contexto);
    expect(media.textScaler.scale(10), 12);
    expect(
      Theme.of(contexto).colorScheme.primary,
      Cores.principal,
    );
  });

  testWidgets('a tela de aparência troca o tema globalmente', (tester) async {
    final preferencias = PreferenciasAplicativoProvider();
    await preferencias.carregar();
    await tester.pumpWidget(
      _aplicativoDeTeste(preferencias, const ConfiguracoesAparencia()),
    );

    expect(
      Theme.of(tester.element(find.text('APARÊNCIA'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.text('Modo escuro'));
    await tester.pumpAndSettle();

    expect(preferencias.tema, PreferenciaTema.escuro);
    expect(
      Theme.of(tester.element(find.text('APARÊNCIA'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('a tela de acessibilidade salva tamanho e controles', (
    tester,
  ) async {
    final preferencias = PreferenciasAplicativoProvider();
    await preferencias.carregar();
    await tester.pumpWidget(
      _aplicativoDeTeste(preferencias, const ConfiguracoesAcessibilidade()),
    );

    await tester.tap(find.text('Grande'));
    await tester.pumpAndSettle();

    expect(preferencias.tamanhoTexto, TamanhoTexto.grande);
    expect(find.text('Alto contraste'), findsNothing);
    expect(find.text('Reduzir animações'), findsNothing);
  });

  testWidgets('perfil abre telas independentes de configuração', (
    tester,
  ) async {
    final preferencias = PreferenciasAplicativoProvider();
    await preferencias.carregar();
    final estado = EstadoPataAmiga();
    final rotas = Map<String, WidgetBuilder>.of(AppRoutesConfig.routes)
      ..remove(AppRoutes.welcome);
    addTearDown(estado.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UsuarioProvider(),
        child: ChangeNotifierProvider.value(
          value: preferencias,
          child: PataAmigaScope(
            notifier: estado,
            child: MaterialApp(
              theme: temaPataAmiga(),
              routes: rotas,
              home: const PerfilUsuario(),
            ),
          ),
        ),
      ),
    );

    // As opções ficam no menu de três pontinhos, no canto
    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aparência'));
    await tester.pumpAndSettle();
    expect(find.text('Seguir sistema'), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acessibilidade'));
    await tester.pumpAndSettle();
    expect(find.text('Tamanho do texto'), findsOneWidget);
  });
}
