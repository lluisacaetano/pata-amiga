// Biblioteca dart:io: acesso a arquivos do aparelho, como a foto de perfil.
import 'dart:io';

// Pacote flutter/foundation: kIsWeb e Uint8List, para a prévia da foto.
import 'package:flutter/foundation.dart';
// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter/services: PlatformException e TextInputFormatter.
import 'package:flutter/services.dart';
// Pacote image_picker: abre a câmera ou a galeria para escolher fotos.
import 'package:image_picker/image_picker.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo estado_pata_amiga.dart: estado compartilhado do app.
import '../estado/estado_pata_amiga.dart';
// Arquivo ong.dart: modelo da ONG, membros e erros de vínculo.
import '../modelos/ong.dart';
// Arquivo usuario_provider.dart: sessão e perfil da pessoa logada.
import '../provider/usuario_provider.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo ong_service.dart: serviço de ONGs da API.
import '../services/ong_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo avatar_da_ong.dart: avatar da ONG e iniciais de um nome.
import '../widgets/avatar_da_ong.dart';
// Arquivo escolha_de_ong.dart: seletor de ONG.
import '../widgets/escolha_de_ong.dart';
// Arquivo mascaras.dart: máscara e formatação do telefone.
import '../widgets/mascaras.dart';
// Arquivo proteger_alteracoes.dart: confirma a saída sem salvar.
import '../widgets/proteger_alteracoes.dart';

// Edição do perfil: foto, nome e telefone, além do vínculo com ONG (pedir
// entrada, cancelar o pedido, sair ou passar a administração)
class EditarPerfil extends StatefulWidget {
  // Serviço injetável para os testes; sem ele, usa o OngService padrão
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
  // ONG escolhida em "Você faz parte de alguma ONG?"; ao salvar, vira um
  // pedido de entrada
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

  // O botão de salvar só fica ativo quando algo mudou
  bool get _houveMudanca =>
      _fotoSelecionada != null ||
      _ong != null ||
      _nomeController.text.trim() != _nomeOriginal.trim() ||
      _telefoneController.text.trim() != _telefoneOriginal.trim();

  // Abre a galeria e guarda a foto escolhida e seus bytes para a prévia
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

  // Imagem do avatar: a recém-escolhida tem prioridade sobre a já salva
  ImageProvider<Object>? _imagemAtual(String? caminho) {
    if (_fotoBytes != null) return MemoryImage(_fotoBytes!);
    if (caminho == null || caminho.isEmpty) return null;
    return kIsWeb ? NetworkImage(caminho) : FileImage(File(caminho));
  }

