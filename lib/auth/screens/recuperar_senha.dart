import 'package:flutter/material.dart';

import 'auth_components.dart';
import '../../tema/cores.dart';
import '../../widgets/mascaras.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _emailController = TextEditingController();

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
              'Informe o e-mail cadastrado para receber as instruções de redefinição.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                height: 1.4,
                color: context.cores.textoFraco,
              ),
            ),
            const SizedBox(height: 24),
            AuthField(
              label: 'E-mail',
              hint: 'Digite seu e-mail',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [MascaraDeEmail()],
              prefixIcon: Icons.mail_outline,
            ),
            const SizedBox(height: 20),
            AuthButton(label: 'Enviar link de recuperação', onPressed: () {}),
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
