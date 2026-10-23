// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter/services: erro da galeria e formatadores de texto.
import 'package:flutter/services.dart';
// Pacote image_picker: abre a câmera ou a galeria para escolher fotos.
import 'package:image_picker/image_picker.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo estado_pata_amiga.dart: estado compartilhado com as ONGs.
import '../estado/estado_pata_amiga.dart';
// Arquivo ong.dart: modelo da ONG.
import '../modelos/ong.dart';
// Arquivo usuario_provider.dart: usuário logado.
import '../provider/usuario_provider.dart';
// Arquivo ong_service.dart: leitura e gravação das ONGs na API.
import '../services/ong_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo proteger_alteracoes.dart: confirmação ao sair sem salvar.
import '../widgets/proteger_alteracoes.dart';
// Arquivo avatar_da_ong.dart: avatar da ONG com foto ou iniciais.
import '../widgets/avatar_da_ong.dart';
// Arquivo mapa_de_local.dart: ponto central de Formiga no mapa.
import '../widgets/mapa_de_local.dart';
// Arquivo mascaras.dart: máscara e formatação do telefone.
import '../widgets/mascaras.dart';
// Arquivo seletor_de_local.dart: escolha do endereço no mapa.
import '../widgets/seletor_de_local.dart';

// Formulário para criar ou editar o perfil da ONG do usuário logado. Todos
// os campos são obrigatórios, exceto a foto (sem ela, o avatar mostra as
// iniciais do nome). Só o administrador da ONG pode editar
class CadastroOng extends StatefulWidget {
  // ONG a editar; nula para criar uma nova
  final Ong? editando;
  // Serviço opcional, para os testes injetarem uma versão falsa
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
  // Assinatura do formulário ao abrir, para detectar alterações não salvas
  String _inicial = '';
  // Junta os valores do formulário numa única string comparável
  String get _assinatura => [
    _nome.text,
    _descricao.text,
    _telefone.text,
    _chavePix.text,
    _politica.text,
    _foto,
    // A posição do pino também conta como alteração
    _local.ponto.latitude.toStringAsFixed(5),
    _local.ponto.longitude.toStringAsFixed(5),
  ].map((parte) => parte.trim()).join('|');

  // Verdadeiro quando outra ONG já usa o nome digitado
  bool _nomeRepetido = false;
  // ONG em edição. Cada conta tem no máximo uma: se o usuário já tem ONG, o
  // formulário edita a existente em vez de criar outra
  Ong? _editando;

