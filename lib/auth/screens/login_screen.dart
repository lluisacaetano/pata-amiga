// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo auth_components.dart: fundo, campos e botões das telas de entrada.
import 'auth_components.dart';
// Arquivo onboarding_screen.dart: navegação para o app depois do login.
import '../../telas/onboarding_screen.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../../tema/cores.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../../routes/route_names.dart';
// Arquivo mascaras.dart: máscara do campo de e-mail.
import '../../widgets/mascaras.dart';
// Arquivo usuario_provider.dart: início da sessão.
import '../../provider/usuario_provider.dart';

// Tela de login. Valida o formato do e-mail e se a senha foi preenchida,
// carrega o perfil salvo no aparelho para esse e-mail e segue para o app.
// A senha não é conferida, porque o app ainda não tem autenticação real
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _mostrarSenha = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        comVoltar: true,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthBrandMark(size: 64),
              const SizedBox(height: 2),
              Image.asset(
                'assets/desenhos/animais_login.png',
                height: 220,
                fit: BoxFit.contain,
                semanticLabel: 'Ilustração de um cachorro',
              ),
              const SizedBox(height: 3),
              Text(
                'Que bom te ver novamente!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: context.cores.principal,
                ),
              ),
              const SizedBox(height: 22),
              AuthField(
                label: 'E-mail',
                hint: 'Digite seu e-mail',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [MascaraDeEmail()],
                prefixIcon: Icons.mail_outline,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Informe seu e-mail.';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Digite um e-mail válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthField(
                label: 'Senha',
                hint: 'Digite sua senha',
                controller: _senhaController,
                prefixIcon: Icons.lock_outline,
                validator: (value) => value == null || value.isEmpty
                    ? 'Informe sua senha.'
                    : null,
                obscureText: !_mostrarSenha,
                suffixIcon: _mostrarSenha
                    ? Icons.visibility_off
                    : Icons.visibility,
                onSuffixPressed: () =>
                    setState(() => _mostrarSenha = !_mostrarSenha),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamed(AppRoutes.recoverPassword),
                  child: const Text('Esqueci a senha'),
                ),
              ),
              const SizedBox(height: 10),
              AuthButton(
                label: 'Entrar',
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  await context.read<UsuarioProvider>().iniciarSessao(
                    _emailController.text,
                  );
                  if (!context.mounted) return;
                  await navegarAposAutenticacao(context);
                },
              ),
              const SizedBox(height: 12),
              // Entrar com o Google: apenas visual, ainda sem integração
              AuthButton(
                label: '',
                primary: false,
                leading: const GoogleWordmark(),
                onPressed: () {},
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.register),
                  child: const Text('Não tem conta? Criar conta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
}
