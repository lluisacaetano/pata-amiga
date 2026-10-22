import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/ong.dart';
import '../provider/usuario_provider.dart';
import '../services/ong_service.dart';
import '../tema/cores.dart';
import '../widgets/proteger_alteracoes.dart';
import '../widgets/avatar_da_ong.dart';
import '../widgets/mapa_de_local.dart';
import '../widgets/mascaras.dart';
import '../widgets/seletor_de_local.dart';

// Criar ou editar o perfil da ONG de quem está logado, no padrão do cadastro
// de animal. Só a foto é opcional, porque as iniciais ficam no lugar dela;
// porque nem todo abrigo quer receber doação pelo app
class CadastroOng extends StatefulWidget {
  final Ong? editando;
  final OngService? servico;

  const CadastroOng({super.key, this.editando, this.servico});

  @override
  State<CadastroOng> createState() => _CadastroOngState();
}

class _CadastroOngState extends State<CadastroOng> {
  late final _servico = widget.servico ?? OngService();
  final _seletorDeFoto = ImagePicker();
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _telefone = TextEditingController();
  final _chavePix = TextEditingController();
  final _politica = TextEditingController();
  String _foto = '';
  LocalEscolhido _local = (ponto: centroDeFormiga, rua: '', bairro: '');
  bool _tentou = false;
  bool _salvando = false;
  final _rolagem = ScrollController();
  // O formulário como abriu, para saber se algo mudou
  String _inicial = '';
  String get _assinatura => [
    _nome.text,
    _descricao.text,
    _telefone.text,
    _chavePix.text,
    _politica.text,
    _foto,
    // O pino do mapa conta: mexer nele sem querer também é uma mudança
    _local.ponto.latitude.toStringAsFixed(5),
    _local.ponto.longitude.toStringAsFixed(5),
  ].map((parte) => parte.trim()).join('|');

  // Outra ONG já usa o nome digitado
  bool _nomeRepetido = false;
  // A ONG que está sendo editada. Cada conta tem no máximo uma: quem já tem
  // ONG e abre o cadastro edita a que existe, em vez de criar outra
  Ong? _editando;

