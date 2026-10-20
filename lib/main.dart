import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'provider/usuario_provider.dart';

import 'package:provider/provider.dart';

import 'routes/app_router.dart';
import 'estado/estado_pata_amiga.dart';
import 'tema/cores.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final usuarioProvider = UsuarioProvider();
  await usuarioProvider.restaurarSessao();
  runApp(
    ChangeNotifierProvider.value(
      value: usuarioProvider,
      child: const AplicativoPataAmiga(),
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
    return PataAmigaScope(
      notifier: _estado,
      child: MaterialApp(
        title: 'Pata Amiga',
        debugShowCheckedModeBanner: false,
        theme: temaPataAmiga(),
        // Os textos prontos do Flutter (calendário, botões de diálogo) em
        // português, como o resto do app
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: AppRoutes.welcome,
        builder: (context, child) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
        routes: AppRoutesConfig.routes,
      ),
    );
  }
}
