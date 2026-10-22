import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/ong.dart';
import '../provider/usuario_provider.dart';
import '../routes/route_names.dart';
import '../services/ong_service.dart';
import '../tema/cores.dart';
import '../widgets/avatar_da_ong.dart';
import '../widgets/escolha_de_ong.dart';
import '../widgets/mascaras.dart';
import '../widgets/proteger_alteracoes.dart';

class EditarPerfil extends StatefulWidget {
  // Os testes passam um serviço de ONGs falso; o app usa o de verdade
  final OngService? ongs;

  const EditarPerfil({super.key, this.ongs});

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final String _nomeOriginal;
  late final String _telefoneOriginal;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _fotoSelecionada;
  Uint8List? _fotoBytes;
  bool _selecionandoFoto = false;
  bool _salvando = false;
  // A ONG escolhida em "Você faz parte de alguma ONG?": vira um pedido
  Ong? _ong;

  @override
  void initState() {
    super.initState();
    final usuario = context.read<UsuarioProvider>().usuario;
    _nomeOriginal = usuario.nome;
    _telefoneOriginal = usuario.telefone;
    _nomeController = TextEditingController(text: usuario.nome)
      ..addListener(_aoMudar);
    _telefoneController = TextEditingController(text: usuario.telefone)
      ..addListener(_aoMudar);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  void _aoMudar() => setState(() {});

  // O botão de salvar só acende quando há o que salvar
  bool get _houveMudanca =>
      _fotoSelecionada != null ||
      _ong != null ||
      _nomeController.text.trim() != _nomeOriginal.trim() ||
      _telefoneController.text.trim() != _telefoneOriginal.trim();

  Future<void> _selecionarFoto() async {
    if (_selecionandoFoto) return;
    setState(() => _selecionandoFoto = true);
    try {
      final imagem = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (imagem == null || !mounted) return;
      final bytes = await imagem.readAsBytes();
      if (!mounted) return;
      setState(() {
        _fotoSelecionada = imagem;
        _fotoBytes = bytes;
      });
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir a galeria neste aparelho.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _selecionandoFoto = false);
    }
  }

  ImageProvider<Object>? _imagemAtual(String? caminho) {
    if (_fotoBytes != null) return MemoryImage(_fotoBytes!);
    if (caminho == null || caminho.isEmpty) return null;
    return kIsWeb ? NetworkImage(caminho) : FileImage(File(caminho));
  }

