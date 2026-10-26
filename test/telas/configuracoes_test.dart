// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter_test: ferramentas de teste de widgets e de unidade do Flutter.
import 'package:flutter_test/flutter_test.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';
// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';

// Arquivo estado_pata_amiga.dart: estado compartilhado exigido pelo perfil.
import 'package:pata_amiga/estado/estado_pata_amiga.dart';
// Arquivo main.dart: o aplicativo completo.
import 'package:pata_amiga/main.dart';
// Arquivo preferencias_aplicativo_provider.dart: tema e tamanho do texto.
import 'package:pata_amiga/provider/preferencias_aplicativo_provider.dart';
// Arquivo usuario_provider.dart: sessão e perfil da pessoa.
import 'package:pata_amiga/provider/usuario_provider.dart';
// Arquivo app_router.dart: rotas do app.
import 'package:pata_amiga/routes/app_router.dart';
// Arquivo configuracoes_acessibilidade.dart: tela de acessibilidade.
import 'package:pata_amiga/telas/configuracoes_acessibilidade.dart';
// Arquivo configuracoes_aparencia.dart: tela de aparência.
import 'package:pata_amiga/telas/configuracoes_aparencia.dart';
// Arquivo perfil_usuario.dart: tela Meu perfil, com o menu de opções.
import 'package:pata_amiga/telas/perfil_usuario.dart';
// Arquivo cores.dart: tema e paleta do app.
import 'package:pata_amiga/tema/cores.dart';

// App mínimo que aplica o tema escolhido nas preferências, com a tela
// informada como inicial
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

  // Cada teste começa com as preferências do aparelho vazias
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Tema e tamanho do texto salvos voltam ao carregar de novo
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

  // O tamanho do texto vale para o app inteiro, junto com o tema
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
    expect(Theme.of(contexto).colorScheme.primary, Cores.principal);
  });

  // Escolher Modo escuro na Aparência troca o tema do app
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

  // A Acessibilidade salva o tamanho do texto e não mostra opções sem efeito
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

  // O menu do perfil abre as telas de Aparência e de Acessibilidade
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

    // As opções ficam no menu de três pontos da barra superior
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
