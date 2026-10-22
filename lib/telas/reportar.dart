import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dados/canais_de_denuncia.dart';
import '../modelos/denuncia.dart';
import '../provider/usuario_provider.dart';
import '../services/denuncia_service.dart';
import '../tema/cores.dart';
import '../widgets/foto_animal.dart';
import '../widgets/mapa_de_local.dart';
import '../widgets/proteger_alteracoes.dart';
import '../widgets/seletor_de_local.dart';

// A denúncia de maus-tratos (US 11). Abre com o que diz a lei, pede o que
// aconteceu, onde, quando e as fotos, e deixa enviar sem identificação. Ao
// registrar, a pessoa recebe o protocolo e encaminha a denúncia à APAF pelo
// WhatsApp, como no contato de adoção
class ReportarScreen extends StatefulWidget {
  final DenunciaService? servico;

  const ReportarScreen({super.key, this.servico});

  @override
  State<ReportarScreen> createState() => _ReportarScreenState();
}

const _maximoDeFotos = 5;

class _ReportarScreenState extends State<ReportarScreen> {
  late final _servico = widget.servico ?? DenunciaService();
  final _seletorDeFotos = ImagePicker();
  final _descricao = TextEditingController();
  final _rolagem = ScrollController();

  TipoDeDenuncia? _tipo;
  DateTime? _data;
  final List<XFile> _fotos = [];
  LocalEscolhido _local = (ponto: centroDeFormiga, rua: '', bairro: '');
  bool _anonima = false;
  bool _tentou = false;
  bool _enviando = false;

  @override
  void dispose() {
    _descricao.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  // O que já foi preenchido: o aviso de sair sem salvar só aparece com algo
  bool get _alterado =>
      !_enviando &&
      (_tipo != null ||
          _descricao.text.trim().isNotEmpty ||
          _fotos.isNotEmpty ||
          _data != null);

  bool get _completo =>
      _tipo != null &&
      _descricao.text.trim().isNotEmpty &&
      _local.rua.trim().isNotEmpty &&
      _local.bairro.trim().isNotEmpty &&
      _fotos.isNotEmpty &&
      (_anonima || _identificavel);

  // Identificada, a denúncia precisa de nome e telefone para a APAF poder
  // falar com quem denunciou; sem eles no perfil, só sai anônima
  bool get _identificavel {
    final usuario = context.read<UsuarioProvider?>()?.usuario;
    return (usuario?.nome.trim().isNotEmpty ?? false) &&
        (usuario?.telefone.trim().isNotEmpty ?? false);
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _data ?? hoje,
      firstDate: DateTime(2000),
      lastDate: DateTime(hoje.year, hoje.month, hoje.day),
      helpText: 'Quando aconteceu?',
    );
    if (data != null && mounted) setState(() => _data = data);
  }