  // Salva nome, telefone e foto e, se uma ONG foi escolhida, envia o pedido
  // de entrada. Volta ao perfil mostrando o resultado
  Future<void> _salvar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _salvando = true);
    final provider = context.read<UsuarioProvider>();
    try {
      await provider.atualizarUsuario(
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        foto: _fotoSelecionada?.path ?? provider.usuario.foto,
      );
    } catch (_) {
      // Falha ao gravar no aparelho: destrava o botão e mantém a tela aberta
      // com o que foi digitado, para a pessoa tentar de novo
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar agora. Tente de novo.'),
          ),
        );
      return;
    }
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
    // O aviso é mostrado já no perfil, depois de fechar esta tela
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(aviso)));
  }

  // Quem administra só sai passando a administração para um membro, para a
  // ONG não ficar sem responsável pelo perfil, pela chave Pix e pelos pedidos
  Future<void> _passarESair(Ong ong) async {
    final escolhido = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.cores.cartao,
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

  // Sai da ONG ou cancela o pedido de entrada, depois de confirmar
  Future<void> _sairDaOng(Ong ong, String email) async {
    final membro = ong.fazParte(email);
    final confirmou = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.cores.cartao,
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
                style: TextStyle(
                  fontSize: 14,
                  color: context.cores.textoFraco,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(painel, false),
                style: FilledButton.styleFrom(
                  backgroundColor: context.cores.principal,
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
                  foregroundColor: context.cores.destaque,
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

  // Seção de ONG: quem já faz parte ou já pediu entrada vê a situação e a
  // saída; os demais escolhem uma ONG ou criam uma. Cada conta tem no máximo
  // uma ONG
  Widget _secaoDaOng(String email) {
    final estado = PataAmigaScope.of(context);
    final minha = estado.ongDe(email);
    final pedida = estado.ongPedidaPor(email);
    if (minha != null || pedida != null) {
      final criou = minha?.eDoResponsavel(email) ?? false;
      final ong = (minha ?? pedida)!;
      // Uma linha com a ONG, o papel da pessoa nela e, à direita, a saída
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Rotulo('ONG'),
          const SizedBox(height: 10),
          Row(
            children: [
              if (minha != null)
                // Raio 22 mais o anel de 2 do AvatarDaOng dá 48 de diâmetro,
                // o mesmo do círculo de "aguardando" (raio 24)
                AvatarDaOng(ong: minha, raio: 22)
              else
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.cores.principalClara,
                  child: Icon(Icons.schedule, color: context.cores.principal),
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
                      style: TextStyle(
                        fontSize: 13,
                        color: context.cores.textoFraco,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    criou ? _passarESair(minha!) : _sairDaOng(ong, email),
                style: TextButton.styleFrom(
                  foregroundColor: context.cores.destaque,
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
        // Para quem representa uma ONG que ainda não está no app
        Divider(height: 28, color: context.cores.borda),
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.cadastroOng),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Criar o perfil de uma ONG'),
          style: TextButton.styleFrom(
            foregroundColor: context.cores.principal,
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

    // Com alterações não salvas, voltar pede confirmação antes de sair
    return ProtegerAlteracoes(
      alterado: () => _houveMudanca && !_salvando,
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: context.cores.fundo,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            color: context.cores.principal,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          'EDITAR PERFIL',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
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
                style: TextButton.styleFrom(foregroundColor: context.cores.principal),
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
            backgroundColor: context.cores.principal,
            disabledBackgroundColor: context.cores.borda,
            disabledForegroundColor: context.cores.textoFraco,
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
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.sobrePrincipal,
                  ),
                )
              : const Text('Salvar alterações'),
        ),
      ),
    ),
    );
  }
}

// Avatar grande tocável, com o selo de câmera (ou o carregamento) no canto
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.cores.principalClara,
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: context.cores.principalClara,
                backgroundImage: imagem,
                child: imagem == null
                    ? Icon(
                        Icons.person_outline,
                        size: 56,
                        color: context.cores.principal,
                      )
                    : null,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.cores.fundo,
                ),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: context.cores.principal,
                  child: carregando
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.sobrePrincipal,
                          ),
                        )
                      : Icon(
                          Icons.photo_camera_outlined,
                          size: 18,
                          color: context.sobrePrincipal,
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

// Moldura de cartão que agrupa os campos do formulário
class _Cartao extends StatelessWidget {
  const _Cartao({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: child,
    );
  }
}

// Rótulo em caixa alta acima do campo, no padrão do cadastro de animal
class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: context.cores.textoFraco,
      ),
    );
  }
}

// Campo de texto com rótulo, ícone, máscara opcional e validação
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
          style: TextStyle(fontSize: 15, color: context.cores.texto),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: context.cores.fundo,
            hintText: exemplo,
            hintStyle: TextStyle(fontSize: 14, color: context.cores.textoFraco),
            prefixIcon: Icon(icone, size: 20, color: context.cores.principal),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: borda(context.cores.borda),
            focusedBorder: borda(context.cores.principal, 1.5),
            errorBorder: borda(context.cores.destaque),
            focusedErrorBorder: borda(context.cores.destaque, 1.5),
            errorStyle: TextStyle(color: context.cores.destaque),
          ),
        ),
      ],
    );
  }
}

// Valor somente leitura exibido como texto, e não como campo desabilitado,
// para não parecer algo à espera de digitação. Usado no e-mail
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
            Icon(icone, size: 20, color: context.cores.textoFraco),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                valor,
                style: TextStyle(fontSize: 15, color: context.cores.texto),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            explicacao,
            style: TextStyle(fontSize: 12, color: context.cores.textoFraco),
          ),
        ),
      ],
    );
  }
}

// Explica por que ainda não há troca de senha
class _AvisoDeSenha extends StatelessWidget {
  const _AvisoDeSenha();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cores.principalClara,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 20, color: context.cores.principal),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'A troca de senha fica disponível quando o login estiver '
              'conectado ao serviço de autenticação.',
              style: TextStyle(fontSize: 13, color: context.cores.texto, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// Painel em que quem administra escolhe, entre os membros, o novo
// responsável pela ONG. Sem membros, explica que é preciso aprovar alguém
// antes; devolve o e-mail escolhido ou null
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
              style: TextStyle(
                fontSize: 14,
                color: context.cores.textoFraco,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            for (final pessoa in membros)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: _escolhido == pessoa.email
                      ? context.cores.principalClara
                      : context.cores.fundo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _escolhido == pessoa.email
                          ? context.cores.principal
                          : context.cores.borda,
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
                            backgroundColor: context.cores.principalClara,
                            child: Text(
                              iniciaisDa(pessoa.nome),
                              style: TextStyle(
                                color: context.cores.principal,
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
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.cores.textoFraco,
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
                                ? context.cores.principal
                                : context.cores.borda,
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
                backgroundColor: context.cores.principal,
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
                  foregroundColor: context.cores.textoFraco,
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