  Future<void> _salvar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _salvando = true);
    final provider = context.read<UsuarioProvider>();
    await provider.atualizarUsuario(
      nome: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim(),
      foto: _fotoSelecionada?.path ?? provider.usuario.foto,
    );
    if (!mounted) return;
    var aviso = 'Alterações salvas.';
    final ong = _ong;
    if (ong != null) {
      final estado = PataAmigaScope.of(context);
      try {
        estado.salvarOng(
          await (widget.ongs ?? OngService()).pedirEntrada(ong, PessoaDaOng(
            email: provider.usuario.email,
            nome: provider.usuario.nome,
            telefone: provider.usuario.telefone,
          )),
        );
        aviso = 'Alterações salvas. Pedido enviado para ${ong.nome}.';
      } on JaFazParteDeOutra catch (erro) {
        aviso =
            'Alterações salvas, mas sua conta já está ligada a ${erro.ong}. '
            'Cada conta pode ter só uma ONG.';
      } on Exception {
        aviso =
            'Alterações salvas, mas o pedido para ${ong.nome} não foi '
            'enviado. Tente de novo.';
      }
      if (!mounted) return;
    }
    // O aviso aparece já no perfil, onde a pessoa vê o resultado
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(aviso)));
  }

  // A admin só sai passando a ONG para um membro: a ONG não fica sem quem
  // cuida do perfil, da chave Pix e dos pedidos
  Future<void> _passarESair(Ong ong) async {
    final escolhido = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Cores.cartao,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (painel) => _EscolherNovaAdmin(ong: ong),
    );
    if (escolhido == null || !mounted) return;
    final estado = PataAmigaScope.of(context);
    final mensageiro = ScaffoldMessenger.of(context);
    final nome = ong.membros
        .firstWhere((pessoa) => pessoa.email == escolhido)
        .nome;
    String aviso;
    try {
      estado.salvarOng(
        await (widget.ongs ?? OngService()).passarAdministracao(
          ong,
          escolhido,
        ),
      );
      aviso = '$nome agora administra ${ong.nome}, e você saiu da ONG.';
    } on NaoEMembro {
      aviso = '$nome não faz mais parte de ${ong.nome}. Escolha outra pessoa.';
    } on Exception {
      aviso = 'Não foi possível agora. Tente de novo.';
    }
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(aviso)));
  }

  // Sair da ONG, ou desistir do pedido, depois de confirmar
  Future<void> _sairDaOng(Ong ong, String email) async {
    final membro = ong.fazParte(email);
    final confirmou = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Cores.cartao,
      showDragHandle: true,
      builder: (painel) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                membro
                    ? 'Sair de ${ong.nome}?'
                    : 'Cancelar o pedido para ${ong.nome}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                membro
                    ? 'Você deixa de publicar em nome da ONG. Os animais que '
                          'já publicou por ela continuam no perfil dela.'
                    : 'Quem administra a ONG não vai mais ver o seu pedido.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Cores.textoFraco,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(painel, false),
                style: FilledButton.styleFrom(
                  backgroundColor: Cores.principal,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(membro ? 'Continuar na ONG' : 'Manter o pedido'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(painel, true),
                style: TextButton.styleFrom(
                  foregroundColor: Cores.destaque,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: Text(membro ? 'Sair da ONG' : 'Cancelar pedido'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmou != true || !mounted) return;
    final estado = PataAmigaScope.of(context);
    final mensageiro = ScaffoldMessenger.of(context);
    String aviso;
    try {
      estado.salvarOng(
        await (widget.ongs ?? OngService()).sairDaOng(ong, email),
      );
      aviso = membro
          ? 'Você saiu de ${ong.nome}.'
          : 'Pedido para ${ong.nome} cancelado.';
    } on Exception {
      aviso = 'Não foi possível agora. Tente de novo.';
    }
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(aviso)));
  }

  // Quem já faz parte de uma ONG, ou já pediu para entrar, vê a situação;
  // os outros veem a pergunta. Cada conta tem no máximo uma ONG
  Widget _secaoDaOng(String email) {
    final estado = PataAmigaScope.of(context);
    final minha = estado.ongDe(email);
    final pedida = estado.ongPedidaPor(email);
    if (minha != null || pedida != null) {
      final criou = minha?.eDoResponsavel(email) ?? false;
      final ong = (minha ?? pedida)!;
      // Uma linha só, como os campos de cima: quem é a ONG, o papel da pessoa
      // nela e, à direita, a saída
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Rotulo('ONG'),
          const SizedBox(height: 10),
          Row(
            children: [
              if (minha != null)
                AvatarDaOng(ong: minha, raio: 22)
              else
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Cores.principalClara,
                  child: Icon(Icons.schedule, color: Cores.principal),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ong.nome,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      minha == null
                          ? 'Aguardando aprovação'
                          : criou
                          ? 'Você administra'
                          : 'Você é membro',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Cores.textoFraco,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    criou ? _passarESair(minha!) : _sairDaOng(ong, email),
                style: TextButton.styleFrom(
                  foregroundColor: Cores.destaque,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: Text(minha != null ? 'Sair da ONG' : 'Cancelar pedido'),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EscolhaDeOng(
          servico: widget.ongs,
          escolhida: _ong,
          aoEscolher: (ong) => setState(() => _ong = ong),
        ),
        // Quem representa uma ONG que ainda não está no app cria o perfil
        const Divider(height: 28, color: Cores.borda),
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.cadastroOng),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Criar o perfil de uma ONG'),
          style: TextButton.styleFrom(
            foregroundColor: Cores.principal,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<UsuarioProvider>().usuario;
    final imagem = _imagemAtual(usuario.foto);

    // Com algo mudado e não salvo, voltar pergunta antes de sair
    return ProtegerAlteracoes(
      alterado: () => _houveMudanca && !_salvando,
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            color: Cores.principal,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'EDITAR PERFIL',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Cores.principal,
          ),
        ),
      ),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(
              child: _FotoEditavel(
                imagem: imagem,
                carregando: _selecionandoFoto,
                aoTocar: _selecionarFoto,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: _selecionandoFoto ? null : _selecionarFoto,
                style: TextButton.styleFrom(foregroundColor: Cores.principal),
                child: Text(
                  imagem == null ? 'Escolher foto' : 'Trocar foto',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Cartao(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Campo(
                    rotulo: 'Nome',
                    controlador: _nomeController,
                    icone: Icons.person_outline,
                    exemplo: 'Seu nome',
                    capitalizacao: TextCapitalization.words,
                    validador: (valor) => (valor ?? '').trim().isEmpty
                        ? 'Informe seu nome.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _Campo(
                    rotulo: 'Telefone',
                    controlador: _telefoneController,
                    icone: Icons.phone_outlined,
                    exemplo: '(37) 90000-0000',
                    teclado: TextInputType.phone,
                    formatadores: [MascaraDeTelefone()],
                    validador: (valor) {
                      final digitos = (valor ?? '').replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      if (digitos.isEmpty) return 'Informe seu telefone.';
                      if (digitos.length < 10) {
                        return 'Digite um telefone com DDD válido.';
                      }
                      return null;
                    },
                  ),
                  if (usuario.email.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _CampoFixo(
                      rotulo: 'E-mail',
                      icone: Icons.mail_outline,
                      valor: usuario.email,
                      explicacao: 'O e-mail identifica sua conta e não muda.',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Cartao(child: _secaoDaOng(usuario.email)),
            const SizedBox(height: 12),
            const _AvisoDeSenha(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: _houveMudanca && !_salvando ? _salvar : null,
          style: FilledButton.styleFrom(
            backgroundColor: Cores.principal,
            disabledBackgroundColor: Cores.borda,
            disabledForegroundColor: Cores.textoFraco,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: _salvando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar alterações'),
        ),
      ),
    ),
    );
  }
}

class _FotoEditavel extends StatelessWidget {
  const _FotoEditavel({
    required this.imagem,
    required this.carregando,
    required this.aoTocar,
  });

  final ImageProvider<Object>? imagem;
  final bool carregando;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Alterar foto',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: carregando ? null : aoTocar,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Cores.principalClara,
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: Cores.principalClara,
                backgroundImage: imagem,
                child: imagem == null
                    ? const Icon(
                        Icons.person_outline,
                        size: 56,
                        color: Cores.principal,
                      )
                    : null,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Cores.fundo,
                ),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: Cores.principal,
                  child: carregando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.photo_camera_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: child,
    );
  }
}

// Rótulo em caixa alta acima do campo, como no cadastro de animal
class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Cores.textoFraco,
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.rotulo,
    required this.controlador,
    required this.icone,
    required this.exemplo,
    this.teclado,
    this.formatadores,
    this.capitalizacao = TextCapitalization.sentences,
    this.validador,
  });

  final String rotulo;
  final TextEditingController controlador;
  final IconData icone;
  final String exemplo;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatadores;
  final TextCapitalization capitalizacao;
  final FormFieldValidator<String>? validador;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borda(Color cor, [double largura = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cor, width: largura),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rotulo(rotulo),
        const SizedBox(height: 6),
        TextFormField(
          controller: controlador,
          keyboardType: teclado,
          inputFormatters: formatadores,
          textCapitalization: capitalizacao,
          validator: validador,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 15, color: Cores.texto),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Cores.fundo,
            hintText: exemplo,
            hintStyle: const TextStyle(fontSize: 14, color: Cores.textoFraco),
            prefixIcon: Icon(icone, size: 20, color: Cores.principal),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: borda(Cores.borda),
            focusedBorder: borda(Cores.principal, 1.5),
            errorBorder: borda(Cores.destaque),
            focusedErrorBorder: borda(Cores.destaque, 1.5),
            errorStyle: const TextStyle(color: Cores.destaque),
          ),
        ),
      ],
    );
  }
}

