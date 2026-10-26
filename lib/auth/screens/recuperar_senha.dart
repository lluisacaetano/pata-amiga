// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo auth_components.dart: fundo, logotipo, campos e botões das telas de
// entrada.
import 'auth_components.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../../tema/cores.dart';
// Arquivo mascaras.dart: máscaras e validador de e-mail e telefone.
import '../../widgets/mascaras.dart';
// Arquivo usuario_provider.dart: redefinição da senha da conta.
import '../../provider/usuario_provider.dart';

// Tela de "Esqueci a senha". A conta existe só neste aparelho e o app não
// tem servidor de e-mail, então a confirmação é feita pelo e-mail e pelo
// telefone cadastrados. Conferidos os dois, a senha nova é gravada e a
// pessoa volta ao login para entrar com ela
class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _mostrarSenha = false;
  bool _mostrarConfirmacao = false;
  bool _salvando = false;
  // Erros que só se sabe depois de consultar a conta salva
  String? _erroDoEmail;
  String? _erroDoTelefone;

  // Confere e-mail e telefone com a conta salva e, se baterem, grava a
  // senha nova, avisa e volta ao login
  Future<void> _redefinir() async {
    setState(() {
      _erroDoEmail = null;
      _erroDoTelefone = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final resultado = await context.read<UsuarioProvider>().redefinirSenha(
      email: _emailController.text,
      telefone: _telefoneController.text,
      senha: _senhaController.text,
    );
    if (!mounted) return;
    switch (resultado) {
      case ResultadoDaRedefinicao.semConta:
        _erroDoEmail = 'Nenhuma conta com este e-mail neste aparelho.';
      case ResultadoDaRedefinicao.telefoneDiferente:
        _erroDoTelefone = 'O telefone não confere com o da conta.';
      case ResultadoDaRedefinicao.redefinida:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Senha redefinida. Entre com a senha nova.'),
            ),
          );
        Navigator.of(context).pop();
        return;
    }
    setState(() => _salvando = false);
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
                'Confirme o e-mail e o telefone da sua conta para criar uma '
                'senha nova.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  height: 1.4,
                  color: context.cores.textoFraco,
                ),
              ),
              const SizedBox(height: 22),
              AuthField(
                label: 'E-mail',
                hint: 'Digite o e-mail da conta',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [MascaraDeEmail()],
                prefixIcon: Icons.mail_outline,
                validator: (value) => validarEmail(value) ?? _erroDoEmail,
              ),
              const SizedBox(height: 12),
              AuthField(
                label: 'Telefone/WhatsApp',
                hint: 'Digite o telefone da conta',
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [MascaraDeTelefone()],
                prefixIcon: Icons.phone_outlined,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Informe o telefone da conta.'
                    : _erroDoTelefone,
              ),
              const SizedBox(height: 12),
              AuthField(
                label: 'Nova senha',
                hint: 'Crie uma senha nova',
                controller: _senhaController,
                prefixIcon: Icons.lock_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Crie uma senha nova.';
                  }
                  if (value.length < 8) {
                    return 'A senha deve ter pelo menos 8 caracteres.';
                  }
                  return null;
                },
                obscureText: !_mostrarSenha,
                suffixIcon: _mostrarSenha
                    ? Icons.visibility_off
                    : Icons.visibility,
                onSuffixPressed: () =>
                    setState(() => _mostrarSenha = !_mostrarSenha),
              ),
              const SizedBox(height: 12),
              AuthField(
                label: 'Confirmar nova senha',
                hint: 'Digite a senha nova novamente',
                controller: _confirmarSenhaController,
                prefixIcon: Icons.lock_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme a senha nova.';
                  }
                  if (value != _senhaController.text) {
                    return 'As senhas não coincidem.';
                  }
                  return null;
                },
                obscureText: !_mostrarConfirmacao,
                suffixIcon: _mostrarConfirmacao
                    ? Icons.visibility_off
                    : Icons.visibility,
                onSuffixPressed: () =>
                    setState(() => _mostrarConfirmacao = !_mostrarConfirmacao),
              ),
              const SizedBox(height: 20),
              AuthButton(
                label: _salvando ? 'Redefinindo…' : 'Redefinir senha',
                carregando: _salvando,
                onPressed: _salvando ? null : _redefinir,
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
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }
}
