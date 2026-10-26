// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo auth_components.dart: fundo, campos e botões das telas de entrada.
import 'auth_components.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../../routes/route_names.dart';
// Arquivo onboarding_screen.dart: navegação para o app depois do cadastro.
import '../../telas/onboarding_screen.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../../tema/cores.dart';
// Arquivo mascaras.dart: máscaras e validador de e-mail e telefone.
import '../../widgets/mascaras.dart';
// Arquivo usuario_provider.dart: registro da conta nova.
import '../../provider/usuario_provider.dart';
// Arquivo estado_pata_amiga.dart: estado compartilhado das ONGs.
import '../../estado/estado_pata_amiga.dart';
// Arquivo ong.dart: modelo da ONG e da pessoa que pede para entrar.
import '../../modelos/ong.dart';
// Arquivo ong_service.dart: serviço que envia o pedido de entrada à ONG.
import '../../services/ong_service.dart';
// Arquivo escolha_de_ong.dart: campo de escolha da ONG.
import '../../widgets/escolha_de_ong.dart';

// Tela de criação de conta: nome, e-mail, telefone, senha, a ONG de que a
// pessoa faz parte (opcional) e o aceite dos termos. O perfil é salvo no
// aparelho e a senha é guardada apenas como resumo (ver UsuarioProvider)
class RegisterScreen extends StatefulWidget {
  // Serviço de ONGs; quando nulo, usa o padrão (os testes passam um falso)
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
  // Impede que um segundo toque crie a conta e peça entrada à ONG de novo
  bool _salvando = false;
  // ONG escolhida no cadastro; ao criar a conta, vira um pedido de entrada
  Ong? _ong;
  // Erro do e-mail que só se sabe ao tentar criar a conta: o e-mail já
  // pertence a outra conta neste aparelho
  String? _erroDoEmail;

  // Envia o pedido de entrada para o administrador da ONG aprovar e avisa o
  // resultado. Se a API falhar, a conta é criada mesmo assim e o pedido
  // pode ser refeito em Editar perfil
  Future<void> _pedirEntrada(Ong ong) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final estado = PataAmigaScope.talvez(context);
    String aviso;
    try {
      // Atualiza o estado com a ONG devolvida, para a etiqueta "Aguardando"
      // aparecer sem recarregar
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
                validator: (value) => validarEmail(value) ?? _erroDoEmail,
              ),
              // Com o e-mail já cadastrado, oferece a recuperação da senha
              if (_erroDoEmail != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .pushNamed(AppRoutes.recoverPassword),
                    child: const Text('Esqueci a senha'),
                  ),
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
              // Força a fonte Roboto, a mesma dos outros campos desta tela
              Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme
                      .apply(fontFamily: 'Roboto'),
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
                      activeColor: context.cores.principal,
                      checkColor: context.sobrePrincipal,
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
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: 4),
                  child: Text(
                    'É necessário aceitar os termos para continuar.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              AuthButton(
                label: _salvando ? 'Criando conta…' : 'Criar conta',
                carregando: _salvando,
                onPressed: _salvando ? null : _criarConta,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  // Vai para o login mesmo quando o cadastro foi aberto
                  // pelas boas-vindas
                  onPressed: () =>
                      Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.login),
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

  // Valida os campos e o aceite dos termos, salva o perfil com a senha,
  // envia o pedido à ONG (se houver) e segue para o app. Se o e-mail já
  // tiver conta, nada é salvo e o erro aparece no campo de e-mail
  Future<void> _criarConta() async {
    setState(() => _erroDoEmail = null);
    final camposValidos = _formKey.currentState!.validate();
    setState(() => _mostrarErroTermos = !_aceitouTermos);
    if (!camposValidos || !_aceitouTermos) return;
    setState(() => _salvando = true);
    final criada = await context.read<UsuarioProvider>().registrarUsuario(
      nome: _nomeController.text,
      email: _emailController.text,
      telefone: _telefoneController.text,
      senha: _senhaController.text,
    );
    if (!mounted) return;
    if (!criada) {
      setState(() {
        _salvando = false;
        _erroDoEmail = 'Já existe uma conta com este e-mail.';
      });
      _formKey.currentState!.validate();
      return;
    }
    final ong = _ong;
    if (ong != null) await _pedirEntrada(ong);
    if (!mounted) return;
    await navegarAposAutenticacao(context);
  }

  // Texto em destaque que abre os Termos de Uso ou a Política de Privacidade
  Widget _linkDocumento(BuildContext context, String texto, String rota) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(rota),
      child: Text(
        texto,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.cores.principal,
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
