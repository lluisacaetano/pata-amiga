import 'dart:async';

import 'package:flutter/material.dart';
import 'provider/usuario_provider.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'estado/estado_pata_amiga.dart';
import 'tema/cores.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => UsuarioProvider(),
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
