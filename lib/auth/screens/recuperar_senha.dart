// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo auth_components.dart: fundo, logotipo e botões das telas de entrada.
import 'auth_components.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../../routes/route_names.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../../tema/cores.dart';

// Tela de "Esqueci a senha". A conta existe só neste aparelho e o app não
// tem servidor de e-mail, então não há link de recuperação: a tela explica
// isso e oferece criar a conta de novo com o mesmo e-mail, o que define uma
// senha nova e mantém os cadastros e curtidas guardados no aparelho
class RecoverPasswordScreen extends StatelessWidget {
  const RecoverPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBrandMark(size: 64),
            const SizedBox(height: 16),
            Text(
              'Recuperar senha',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: context.cores.principal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sua conta fica guardada só neste aparelho, por isso não '
              'enviamos link por e-mail. Para definir uma senha nova, crie a '
              'conta de novo com o mesmo e-mail.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                height: 1.4,
                color: context.cores.textoFraco,
              ),
            ),
            const SizedBox(height: 24),
            AuthButton(
              label: 'Criar a conta de novo',
              onPressed: () =>
                  Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.register),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar para o login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