  @override
  void initState() {
    super.initState();
    // A assinatura inicial é tirada após o primeiro quadro, com o formulário
    // já preenchido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicial = _assinatura;
    });
    final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
    _editando = widget.editando ?? PataAmigaScope.talvez(context)?.ongDe(email);
    final ong = _editando;
    if (ong == null) {
      // Nova ONG: sugere o telefone de quem está criando o perfil
      final usuario = context.read<UsuarioProvider?>()?.usuario;
      _telefone.text = formatarTelefone(usuario?.telefone ?? '');
      return;
    }
    _preencher(ong);
  }

  // Só o administrador edita os dados da ONG. Membros aprovados publicam
  // animais em nome dela, mas não alteram o perfil
  bool get _podeEditar {
    final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
    return _editando == null || _editando!.eDoResponsavel(email);
  }

  // Preenche o formulário com os dados de uma ONG existente
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

  // Campo obrigatório vazio, depois de uma tentativa de salvar
  bool _faltando(TextEditingController campo) =>
      _tentou && campo.text.trim().isEmpty;

  // Abre a galeria para escolher a foto de perfil da ONG
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

  // Mostra uma mensagem curta no rodapé, substituindo a anterior
  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // O telefone é usado como WhatsApp da ONG, por isso exige o DDD
  // (10 dígitos ou mais)
  bool get _telefoneValido =>
      _telefone.text.replaceAll(RegExp(r'\D'), '').length >= 10;

  // Todos os campos obrigatórios preenchidos, com endereço completo no mapa
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

  // Valida e grava a ONG na API. Antes de gravar, consulta a API para
  // impedir nome repetido, ONG duplicada para a mesma conta e edição por quem
  // deixou de ser administrador
  Future<void> _salvar() async {
    setState(() => _tentou = true);
    if (_salvando || !_podeEditar) return;
    if (!_completo) {
      // Rola até o topo, onde estão os campos marcados em vermelho
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
      // Consulta a API, pois a ONG pode ter sido criada ou alterada em outro
      // aparelho
      final ongs = await _servico.buscarOngs();
      // Não permite duas ONGs com o mesmo nome
      if (ongs.any((ong) => ong.id != antes?.id && ong.temNome(_nome.text))) {
        if (!mounted) return;
        setState(() {
          _salvando = false;
          _nomeRepetido = true;
        });
        return;
      }
      if (antes == null) {
        // Quem tem pedido de entrada pendente em outra ONG não pode criar
        // uma, pois ficaria em duas se fosse aprovado
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
          // A conta já participa de uma ONG: o formulário passa a editá-la,
          // para não sobrescrevê-la com o que foi digitado
          setState(() {
            _salvando = false;
            _editando = existente.first;
            _preencher(existente.first);
          });
          // Atualiza a assinatura inicial para a ONG carregada
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
      // Na edição, membros e pedidos são lidos da API, pois podem ter mudado
      // com o formulário aberto
      final naApi = antes?.id == null
          ? null
          : await _servico.buscarOng(antes!.id!);
      // Impede a gravação se o usuário deixou de administrar a ONG
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
          // Na edição, mantém o administrador registrado na API
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
    // Pede confirmação ao sair com alterações não salvas
    return ProtegerAlteracoes(
      alterado: () => _assinatura != _inicial && !_salvando,
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
            editando ? 'EDITAR PERFIL DA ONG' : 'PERFIL DA ONG',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: context.cores.principal,
            ),
          ),
        ),
        body: !_podeEditar
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 44,
                      color: context.cores.principal,
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
                  // Avatar tocável com ícone de câmera; sem foto, mostra as
                  // iniciais do nome digitado
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
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.cores.fundo,
                                ),
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundColor: context.cores.principal,
                                  child: Icon(
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: _escolherFoto,
                      style: TextButton.styleFrom(
                        foregroundColor: context.cores.principal,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // A chave recria o mapa quando a ONG em edição muda
                        SeletorDeLocal(
                          key: ValueKey(_editando?.id),
                          inicio: _local.ponto,
                          // O mapa relê o endereço ao abrir. Na edição, o
                          // endereço salvo só muda se o pino for movido
                          aoMudar: (local) {
                            final salva = _editando;
                            if (salva != null &&
                                salva.temLocal &&
                                local.ponto.latitude == salva.latitude &&
                                local.ponto.longitude == salva.longitude) {
                              return;
                            }
                            // Reconstrói para o aviso de endereço faltando
                            // sumir assim que o pino tiver rua e bairro
                            setState(() => _local = local);
                          },
                        ),
                        if (_tentou &&
                            (_local.rua.trim().isEmpty ||
                                _local.bairro.trim().isEmpty))
                          Padding(
                            padding: EdgeInsets.only(top: 6, left: 2),
                            child: Text(
                              'Marque no mapa onde fica a ONG, com rua e '
                              'bairro.',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.cores.destaque,
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

// Cartão de seção do formulário, com ícone e título
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

// Campo de texto com rótulo acima e mensagem de erro ou aviso abaixo
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: context.cores.textoFraco,
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
            fillColor: context.cores.fundo,
            hintText: exemplo,
            hintStyle: TextStyle(fontSize: 14, color: context.cores.textoFraco),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
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
                color: comErro
                    ? context.cores.destaque
                    : context.cores.principal,
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
                color: comErro
                    ? context.cores.destaque
                    : context.cores.textoFraco,
              ),
            ),
          ),
      ],
    );
  }
}