// O e-mail aparece como texto, não como campo desabilitado: não é algo que a
// pessoa possa mudar, então não deve parecer um campo à espera de digitação
class _CampoFixo extends StatelessWidget {
  const _CampoFixo({
    required this.rotulo,
    required this.icone,
    required this.valor,
    required this.explicacao,
  });

  final String rotulo;
  final IconData icone;
  final String valor;
  final String explicacao;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rotulo(rotulo),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icone, size: 20, color: Cores.textoFraco),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                valor,
                style: const TextStyle(fontSize: 15, color: Cores.texto),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            explicacao,
            style: const TextStyle(fontSize: 12, color: Cores.textoFraco),
          ),
        ),
      ],
    );
  }
}

class _AvisoDeSenha extends StatelessWidget {
  const _AvisoDeSenha();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.principalClara,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 20, color: Cores.principal),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'A troca de senha fica disponível quando o login estiver '
              'conectado ao serviço de autenticação.',
              style: TextStyle(fontSize: 13, color: Cores.texto, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// A admin escolhe entre os membros quem vai administrar a ONG. Sem membros,
// explica que é preciso aprovar alguém antes
class _EscolherNovaAdmin extends StatefulWidget {
  const _EscolherNovaAdmin({required this.ong});

  final Ong ong;

  @override
  State<_EscolherNovaAdmin> createState() => _EscolherNovaAdminState();
}

class _EscolherNovaAdminState extends State<_EscolherNovaAdmin> {
  String? _escolhido;

  @override
  Widget build(BuildContext context) {
    final membros = widget.ong.membros;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              membros.isEmpty
                  ? 'Ninguém para administrar ${widget.ong.nome}'
                  : 'Quem vai administrar ${widget.ong.nome}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              membros.isEmpty
                  ? 'A ONG não pode ficar sem admin. Aprove um membro pelas '
                        'notificações e depois passe a administração para ele.'
                  : 'A pessoa escolhida passa a editar o perfil e a chave Pix '
                        'e a responder aos pedidos. Você sai da ONG.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Cores.textoFraco,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            for (final pessoa in membros)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: _escolhido == pessoa.email
                      ? Cores.principalClara
                      : Cores.fundo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _escolhido == pessoa.email
                          ? Cores.principal
                          : Cores.borda,
                      width: _escolhido == pessoa.email ? 1.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => setState(() => _escolhido = pessoa.email),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Cores.principalClara,
                            child: Text(
                              iniciaisDa(pessoa.nome),
                              style: const TextStyle(
                                color: Cores.principal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pessoa.nome,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (pessoa.telefone.isNotEmpty)
                                  Text(
                                    formatarTelefone(pessoa.telefone),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Cores.textoFraco,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            _escolhido == pessoa.email
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: _escolhido == pessoa.email
                                ? Cores.principal
                                : Cores.borda,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: membros.isEmpty
                  ? () => Navigator.pop(context)
                  : _escolhido == null
                  ? null
                  : () => Navigator.pop(context, _escolhido),
              style: FilledButton.styleFrom(
                backgroundColor: Cores.principal,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                membros.isEmpty ? 'Entendi' : 'Passar a ONG e sair',
              ),
            ),
            if (membros.isNotEmpty) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Cores.textoFraco,
                ),
                child: const Text('Continuar na ONG'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