  Future<void> _adicionarFotos() async {
    final vagas = _maximoDeFotos - _fotos.length;
    if (vagas <= 0) return;
    try {
      final escolhidas = await _seletorDeFotos.pickMultiImage(
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (!mounted || escolhidas.isEmpty) return;
      setState(() => _fotos.addAll(escolhidas.take(vagas)));
    } on PlatformException {
      _avisar('Não foi possível abrir a galeria neste aparelho.');
    }
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    setState(() => _tentou = true);
    if (_enviando) return;
    if (!_completo) {
      _avisar('Preencha os campos obrigatórios marcados em vermelho.');
      _rolagem.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    setState(() => _enviando = true);
    final usuario = context.read<UsuarioProvider?>()?.usuario;
    final agora = DateTime.now();
    try {
      final registrada = await _servico.registrar(
        Denuncia(
          protocolo: Denuncia.novoProtocolo(agora),
          tipo: _tipo!,
          descricao: _descricao.text.trim(),
          rua: _local.rua,
          bairro: _local.bairro,
          latitude: _local.ponto.latitude,
          longitude: _local.ponto.longitude,
          ocorridaEm: _data,
          fotos: [for (final foto in _fotos) foto.path],
          anonima: _anonima,
          denuncianteNome: usuario?.nome.trim() ?? '',
          denuncianteTelefone: usuario?.telefone.trim() ?? '',
          denuncianteEmail: usuario?.email.trim() ?? '',
          registradaEm: agora,
        ),
      );
      if (!mounted) return;
      final navegador = Navigator.of(context);
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: context.cores.cartao,
        showDragHandle: true,
        builder: (_) => _DenunciaRegistrada(denuncia: registrada),
      );
      // Registrada, a tela fecha: não há mais nada a salvar
      navegador.pop();
    } on Exception {
      if (!mounted) return;
      setState(() => _enviando = false);
      _avisar('Não foi possível registrar a denúncia agora. Tente de novo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final semTipo = _tentou && _tipo == null;
    final semDescricao = _tentou && _descricao.text.trim().isEmpty;
    final semLocal =
        _tentou && (_local.rua.trim().isEmpty || _local.bairro.trim().isEmpty);
    final semFoto = _tentou && _fotos.isEmpty;
    final semContato = _tentou && !_anonima && !_identificavel;
    return ProtegerAlteracoes(
      alterado: () => _alterado,
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
            'DENUNCIAR MAUS-TRATOS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: context.cores.principal,
            ),
          ),
        ),
        body: ListView(
          controller: _rolagem,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _OQueDizALei(),
            _Cartao(
              icone: Icons.report_outlined,
              titulo: 'O que aconteceu',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Rotulo('Tipo'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TipoDeDenuncia>(
                    initialValue: _tipo,
                    isDense: true,
                    decoration: _caixa(context, null, comErro: semTipo),
                    hint: Text(
                      'Escolher',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.cores.textoFraco,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.cores.textoFraco,
                    ),
                    dropdownColor: context.cores.cartao,
                    style: TextStyle(fontSize: 15, color: context.cores.texto),
                    items: [
                      for (final tipo in TipoDeDenuncia.values)
                        DropdownMenuItem(value: tipo, child: Text(tipo.rotulo)),
                    ],
                    onChanged: (tipo) => setState(() => _tipo = tipo),
                  ),
                  if (semTipo) const _Recado('Campo obrigatório', erro: true),
                  const SizedBox(height: 14),
                  const _Rotulo('Descrição'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descricao,
                    minLines: 4,
                    maxLines: null,
                    maxLength: 1000,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 15),
                    decoration: _caixa(
                      context,
                      'Conte o que você viu: o animal, o estado dele e '
                      'há quanto tempo isso acontece.',
                      comErro: semDescricao,
                    ),
                  ),
                  if (semDescricao)
                    const _Recado('Campo obrigatório', erro: true),
                ],
              ),
            ),
            _Cartao(
              icone: Icons.location_on_outlined,
              titulo: 'Onde',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SeletorDeLocal(
                    aoMudar: (local) => setState(() => _local = local),
                  ),
                  if (semLocal)
                    const _Recado(
                      'Marque no mapa onde fica, com rua e bairro.',
                      erro: true,
                    ),
                ],
              ),
            ),
            _Cartao(
              icone: Icons.event_outlined,
              titulo: 'Quando',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _escolherData,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      _data == null
                          ? 'Escolher a data'
                          : '${_data!.day.toString().padLeft(2, '0')}/'
                                '${_data!.month.toString().padLeft(2, '0')}/'
                                '${_data!.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.cores.principal,
                      side: BorderSide(color: context.cores.principal),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const _Recado('Opcional: deixe em branco se não souber.'),
                ],
              ),
            ),
            _Cartao(
              icone: Icons.photo_camera_outlined,
              titulo: 'Fotos',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 92,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (var i = 0; i < _fotos.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _Miniatura(
                              caminho: _fotos[i].path,
                              aoRemover: () =>
                                  setState(() => _fotos.removeAt(i)),
                            ),
                          ),
                        if (_fotos.length < _maximoDeFotos)
                          _AdicionarFoto(
                            aoTocar: _adicionarFotos,
                            comErro: semFoto,
                          ),
                      ],
                    ),
                  ),
                  _Recado(
                    semFoto
                        ? 'Adicione pelo menos uma foto.'
                        : 'De 1 a $_maximoDeFotos fotos. Fotografe só se for '
                              'seguro.',
                    erro: semFoto,
                  ),
                ],
              ),
            ),
            _Cartao(
              icone: Icons.shield_outlined,
              titulo: 'Identificação',
              // Material transparente: o toque da chave aparece por cima do
              // cartão, que tem cor
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      value: _anonima,
                      onChanged: (anonima) =>
                          setState(() => _anonima = anonima),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: context.cores.principal,
                      title: const Text(
                        'Enviar sem me identificar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _anonima
                            ? 'Seu nome e seu contato não vão junto com a '
                                  'denúncia.'
                            : 'Seu nome e seu telefone vão junto, caso seja '
                                  'preciso falar com você.',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.cores.textoFraco,
                        ),
                      ),
                    ),
                  ),
                  if (semContato)
                    const _Recado(
                      'Seu perfil está sem nome ou telefone. Complete o '
                      'perfil ou envie sem se identificar.',
                      erro: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.sobrePrincipal,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(_enviando ? 'Registrando…' : 'Registrar denúncia'),
              style: FilledButton.styleFrom(
                backgroundColor: context.cores.principal,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A abertura: o que é maus-tratos e o que diz a lei, com o trecho do art. 32
// na barra verde das citações do app
class _OQueDizALei extends StatelessWidget {
  const _OQueDizALei();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cores.principalClara,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maus-tratos a animais é crime',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.cores.principal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Abandono, agressão, ferimentos e falta de cuidados básicos podem '
            'configurar maus-tratos. Sua denúncia ajuda a proteger o animal.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: context.cores.texto,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: context.cores.principal, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Praticar ato de abuso, maus-tratos, ferir ou mutilar '
                  'animais silvestres, domésticos ou domesticados, nativos ou '
                  'exóticos."',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                    color: context.cores.texto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lei nº 9.605/1998, art. 32',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.cores.principal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Quando se trata de cão ou gato, a pena é de reclusão de 2 a 5 '
            'anos, multa e proibição da guarda (Lei nº 14.064/2020).',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: context.cores.textoFraco,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Relate apenas o que você viu. Se o animal ou alguém correr '
            'perigo agora, ligue 190.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: context.cores.texto,
            ),
          ),
        ],
      ),
    );
  }
}

