// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo auth_components.dart: fundo, logotipo e botões das telas de entrada.
import 'auth_components.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../../routes/route_names.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../../tema/cores.dart';

// Tela de boas-vindas de quem ainda não tem sessão: a marca, o slogan e os
// caminhos para entrar ou criar conta
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
                  // A patinha fica atrás do nome e da ilustração dos animais
                  const Positioned(top: 0, child: AuthBrandMark(size: 68)),

                  Positioned(
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
                        color: context.cores.principal,
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
            Text(
              'Encontre um novo melhor amigo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
                color: context.cores.textoFraco,
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
