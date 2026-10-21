import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../provider/usuario_provider.dart';
import '../tema/cores.dart';
import '../widgets/mascaras.dart';

class EditarPerfil extends StatefulWidget {
  const EditarPerfil({super.key});

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
    // O aviso aparece já no perfil, onde a pessoa vê o resultado
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Alterações salvas.')));
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<UsuarioProvider>().usuario;
    final imagem = _imagemAtual(usuario.foto);

    return Scaffold(
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
                      if (digitos.isEmpty) return null;
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
