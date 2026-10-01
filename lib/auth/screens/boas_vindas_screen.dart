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
            SizedBox(
              height: 210,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Pata ATRÁS
                  const Positioned(top: 0, child: AuthBrandMark(size: 68)),

                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Text(
                      'Pata Amiga',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 59,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF24543A),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/desenhos/animais_olhando.png',
                      height: 120,
                      fit: BoxFit.contain,
                      semanticLabel:
                          'Cães e gatos apoiados na marca Pata Amiga',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height:12),
            const Text(
              'Encontre um novo melhor amigo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
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
