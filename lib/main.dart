import 'package:flutter/material.dart';
import 'provider/usuario_provider.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'tema/cores.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UsuarioProvider(),
      child: const AplicativoPataAmiga(),
    ),
  );
}

class AplicativoPataAmiga extends StatelessWidget {
  const AplicativoPataAmiga({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pata Amiga',
      debugShowCheckedModeBanner: false,
      theme: temaPataAmiga(),
      initialRoute: AppRoutes.feed,
      routes: AppRoutes.routes,
    );
  }
}