import 'package:flutter/material.dart';

import 'auth/auth_router.dart';
import 'auth/screens/cadastro_screen.dart';
import 'auth/screens/login_screen.dart';
import 'auth/screens/recuperar_senha.dart';
import 'routes/app_router.dart';
import 'tema/cores.dart';
import 'telas/home_screen.dart';

void main() {
  runApp(const AplicativoPataAmiga());
}

class AplicativoPataAmiga extends StatelessWidget {
  const AplicativoPataAmiga({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pata Amiga',
      debugShowCheckedModeBanner: false,
      theme: temaPataAmiga(),
      home: const AuthRouter(),
      builder: (context, child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const RegisterScreen(),
        '/recuperacao': (context) => const RecoverPasswordScreen(),
        '/home': (context) => const SuaTelaHome(),
        ...AppRoutes.routes,
      },
    );
  }
}