  @override
  void initState() {
    super.initState();
    // O ponto de partida é o formulário já preenchido, depois do initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicial = _assinatura;
    });
    final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
    _editando = widget.editando ?? PataAmigaScope.talvez(context)?.ongDe(email);
    final ong = _editando;
    if (ong == null) {
      // A ONG costuma atender pelo telefone de quem cria o perfil
      final usuario = context.read<UsuarioProvider?>()?.usuario;
      _telefone.text = formatarTelefone(usuario?.telefone ?? '');
      return;
    }
    _preencher(ong);
  }

  // Só quem administra a ONG muda os dados dela, como a chave Pix: quem entrou
  // por aprovação publica animais em nome da ONG, mas não edita o perfil
  bool get _podeEditar {
    final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
    return _editando == null || _editando!.eDoResponsavel(email);
  }

  // O formulário com os dados da ONG que está sendo editada
  void _preencher(Ong ong) {
    _local = ong.temLocal
        ? (
            ponto: LatLng(ong.latitude!, ong.longitude!),
            rua: ong.rua,
            bairro: ong.bairro,
          )
        : (ponto: centroDeFormiga, rua: '', bairro: '');
    _nome.text = ong.nome;
    _descricao.text = ong.descricao;
    _telefone.text = formatarTelefone(ong.telefone);
    _chavePix.text = ong.chavePix;
    _politica.text = ong.politicaDeAdocao;
    _foto = ong.foto;
  }

  @override
  void dispose() {
    _rolagem.dispose();
    for (final campo in [_nome, _descricao, _telefone, _chavePix, _politica]) {
      campo.dispose();
    }
    super.dispose();
  }

  bool _faltando(TextEditingController campo) =>
      _tentou && campo.text.trim().isEmpty;

  Future<void> _escolherFoto() async {
    try {
      final foto = await _seletorDeFoto.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (foto != null && mounted) setState(() => _foto = foto.path);
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

  // O telefone vira o WhatsApp do perfil: precisa do DDD
  bool get _telefoneValido =>
      _telefone.text.replaceAll(RegExp(r'\D'), '').length >= 10;

  // Tudo o que o perfil mostra é obrigatório, menos a foto
  bool get _completo =>
      [
        _nome,
        _descricao,
        _politica,
        _chavePix,
      ].every((campo) => campo.text.trim().isNotEmpty) &&
      _telefoneValido &&
      _local.rua.trim().isNotEmpty &&
      _local.bairro.trim().isNotEmpty;

  Future<void> _salvar() async {
    setState(() => _tentou = true);
    if (_salvando || !_podeEditar) return;
    if (!_completo) {
      // O botão fica no fim e os campos em vermelho lá em cima: a tela sobe
      // até eles e avisa
      _avisar('Preencha os campos obrigatórios marcados em vermelho.');
      _rolagem.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    setState(() => _salvando = true);
    final estado = PataAmigaScope.of(context);
    final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
    final antes = _editando;
    try {
      // A ONG pode ter sido criada em outro aparelho: antes de criar, confere
      // na API se o e-mail já tem uma
      final ongs = await _servico.buscarOngs();
      // Duas ONGs com o mesmo nome confundem quem quer doar
      if (ongs.any((ong) => ong.id != antes?.id && ong.temNome(_nome.text))) {
        if (!mounted) return;
        setState(() {
          _salvando = false;
          _nomeRepetido = true;
        });
        return;
      }
      if (antes == null) {
        // Quem espera resposta de uma ONG também não cria outra: aprovado
        // depois, ficaria em duas
        final pedida = ongs.where((ong) => ong.pediuEntrada(email));
        if (pedida.isNotEmpty) {
          if (!mounted) return;
          setState(() => _salvando = false);
          _avisar(
            'Você pediu para entrar em ${pedida.first.nome}. Cada conta pode '
            'ter só uma ONG.',
          );
          return;
        }
        final existente = ongs.where((ong) => ong.fazParte(email));
        if (existente.isNotEmpty) {
          estado.salvarOng(existente.first);
          if (!mounted) return;
          // O formulário passa a mostrar a ONG que já existe, para o próximo
          // salvar não a trocar pelo que foi digitado aqui
          setState(() {
            _salvando = false;
            _editando = existente.first;
            _preencher(existente.first);
          });
          // O formulário passou a ser o da ONG que existe: é ele o ponto de
          // partida do "sair sem salvar"
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _inicial = _assinatura;
          });
          _avisar(
            'Sua conta já faz parte da ONG ${existente.first.nome}. Cada '
            'conta pode ter só uma.',
          );
          return;
        }
      }
      // Na edição, quem faz parte e quem pediu para entrar vêm da API: um
      // pedido pode ter chegado enquanto o formulário estava aberto
      final naApi = antes?.id == null
          ? null
          : await _servico.buscarOng(antes!.id!);
      // A administração pode ter mudado em outro aparelho: quem não
      // administra mais não grava por cima
      if (naApi != null && !naApi.eDoResponsavel(email)) {
        if (!mounted) return;
        setState(() {
          _salvando = false;
          _editando = naApi;
        });
        _avisar('Você não administra mais ${naApi.nome}.');
        return;
      }
      final salva = await _servico.salvarOng(
        Ong(
          id: antes?.id,
          nome: _nome.text.trim(),
          descricao: _descricao.text.trim(),
          politicaDeAdocao: _politica.text.trim(),
          telefone: _telefone.text.replaceAll(RegExp(r'\D'), ''),
          chavePix: _chavePix.text.trim(),
          foto: _foto,
          rua: _local.rua,
          bairro: _local.bairro,
          latitude: _local.ponto.latitude,
          longitude: _local.ponto.longitude,
          // Na edição, a ONG continua de quem a administra
          responsavelEmail: naApi?.responsavelEmail ?? email,
          criadaEm: antes?.criadaEm ?? DateTime.now(),
          membros: naApi?.membros ?? const [],
          pedidos: naApi?.pedidos ?? const [],
        ),
      );
      estado.salvarOng(salva);
      if (!mounted) return;
      Navigator.pop(context, salva);
    } on Exception {
      if (!mounted) return;
      setState(() => _salvando = false);
      _avisar('Não foi possível salvar agora. Tente de novo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = _editando != null;
    // Com algo mudado e não salvo, voltar pergunta antes de sair
    return ProtegerAlteracoes(
      alterado: () => _assinatura != _inicial && !_salvando,
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
          title: Text(
            editando ? 'EDITAR PERFIL DA ONG' : 'PERFIL DA ONG',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Cores.principal,
            ),
          ),
        ),
        body: !_podeEditar
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 44,
                      color: Cores.principal,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Só quem administra esta ONG pode mudar os dados '
                      'dela, como a chave Pix.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ],
                ),
              )
            : ListView(
                controller: _rolagem,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // A foto como no "Editar perfil": o círculo com a câmera, que
                  // mostra as iniciais do nome enquanto não há foto
                  Center(
                    child: Semantics(
                      button: true,
                      label: 'Escolher a foto da ONG',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _escolherFoto,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ListenableBuilder(
                              listenable: _nome,
                              builder: (context, _) => AvatarDaOng(
                                raio: 56,
                                ong: Ong(
                                  nome: _nome.text,
                                  descricao: '',
                                  telefone: '',
                                  foto: _foto,
                                  responsavelEmail: '',
                                  criadaEm: DateTime(0),
                                ),
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
                                child: const CircleAvatar(
                                  radius: 17,
                                  backgroundColor: Cores.principal,
                                  child: Icon(
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: _escolherFoto,
                      style: TextButton.styleFrom(
                        foregroundColor: Cores.principal,
                      ),
                      child: Text(
                        _foto.isEmpty ? 'Escolher foto' : 'Trocar foto',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Cartao(
                    icone: Icons.volunteer_activism_outlined,
                    titulo: 'A ONG',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Campo(
                          rotulo: 'Nome',
                          controlador: _nome,
                          exemplo: 'Nome da ONG ou do abrigo',
                          comErro: _faltando(_nome) || _nomeRepetido,
                          erro: _nomeRepetido
                              ? 'Já existe uma ONG com esse nome.'
                              : null,
                          aoMudar: (_) {
                            if (_nomeRepetido) {
                              setState(() => _nomeRepetido = false);
                            }
                          },
                          palavras: true,
                        ),
                        const SizedBox(height: 14),
                        _Campo(
                          rotulo: 'Descrição',
                          controlador: _descricao,
                          exemplo: 'O que a ONG faz e há quanto tempo',
                          linhas: 4,
                          comErro: _faltando(_descricao),
                        ),
                        const SizedBox(height: 14),
                        _Campo(
                          rotulo: 'Política de adoção',
                          controlador: _politica,
                          exemplo: 'Ex.: entrevista, visita e termo de adoção',
                          linhas: 4,
                          comErro: _faltando(_politica),
                        ),
                      ],
                    ),
                  ),
                  _Cartao(
                    icone: Icons.call_outlined,
                    titulo: 'Contato e doações',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Campo(
                          rotulo: 'Telefone (WhatsApp)',
                          controlador: _telefone,
                          exemplo: '(37) 99999-0000',
                          teclado: TextInputType.phone,
                          formatadores: [MascaraDeTelefone()],
                          comErro: _tentou && !_telefoneValido,
                          erro: _faltando(_telefone)
                              ? null
                              : 'Digite um telefone com DDD.',
                        ),
                        const SizedBox(height: 14),
                        _Campo(
                          rotulo: 'Chave Pix',
                          controlador: _chavePix,
                          comErro: _faltando(_chavePix),
                          exemplo: 'E-mail, telefone, CNPJ ou chave aleatória',
                          aviso:
                              'A chave só aparece no perfil: a doação é feita pelo '
                              'aplicativo do banco de quem doa.',
                        ),
                      ],
                    ),
                  ),
                  _Cartao(
                    icone: Icons.location_on_outlined,
                    titulo: 'Onde fica',
                    // A chave refaz o mapa quando a ONG editada muda
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SeletorDeLocal(
                          key: ValueKey(_editando?.id),
                          inicio: _local.ponto,
                          // O mapa relê o endereço do pino ao abrir; na edição, ele só
                          // troca o endereço salvo se o pino tiver mudado
                          aoMudar: (local) {
                            final salva = _editando;
                            if (salva != null &&
                                salva.temLocal &&
                                local.ponto.latitude == salva.latitude &&
                                local.ponto.longitude == salva.longitude) {
                              return;
                            }
                            _local = local;
                          },
                        ),
                        if (_tentou &&
                            (_local.rua.trim().isEmpty ||
                                _local.bairro.trim().isEmpty))
                          const Padding(
                            padding: EdgeInsets.only(top: 6, left: 2),
                            child: Text(
                              'Marque no mapa onde fica a ONG, com rua e '
                              'bairro.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Cores.destaque,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  FilledButton(
                    onPressed: _salvando ? null : _salvar,
                    style: FilledButton.styleFrom(
                      backgroundColor: Cores.principal,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(
                      _salvando
                          ? 'Salvando…'
                          : editando
                          ? 'Salvar alterações'
                          : 'Criar perfil da ONG',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// O mesmo cartão do cadastro de animal: branco, borda clara e título verde
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
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: Cores.principal),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  color: Cores.principal,
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

class _Campo extends StatelessWidget {
  final String rotulo;
  final TextEditingController controlador;
  final String exemplo;
  final String? aviso;
  final int linhas;
  final bool comErro;
  final bool palavras;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatadores;
  final String? erro;
  final ValueChanged<String>? aoMudar;

  const _Campo({
    required this.rotulo,
    required this.controlador,
    required this.exemplo,
    this.aviso,
    this.linhas = 1,
    this.comErro = false,
    this.palavras = false,
    this.teclado,
    this.formatadores,
    this.erro,
    this.aoMudar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Cores.textoFraco,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controlador,
          onChanged: aoMudar,
          minLines: linhas,
          maxLines: linhas == 1 ? 1 : null,
          keyboardType: linhas > 1 ? TextInputType.multiline : teclado,
          inputFormatters: formatadores,
          textCapitalization: palavras
              ? TextCapitalization.words
              : TextCapitalization.sentences,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Cores.fundo,
            hintText: exemplo,
            hintStyle: const TextStyle(fontSize: 14, color: Cores.textoFraco),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: comErro ? Cores.destaque : Cores.borda,
                width: comErro ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: comErro ? Cores.destaque : Cores.principal,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (comErro || aviso != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(
              comErro ? erro ?? 'Campo obrigatório' : aviso!,
              style: TextStyle(
                fontSize: 12,
                color: comErro ? Cores.destaque : Cores.textoFraco,
              ),
            ),
          ),
      ],
    );
  }
}
