import 'package:flutter/material.dart';

import 'auth_components.dart';
import '../../routes/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _aceitouTermos = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmacao = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBrandMark(size: 58),
            const SizedBox(height: 10),
            const Text(
              'Criar conta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF24543A),
              ),
            ),
            const SizedBox(height: 18),
            AuthField(
              label: 'Nome',
              hint: 'Digite seu nome completo',
              controller: _nomeController,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            AuthField(
              label: 'E-mail',
              hint: 'Digite seu e-mail',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline,
            ),
            const SizedBox(height: 12),
            AuthField(
              label: 'Telefone/WhatsApp',
              hint: 'Digite seu telefone',
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 12),
            AuthField(
              label: 'Senha',
              hint: 'Crie uma senha',
              controller: _senhaController,
              prefixIcon: Icons.lock_outline,
              obscureText: !_mostrarSenha,
              suffixIcon: _mostrarSenha
                  ? Icons.visibility_off
                  : Icons.visibility,
              onSuffixPressed: () =>
                  setState(() => _mostrarSenha = !_mostrarSenha),
            ),
            const SizedBox(height: 12),
            AuthField(
              label: 'Confirmar senha',
              hint: 'Digite a senha novamente',
              controller: _confirmarSenhaController,
              prefixIcon: Icons.lock_outline,
              obscureText: !_mostrarConfirmacao,
              suffixIcon: _mostrarConfirmacao
                  ? Icons.visibility_off
                  : Icons.visibility,
              onSuffixPressed: () =>
                  setState(() => _mostrarConfirmacao = !_mostrarConfirmacao),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Checkbox(
                    value: _aceitouTermos,
                    activeColor: const Color(0xFF3F7D58),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (value) {
                      setState(() => _aceitouTermos = value ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Text(
                      'Li e aceito os Termos de Uso e a Política de Privacidade',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AuthButton(
              label: 'Criar conta',
              onPressed: _aceitouTermos
                  ? () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.feed, (route) => false)
                  : null,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Já tem conta? Entrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }
}
