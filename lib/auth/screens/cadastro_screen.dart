import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_components.dart';
import '../../routes/route_names.dart';
import '../../telas/onboarding_screen.dart';
import '../../tema/cores.dart';
import '../../widgets/mascaras.dart';
import '../../provider/usuario_provider.dart';
import '../../estado/estado_pata_amiga.dart';
import '../../modelos/ong.dart';
import '../../services/ong_service.dart';
import '../../widgets/escolha_de_ong.dart';

class RegisterScreen extends StatefulWidget {
  // Os testes passam um serviço de ONGs falso; o app usa o de verdade
  final OngService? ongs;

  const RegisterScreen({super.key, this.ongs});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _aceitouTermos = false;
  bool _mostrarErroTermos = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmacao = false;
  // A ONG de que a pessoa diz fazer parte: vira um pedido para entrar
  Ong? _ong;

  // O pedido vai para quem administra a ONG aprovar. Se a API não responder, a
  // conta é criada mesmo assim, e o pedido pode ser refeito no Editar perfil
  Future<void> _pedirEntrada(Ong ong) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final estado = PataAmigaScope.talvez(context);
    String aviso;
    try {
      // O estado já sabe do pedido: a etiqueta "Aguardando" aparece logo
      estado?.salvarOng(
        await (widget.ongs ?? OngService()).pedirEntrada(
          ong,
          PessoaDaOng(
            email: _emailController.text.trim(),
            nome: _nomeController.text.trim(),
            telefone: _telefoneController.text.trim(),
          ),
        ),
      );
      aviso =
          'Pedido enviado para ${ong.nome}. Você terá acesso quando '
          'ele for aprovado.';
    } on JaFazParteDeOutra catch (erro) {
      aviso = 'Sua conta já está ligada a ${erro.ong}.';
    } on Exception {
      aviso =
          'Não foi possível enviar o pedido para ${ong.nome}. Tente '
          'de novo pelo Editar perfil.';
    }
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(aviso)));
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
              const AuthBrandMark(size: 58),
              const SizedBox(height: 10),
              Text(
                'Criar conta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.cores.principal,
                ),
              ),
              const SizedBox(height: 18),
              AuthField(
                label: 'Nome',
                hint: 'Digite seu nome completo',
                controller: _nomeController,
                prefixIcon: Icons.person_outline,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe seu nome.'
                    : null,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              AuthField(
                label: 'Telefone/WhatsApp',
                hint: 'Digite seu telefone',
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [MascaraDeTelefone()],
                prefixIcon: Icons.phone_outlined,
                validator: (value) {
                  final telefone = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (telefone.isEmpty) return 'Informe seu telefone.';
                  if (telefone.length < 10 || telefone.length > 11) {
                    return 'Digite um telefone com DDD válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AuthField(
                label: 'Senha',
                hint: 'Crie uma senha',
                controller: _senhaController,
                prefixIcon: Icons.lock_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Crie uma senha.';
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
                label: 'Confirmar senha',
                hint: 'Digite a senha novamente',
                controller: _confirmarSenhaController,
                prefixIcon: Icons.lock_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme sua senha.';
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
              const SizedBox(height: 16),
              // A mesma fonte Roboto dos outros campos desta tela
              Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(
                    context,
                  ).textTheme.apply(fontFamily: 'Roboto'),
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: 'Roboto'),
                  child: EscolhaDeOng(
                    servico: widget.ongs,
                    escolhida: _ong,
                    aoEscolher: (ong) => setState(() => _ong = ong),
                    estiloDaPergunta: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.cores.texto,
                    ),
                  ),
                ),
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
                        setState(() {
                          _aceitouTermos = value ?? false;
                          _mostrarErroTermos = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Li e aceito '),
                          _linkDocumento(
                            context,
                            'Termos de Uso',
                            AppRoutes.terms,
                          ),
                          const Text(' e a '),
                          _linkDocumento(
                            context,
                            'Política de Privacidade',
                            AppRoutes.privacy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_mostrarErroTermos)
                const Padding(
                  padding: EdgeInsets.only(left: 44, top: 4),
                  child: Text(
                    'É necessário aceitar os termos para continuar.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 12),
              AuthButton(
                label: 'Criar conta',
                onPressed: () async {
                  final camposValidos = _formKey.currentState!.validate();
                  setState(() => _mostrarErroTermos = !_aceitouTermos);
                  if (!camposValidos || !_aceitouTermos) return;
                  await context.read<UsuarioProvider>().registrarUsuario(
                    nome: _nomeController.text,
                    email: _emailController.text,
                    telefone: _telefoneController.text,
                  );
                  final ong = _ong;
                  if (ong != null) await _pedirEntrada(ong);
                  if (!context.mounted) return;
                  await navegarAposAutenticacao(context);
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Já tem conta? Entrar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linkDocumento(BuildContext context, String texto, String rota) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(rota),
      child: Text(
        texto,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: context.cores.principal,
          decoration: TextDecoration.underline,
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
