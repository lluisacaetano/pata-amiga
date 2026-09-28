import 'package:flutter/material.dart';

import 'auth_components.dart';
import '../../routes/route_names.dart';

class BoasVindasScreen extends StatelessWidget {
  const BoasVindasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBrandMark(size: 68),
            const SizedBox(height: 20),
            Image.asset(
              'assets/desenhos/cachorro_lingua.png',
              height: 220,
              fit: BoxFit.contain,
              semanticLabel: 'Ilustração de um cachorro',
            ),
            const SizedBox(height: 20),
            const Text(
              'Pata Amiga',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xFF24543A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Encontre um novo melhor amigo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF454B47),
              ),
            ),
            const SizedBox(height: 28),
            AuthButton(
              label: 'Entrar',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
            ),
            const SizedBox(height: 12),
            AuthButton(
              label: 'Criar conta',
              primary: false,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.register),
            ),
          ],
        ),
      ),
    );
  }
}
