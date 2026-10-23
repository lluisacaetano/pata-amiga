// Biblioteca dart:async: unawaited, para carregar os curtidos sem esperar.
import 'dart:async';

// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter_localizations: componentes do Flutter em português.
import 'package:flutter_localizations/flutter_localizations.dart';

// Arquivo usuario_provider.dart: sessão e perfil da pessoa logada.
import 'provider/usuario_provider.dart';
// Arquivo preferencias_aplicativo_provider.dart: tema e tamanho do texto.
import 'provider/preferencias_aplicativo_provider.dart';

// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo app_router.dart: tabela de rotas e nomes das rotas.
import 'routes/app_router.dart';
// Arquivo estado_pata_amiga.dart: estado compartilhado do app.
import 'estado/estado_pata_amiga.dart';
// Arquivo cores.dart: tema claro e escuro do app.
import 'tema/cores.dart';

// Restaura a sessão e as preferências salvas antes do primeiro quadro, para
// o app já abrir com a conta, o tema e o tamanho de texto certos
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final usuarioProvider = UsuarioProvider();
  final preferencias = PreferenciasAplicativoProvider();
  await usuarioProvider.restaurarSessao();
  await preferencias.carregar();
  runApp(
    ChangeNotifierProvider.value(
      value: usuarioProvider,
      child: ChangeNotifierProvider.value(
        value: preferencias,
        child: const AplicativoPataAmiga(),
      ),
    ),
  );
}

// Raiz do app: cria o estado compartilhado (animais, curtidos, ONGs) e
// aplica tema, idioma, rotas e a escala de texto escolhida pela pessoa
class AplicativoPataAmiga extends StatefulWidget {
  const AplicativoPataAmiga({super.key});

  @override
  State<AplicativoPataAmiga> createState() => _AplicativoPataAmigaState();
}

class _AplicativoPataAmigaState extends State<AplicativoPataAmiga> {
  late final EstadoPataAmiga _estado;

  @override
  void initState() {
    super.initState();
    _estado = EstadoPataAmiga();
    unawaited(_estado.carregarCurtidos());
  }

  @override
  void dispose() {
    _estado.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferencias = context.watch<PreferenciasAplicativoProvider>();
    return PataAmigaScope(
      notifier: _estado,
      child: MaterialApp(
        title: 'Pata Amiga',
        debugShowCheckedModeBanner: false,
        theme: temaPataAmiga(),
        darkTheme: temaPataAmiga(brilho: Brightness.dark),
        themeMode: switch (preferencias.tema) {
          PreferenciaTema.claro => ThemeMode.light,
          PreferenciaTema.escuro => ThemeMode.dark,
          PreferenciaTema.sistema => ThemeMode.system,
        },
        // Os textos prontos do Flutter (calendário, botões de diálogo) em
        // português, como o resto do app
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: AppRoutes.welcome,
        // Multiplica a escala de texto do sistema pela escolhida em
        // Acessibilidade e limita a largura a 480, para o layout de celular
        // não esticar em telas largas
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(
                media.textScaler.scale(1) * preferencias.escalaTexto,
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: child,
              ),
            ),
          );
        },
        routes: AppRoutesConfig.routes,
      ),
    );
  }
}