// Depois de registrar: o protocolo em destaque, para copiar, e o
// encaminhamento à APAF pelo WhatsApp com a denúncia já escrita
class _DenunciaRegistrada extends StatelessWidget {
  const _DenunciaRegistrada({required this.denuncia});

  final Denuncia denuncia;

  Future<void> _encaminhar(BuildContext context) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final texto = Uri.encodeComponent(denuncia.mensagemParaOCanal);
    final abriu = await launchUrl(
      Uri.parse('https://wa.me/$whatsAppDoCanalDeDenuncia?text=$texto'),
      mode: LaunchMode.externalApplication,
    );
    if (!abriu) {
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o WhatsApp neste aparelho.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 44,
              color: context.cores.principal,
            ),
            const SizedBox(height: 8),
            const Text(
              'Denúncia registrada',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Guarde o protocolo para acompanhar em Minhas denúncias.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.cores.textoFraco),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
              decoration: BoxDecoration(
                color: context.cores.principalClara,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROTOCOLO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: context.cores.principal,
                          ),
                        ),
                        Text(
                          denuncia.protocolo,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: context.cores.texto,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final mensageiro = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                        ClipboardData(text: denuncia.protocolo),
                      );
                      mensageiro
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Protocolo copiado.')),
                        );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.cores.principal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Enquanto não há um canal oficial no aplicativo, envie a '
              'denúncia à $nomeDoCanalDeDenuncia, a Associação Protetora dos '
              'Animais de Formiga.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.cores.textoFraco,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _encaminhar(context),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text('Enviar à $nomeDoCanalDeDenuncia pelo WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.cores.principal,
                  foregroundColor: context.sobrePrincipal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: context.cores.textoFraco,
              ),
              child: const Text('Concluir'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.icone,
    required this.titulo,
    required this.child,
  });

  final IconData icone;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: context.cores.principal),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  color: context.cores.principal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: context.cores.textoFraco,
    ),
  );
}

class _Recado extends StatelessWidget {
  const _Recado(this.texto, {this.erro = false});

  final String texto;
  final bool erro;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 2),
    child: Text(
      texto,
      style: TextStyle(
        fontSize: 12,
        color: erro ? context.cores.destaque : context.cores.textoFraco,
      ),
    ),
  );
}

// A mesma caixa dos campos do cadastro de animal
InputDecoration _caixa(
  BuildContext context,
  String? dica, {
  bool comErro = false,
}) => InputDecoration(
  isDense: true,
  filled: true,
  fillColor: context.cores.fundo,
  hintText: dica,
  hintMaxLines: 3,
  counterText: '',
  hintStyle: TextStyle(fontSize: 14, color: context.cores.textoFraco),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: comErro ? context.cores.destaque : context.cores.borda,
      width: comErro ? 1.5 : 1,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: comErro ? context.cores.destaque : context.cores.principal,
      width: 1.5,
    ),
  ),
);

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.caminho, required this.aoRemover});

  final String caminho;
  final VoidCallback aoRemover;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Stack(
        children: [
          FotoAnimal(caminho: caminho, altura: 92),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: context.cores.cartao,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: aoRemover,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: context.cores.texto,
                    semanticLabel: 'Remover foto',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdicionarFoto extends StatelessWidget {
  const _AdicionarFoto({required this.aoTocar, required this.comErro});

  final VoidCallback aoTocar;
  final bool comErro;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cores.principalClara,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: comErro
            ? BorderSide(color: context.cores.destaque, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 92,
          height: 92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: context.cores.principal),
              const SizedBox(height: 4),
              Text(
                'Adicionar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.cores.principal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
