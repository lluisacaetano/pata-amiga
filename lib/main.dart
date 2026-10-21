import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'provider/usuario_provider.dart';
import 'provider/preferencias_aplicativo_provider.dart';

import 'package:provider/provider.dart';

import 'routes/app_router.dart';
import 'estado/estado_pata_amiga.dart';
import 'tema/cores.dart';

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
        theme: temaPataAmiga(altoContraste: preferencias.altoContraste),
        darkTheme: temaPataAmiga(
          brilho: Brightness.dark,
          altoContraste: preferencias.altoContraste,
        ),
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
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(
                media.textScaler.scale(1) * preferencias.escalaTexto,
              ),
              highContrast:
                  media.highContrast || preferencias.altoContraste,
              disableAnimations:
                  media.disableAnimations || preferencias.reduzirAnimacoes,
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
