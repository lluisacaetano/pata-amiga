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
// Arquivo mascaras.dart: máscara e validador do campo de e-mail.
import '../../widgets/mascaras.dart';
// Arquivo usuario_provider.dart: conferência da conta e início da sessão.
import '../../provider/usuario_provider.dart';

// Tela de login. Confere o e-mail e a senha com a conta salva neste
// aparelho; o erro aparece no próprio campo (conta inexistente no e-mail,
// senha incorreta na senha). Com tudo certo, segue para o app. Aberta depois
// da recuperação de senha, já traz o e-mail e o aviso da senha nova
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
  bool _entrando = false;
  // Erros que só se sabe depois de consultar a conta salva
  String? _erroDoEmail;
  String? _erroDaSenha;
  // Verdadeiro quando o login foi aberto logo depois de redefinir a senha
  bool _senhaRedefinida = false;
  bool _leuArgumento = false;

  // Vindo da recuperação de senha, a rota traz o e-mail da conta: o campo é
  // preenchido e o aviso da senha nova aparece acima dele
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_leuArgumento) return;
    _leuArgumento = true;
    final email = ModalRoute.of(context)?.settings.arguments;
    if (email is String && email.isNotEmpty) {
      _emailController.text = email;
      _senhaRedefinida = true;
    }
  }

  Future<void> _entrar() async {
    setState(() {
      _erroDoEmail = null;
      _erroDaSenha = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _entrando = true);
    final resultado = await context.read<UsuarioProvider>().entrar(
      _emailController.text,
      _senhaController.text,
    );
    if (!mounted) return;
    switch (resultado) {
      case ResultadoDoLogin.semConta:
        _erroDoEmail = 'Nenhuma conta com este e-mail neste aparelho.';
      case ResultadoDoLogin.senhaIncorreta:
        _erroDaSenha = 'Senha incorreta.';
      case ResultadoDoLogin.entrou:
        await navegarAposAutenticacao(context);
        return;
    }
    setState(() => _entrando = false);
    _formKey.currentState!.validate();
  }

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
              if (_senhaRedefinida) ...[
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.cores.principalClara,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: context.cores.principal,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Senha redefinida. Entre com a senha nova.',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: context.cores.texto,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AuthField(
                label: 'E-mail',
                hint: 'Digite seu e-mail',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [MascaraDeEmail()],
                prefixIcon: Icons.mail_outline,
                validator: (value) => validarEmail(value) ?? _erroDoEmail,
              ),
              const SizedBox(height: 16),
              AuthField(
                label: 'Senha',
                hint: 'Digite sua senha',
                controller: _senhaController,
                prefixIcon: Icons.lock_outline,
                validator: (value) => value == null || value.isEmpty
                    ? 'Informe sua senha.'
                    : _erroDaSenha,
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
                label: _entrando ? 'Entrando…' : 'Entrar',
                carregando: _entrando,
                onPressed: _entrando ? null : _entrar,
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
