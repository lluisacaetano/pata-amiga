// Biblioteca dart:async: Timer da verificação periódica e unawaited.
import 'dart:async';

// Pacote flutter/foundation: kIsWeb, para não ler arquivo local na web.
import 'package:flutter/foundation.dart';
// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter/services: leitura dos assets (rootBundle).
import 'package:flutter/services.dart';
// Pacote http: faz as requisições à API (GET, POST, PATCH, DELETE).
import 'package:http/http.dart' as http;
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';
// Pacote share_plus: abre o compartilhamento do sistema (WhatsApp etc.).
import 'package:share_plus/share_plus.dart';
// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';
// Pacote url_launcher: abre WhatsApp, telefone e links no navegador.
import 'package:url_launcher/url_launcher.dart';

// Arquivo estado_pata_amiga.dart: estado compartilhado de animais, ONGs e mapa.
import '../estado/estado_pata_amiga.dart';
// Arquivo animal.dart: modelo do animal e o tipo do registro.
import '../modelos/animal.dart';
// Arquivo dono.dart: número do responsável no formato do WhatsApp.
import '../modelos/dono.dart';
// Arquivo filtros_do_feed.dart: filtros do feed e os grupos de filtro.
import '../modelos/filtros_do_feed.dart';
// Arquivo ong.dart: modelo da ONG, para o nome nas etiquetas de filtro.
import '../modelos/ong.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo barra_inferior.dart: barra de navegação inferior.
import '../widgets/barra_inferior.dart';
// Arquivo aviso_no_centro.dart: aviso centralizado de lista vazia ou erro.
import '../widgets/aviso_no_centro.dart';
// Arquivo card_animal.dart: card de cada animal do feed.
import '../widgets/card_animal.dart';
// Arquivo painel_de_confirmacao.dart: painel inferior do pedido de localização.
import '../widgets/painel_de_confirmacao.dart';
// Arquivo escolha_de_tipo.dart: abas de adoção, perdidos e resgates.
import '../widgets/escolha_de_tipo.dart';
// Arquivo painel_de_filtros.dart: painel inferior com os filtros.
import '../widgets/painel_de_filtros.dart';
// Arquivo app_router.dart: rotas do aplicativo e os nomes delas (AppRoutes).
import '../routes/app_router.dart';
// Arquivo alimentacao_service.dart: pontos de alimentação na API.
import '../services/alimentacao_service.dart';
// Arquivo animal_service.dart: busca e cadastro de animais na API.
import '../services/animal_service.dart';
// Arquivo denuncia.dart: lista vazia de denúncias, sem organização.
import '../modelos/denuncia.dart';
// Arquivo avistamento.dart: último avistamento, que ordena os perdidos.
import '../modelos/avistamento.dart';
// Arquivo avistamento_service.dart: avistamentos na API.
import '../services/avistamento_service.dart';
// Arquivo cache_service.dart: cache local dos animais do feed.
import '../services/cache_service.dart';
// Arquivo denuncia_service.dart: denúncias para as notificações.
import '../services/denuncia_service.dart';
// Arquivo localizacao_service.dart: posição do aparelho para as notificações.
import '../services/localizacao_service.dart';
// Arquivo ong_service.dart: ONGs na API.
import '../services/ong_service.dart';
// Arquivo usuario_provider.dart: usuário logado.
import '../provider/usuario_provider.dart';
// Arquivo sino_de_notificacoes.dart: pedidos de vínculo e vibração de aviso.
import '../widgets/sino_de_notificacoes.dart';

// Origem dos dados exibidos no feed: carregando, cache do aparelho, API ou
// erro (sem API e sem cache)
enum EstadoFeed { carregando, cache, atualizado, erro }

// Tela principal: feed de animais com abas por tipo de registro, pesquisa,
// filtros, banner de dados em cache e botão para cadastrar um animal
class FeedAdocao extends StatefulWidget {
  // Serviços opcionais: o app usa as implementações reais e os testes
  // injetam versões falsas para não depender da API
  final AnimalService? api;
  final CacheService? cache;
  final AvistamentoService? avistamentos;
  final AlimentacaoService? alimentacao;
  final OngService? ongs;
  final LocalizacaoService? localizacao;
  final DenunciaService? denuncias;

  const FeedAdocao({
    super.key,
    this.api,
    this.cache,
    this.avistamentos,
    this.alimentacao,
    this.ongs,
    this.localizacao,
    this.denuncias,
  });

  @override
  State<FeedAdocao> createState() => _FeedAdocaoState();
}

class _FeedAdocaoState extends State<FeedAdocao> {
  // Aba aberta no momento, que decide quais animais o feed mostra
  TipoRegistro _abaAtual = TipoRegistro.adocao;

  // Animais cadastrados neste aparelho que não chegaram à API
  final List<Animal> _animaisCriados = [];

  // Texto digitado no campo de pesquisa
  final _pesquisa = TextEditingController();
  String _busca = '';

  // Filtros aplicados: valem nas três abas e se somam à pesquisa
  FiltrosDoFeed _filtros = const FiltrosDoFeed();

  // Serviços de dados
  late final _api = widget.api ?? AnimalService();
  late final _cache = widget.cache ?? CacheService();
  late final _avistamentos = widget.avistamentos ?? AvistamentoService();
  late final _alimentacao = widget.alimentacao ?? AlimentacaoService();
  late final _ongs = widget.ongs ?? OngService();
  late final _localizacao = widget.localizacao ?? const LocalizacaoService();
  late final _denuncias = widget.denuncias ?? DenunciaService();

  // Animais recebidos da API ou lidos do cache
  List<Animal> _animaisApi = [];

  // Estado atual da tela e dados usados pelo banner
  EstadoFeed _estado = EstadoFeed.carregando;
  // Momento em que os dados exibidos foram salvos ou atualizados
  DateTime? _dataCache;
  // Verdadeiro enquanto há uma busca na API em andamento
  bool _atualizando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _pararDeVigiar();
    _ciclo?.dispose();
    _pesquisa.dispose();
    super.dispose();
  }

  // Carrega os avistamentos para o estado compartilhado. Uma falha aqui não
  // afeta o feed; só o mapa fica sem o último ponto visto
  Future<void> _carregarAvistamentos() async {
    try {
      final lista = await _avistamentos.buscarTodos();
      if (!mounted) return;
      PataAmigaScope.of(context).atualizarAvistamentos(lista);
    } on Exception {
      // Falha ignorada: tenta de novo no próximo carregamento
    }
  }

  // Carrega os pontos de alimentação e os abastecimentos para o mapa. Uma
  // falha aqui também não afeta o feed
  Future<void> _carregarAlimentacao() async {
    try {
      final pontos = await _alimentacao.buscarPontos();
      final abastecimentos = await _alimentacao.buscarAbastecimentos();
      if (!mounted) return;
      PataAmigaScope.of(context).atualizarAlimentacao(pontos, abastecimentos);
    } on Exception {
      // Falha ignorada: o mapa fica sem a camada de alimentação
    }
  }

  // Verificação periódica (a cada 30 segundos com o app aberto) das ONGs,
  // dos animais, dos avistamentos e da posição do aparelho, para avisar
  // quando chega uma notificação nova
  Timer? _vigia;
  // Notificações já conhecidas; nulo até a primeira conferência, que só
  // define a base
  Set<String>? _notificacoesConhecidas;
  // Suspende a verificação com o app em segundo plano e retoma ao voltar
  AppLifecycleListener? _ciclo;

  // Inicia o timer da verificação, se ainda não estiver ativo
  void _vigiar() => _vigia ??= Timer.periodic(
    const Duration(seconds: 30),
    (_) => _verificarNovidades(),
  );

  void _pararDeVigiar() {
    _vigia?.cancel();
    _vigia = null;
  }

  // Atualiza as ONGs no estado compartilhado
  Future<void> _carregarOngs() async {
    try {
      final ongs = await _ongs.buscarOngs();
      if (!mounted) return;
      PataAmigaScope.of(context).atualizarOngs(ongs);
    } on Exception {
      // Falha ignorada: mantém as ONGs já carregadas
    }
  }

  // Busca os animais na API sem mexer no estado da tela, para que um
  // animal perdido novo na região vire notificação
  Future<void> _atualizarAnimais() async {
    try {
      final novos = await _api.buscarAnimais();
      await _cache.salvarAnimais(novos);
      if (!mounted) return;
      setState(() => _animaisApi = novos);
      PataAmigaScope.of(context)
          .atualizarAnimais([..._animaisApi, ..._animaisCriados]);
    } on Exception {
      // Falha ignorada: mantém os animais já carregados
    }
  }

  // Lê a posição do aparelho, sem pedir permissão, para as notificações de
  // animais perdidos na região
  Future<void> _atualizarPosicao() async {
    final posicao = await _localizacao.posicaoSemPedir();
    if (posicao == null || !mounted) return;
    PataAmigaScope.of(context).atualizarPosicao(posicao);
  }

  // Busca as denúncias recebidas pela organização de quem está logado (se
  // ela recebe denúncias) e as feitas neste aparelho, para as notificações
  Future<void> _carregarDenuncias() async {
    try {
      final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
      final organizacao = PataAmigaScope.of(context).ongDe(email);
      final recebidas = organizacao?.id != null && organizacao!.recebeDenuncias
          ? await _denuncias.daOrganizacao(organizacao.id!)
          : const <Denuncia>[];
      final minhas = await _denuncias.minhasDenuncias();
      if (!mounted) return;
      PataAmigaScope.of(
        context,
      ).atualizarDenuncias(daOrganizacao: recebidas, minhas: minhas);
    } on Exception {
      // Falha ignorada: mantém as denúncias já carregadas
    }
  }

  // Busca tudo o que pode gerar notificação e confere se chegou alguma nova
  Future<void> _verificarNovidades() async {
    await Future.wait([
      _carregarDenuncias(),
      _carregarOngs(),
      _carregarAvistamentos(),
      _atualizarAnimais(),
      _atualizarPosicao(),
    ]);
    await _conferirNotificacoes();
  }

  // Vibra o aparelho quando há uma notificação que não existia na última
  // conferência: pedido ou aviso de ONG, animal perdido na região ou
  // avistamento de um animal do usuário
  Future<void> _conferirNotificacoes() async {
    if (!mounted) return;
    final estado = PataAmigaScope.of(context);
    final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
    final atuais = {
      ...notificacoesPara(estado.ongs, email),
      for (final alerta in estado.alertasPara(email)) alerta.chave,
      for (final aviso in estado.avisosDeDenunciaPara(email)) aviso.chave,
    };
    final conhecidas = _notificacoesConhecidas;
    _notificacoesConhecidas = atuais;
    if (conhecidas != null && !conhecidas.containsAll(atuais)) {
      await avisarNovaNotificacao();
    }
  }

  // Carregamento principal, chamado ao abrir a tela e pelo botão "Tentar
  // atualizar":
  //   1. Com cache, mostra os dados salvos na hora (estado cache); sem
  //      cache, mostra o indicador de carregamento.
  //   2. Busca na API. Com sucesso, exibe os dados e sobrescreve o cache
  //      (estado atualizado). Com falha, mantém o cache ou, sem ele, passa
  //      ao estado de erro.
  // Também dispara as cargas paralelas e a verificação periódica das ONGs
  Future<void> _carregar() async {
    final salvos = await _cache.lerAnimais();
    final dataSalva = await _cache.dataDoCache();
    if (!mounted) return;

    setState(() {
      _atualizando = true;
      if (salvos != null) {
        _animaisApi = salvos;
        _dataCache = dataSalva;
        _estado = EstadoFeed.cache;
      } else {
        _estado = EstadoFeed.carregando;
      }
    });
    if (salvos != null) {
      PataAmigaScope.of(context)
          .atualizarAnimais([..._animaisApi, ..._animaisCriados]);
    }

    // As cargas que geram notificações correm junto com a dos animais; a
    // primeira conferência, ao fim de todas, só define a base
    final notificacoes = Future.wait([
      _carregarAvistamentos(),
      _carregarOngs().then((_) => _carregarDenuncias()),
      _atualizarPosicao(),
    ]);
    unawaited(_carregarAlimentacao());
    _vigiar();
    _ciclo ??= AppLifecycleListener(
      onPause: _pararDeVigiar,
      onResume: () {
        _verificarNovidades();
        _vigiar();
      },
    );
    try {
      final novos = await _api.buscarAnimais();
      // Toda resposta da API substitui o cache, que nunca fica defasado
      await _cache.salvarAnimais(novos);
      if (!mounted) return;
      setState(() {
        _animaisApi = novos;
        _dataCache = DateTime.now();
        _estado = EstadoFeed.atualizado;
        _atualizando = false;
      });
      PataAmigaScope.of(context)
          .atualizarAnimais([..._animaisApi, ..._animaisCriados]);
    } catch (_) {
      // Sem internet, servidor fora do ar ou tempo esgotado
      if (!mounted) return;
      setState(() {
        _atualizando = false;
        if (salvos == null) _estado = EstadoFeed.erro;
        // Com cache, o estado continua "cache" e a faixa do topo
        // avisa que os dados podem estar desatualizados
      });
    }
    await notificacoes;
    await _conferirNotificacoes();
    await _pedirLocalizacaoUmaVez();
  }

  // Na primeira abertura do feed, explica para que serve a localização e,
  // se a pessoa aceitar, abre o pedido de permissão do sistema. A pergunta
  // é feita uma única vez; depois, a permissão pode ser dada pela mira do
  // mapa
  Future<void> _pedirLocalizacaoUmaVez() async {
    const chave = 'localizacao_pedida';
    final armazenamento = await SharedPreferences.getInstance();
    if (armazenamento.getBool(chave) ?? false) return;
    if (!await _localizacao.podePedirPermissao() || !mounted) return;
    await armazenamento.setBool(chave, true);
    if (!mounted) return;
    final permitir = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.cores.cartao,
      showDragHandle: true,
      builder: (painel) => PainelDeConfirmacao(
        icone: Icons.location_on_outlined,
        titulo: 'Usar sua localização?',
        texto:
            'Ative a localização para ser avisado quando um animal se perder '
            'perto de você e para ver onde você está no mapa.',
        rotuloPrincipal: 'Permitir',
        aoPrincipal: () => Navigator.pop(painel, true),
        rotuloSecundario: 'Agora não',
        aoSecundario: () => Navigator.pop(painel, false),
      ),
    );
    if (permitir != true || !mounted) return;
    try {
      final posicao = await _localizacao.posicaoAtual();
      if (!mounted) return;
      PataAmigaScope.of(context).atualizarPosicao(posicao);
    } on ErroDeLocalizacao catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(erro.texto)));
    }
  }

  // Formata a data do cache no padrão "dd/mm às hh:mm"
  String _formatarData(DateTime? data) {
    if (data == null) return 'data desconhecida';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(data.day)}/${dois(data.month)} às '
        '${dois(data.hour)}:${dois(data.minute)}';
  }

  // Abre o cadastro e tenta salvar o animal na API. Se a API falhar, o
  // animal fica só neste aparelho e o usuário é avisado
  Future<void> _abrirCadastroAnimal() async {
    final animal = (await Navigator.pushNamed(
      context,
      AppRoutes.registerAnimal,
    )) as Animal?;
    if (!mounted || animal == null) return;

    final estado = PataAmigaScope.of(context);

    var salvoNaApi = false;
    try {
      await _api.criarAnimal(animal);
      salvoNaApi = true;
    } catch (_) {
      // API indisponível: o registro continua visível neste aparelho
    }

    await estado.registrarCadastro(animal);
    if (!mounted) return;
    // Garante que o animal novo apareça: abre a aba do tipo dele e limpa a
    // pesquisa. Como o feed é do mais recente ao mais antigo, ele fica no topo
    _pesquisa.clear();
    setState(() {
      _abaAtual = animal.tipo;
      _busca = '';
    });
    if (salvoNaApi) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${animal.nome} foi salvo na API.')),
      );
      // Recarrega para obter o animal com o id da API e atualizar o cache
      await _carregar();
      return;
    }

    setState(() => _animaisCriados.insert(0, animal));
    estado.atualizarAnimais([..._animaisApi, ..._animaisCriados]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${animal.nome} foi adicionado só neste aparelho. '
          'Não foi possível enviar à API.',
        ),
      ),
    );
  }

  // Abre a ficha do animal. As mudanças feitas nela chegam ao feed pelo
  // estado compartilhado, sem precisar de retorno
  void _abrirDetalhes(Animal animal) {
    Navigator.pushNamed(context, AppRoutes.details, arguments: animal);
  }

  List<Animal> get _animaisVisiveis => _visiveis(_filtros);

  // Lê do estado compartilhado, e não das listas locais, para que uma
  // mudança de status feita na ficha apareça aqui na hora
  List<Animal> get _todosOsAnimais {
    final estado = PataAmigaScope.of(context);
    return estado.animais.isNotEmpty
        ? estado.animais
        : [..._animaisApi, ..._animaisCriados];
  }

  // Animais da aba atual que combinam com os filtros e a pesquisa (nome,
  // raça, espécie ou bairro), do mais recente ao mais antigo. Nos perdidos,
  // vale a data do último avistamento, quando é mais nova que a publicação
  List<Animal> _visiveis(FiltrosDoFeed filtros) {
    final avistamentos = PataAmigaScope.of(context).avistamentos;
    DateTime recencia(Animal animal) {
      final visto = animal.tipo == TipoRegistro.perdido
          ? ultimoAvistamento(animal, avistamentos)
          : null;
      return visto != null && visto.data.isAfter(animal.publicadoEm)
          ? visto.data
          : animal.publicadoEm;
    }

    final termo = _busca.trim().toLowerCase();
    final encontrados = _todosOsAnimais.where((animal) {
      // Animal com desfecho (adotado, encontrado ou resgatado) sai do feed
      if (animal.finalizado) return false;
      if (animal.tipo != _abaAtual) return false;
      if (!filtros.combina(animal)) return false;
      if (termo.isEmpty) return true;
      return animal.nome.toLowerCase().contains(termo) ||
          animal.raca.toLowerCase().contains(termo) ||
          animal.especie.toLowerCase().contains(termo) ||
          animal.bairro.toLowerCase().contains(termo);
    }).toList();
    encontrados.sort((a, b) => recencia(b).compareTo(recencia(a)));
    return encontrados;
  }

  // Abre o painel de filtros e aplica o que ele devolver. O painel recebe
  // a contagem para mostrar quantos animais da aba vão aparecer
  Future<void> _abrirFiltros() async {
    final escolhidos = await showModalBottomSheet<FiltrosDoFeed>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.cores.fundo,
      builder: (_) => PainelDeFiltros(
        inicial: _filtros,
        animais: [
          for (final animal in _todosOsAnimais)
            if (!animal.finalizado) animal,
        ],
        contar: (filtros) => _visiveis(filtros).length,
        ongs: PataAmigaScope.of(context).ongs,
      ),
    );
    if (escolhidos == null || !mounted) return;
    setState(() => _filtros = escolhidos);
  }

  void _limparFiltros() => setState(() => _filtros = const FiltrosDoFeed());

  // Junta os cuidados de saúde marcados numa frase, concordando com o sexo
  // (ex.: "Castrada e vacinada")
  String _saude(Animal animal) {
    final a = animal.sexo == 'fêmea' ? 'a' : 'o';
    final itens = [
      if (animal.castrado) 'castrad$a',
      if (animal.vacinado) 'vacinad$a',
      if (animal.vermifugado) 'vermifugad$a',
    ];
    if (itens.isEmpty) return '';
    final frase = itens.length == 1
        ? itens.first
        : '${itens.sublist(0, itens.length - 1).join(', ')} e ${itens.last}';
    return frase[0].toUpperCase() + frase.substring(1);
  }

  // Abre a conversa no WhatsApp do responsável com uma mensagem pronta
  Future<void> _chamarNoWhatsApp(Animal animal) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final texto = Uri.encodeComponent(
      'Olá! Vi ${animal.nome} no Pata Amiga e queria saber mais.',
    );
    final endereco = Uri.parse(
      'https://wa.me/${animal.dono.numeroNoWhatsApp}?text=$texto',
    );

    final abriu = await launchUrl(
      endereco,
      mode: LaunchMode.externalApplication,
    );
    if (!abriu) {
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o WhatsApp neste aparelho.'),
            duration: Duration(seconds: 3),
          ),
        );
    }
  }

  // Compartilha um resumo do animal em texto, com a foto anexada quando
  // houver
  Future<void> _compartilhar(Animal animal) async {
    final situacao = switch (animal.tipo) {
      TipoRegistro.adocao => 'Disponível para adoção',
      TipoRegistro.perdido => 'Está perdido',
      TipoRegistro.resgate => 'Precisa de resgate',
    };

    final saude = _saude(animal);

    final texto = [
      animal.nome,
      '${animal.especie}, ${animal.raca}, ${animal.sexo}, '
          'porte ${animal.porte}, ${animal.idade}, ${animal.cor}',
      '${animal.bairro}, ${animal.cidade}',
      if (saude.isNotEmpty) saude,
      '',
      '$situacao.',
      if (animal.observacoes.isNotEmpty) animal.observacoes,
      '',
      'Contato: ${animal.dono.nome}, ${animal.dono.telefone}',
      '',
      'Divulgado pelo Pata Amiga',
    ].join('\n');

    // Sem foto, ou se ela não puder ser lida, compartilha só o texto
    final foto = await _arquivoDaFoto(animal);
    await SharePlus.instance.share(ShareParams(text: texto, files: [?foto]));
  }

  // Lê a foto do animal para anexar ao compartilhamento, pela mesma regra
  // de origem do FotoAnimal: "http" vem da internet, caminho absoluto é um
  // arquivo do aparelho e o restante é asset do app. Devolve nulo se falhar
  Future<XFile?> _arquivoDaFoto(Animal animal) async {
    final caminho = animal.foto;
    if (caminho.isEmpty) return null;
    final nome = '${animal.nome}.jpg';
    try {
      if (caminho.startsWith('http')) {
        final resposta = await http
            .get(Uri.parse(caminho))
            .timeout(const Duration(seconds: 10));
        if (resposta.statusCode != 200) return null;
        return XFile.fromData(
          resposta.bodyBytes,
          mimeType: 'image/jpeg',
          name: nome,
        );
      }
      if (!kIsWeb && caminho.startsWith('/')) {
        return XFile(caminho, mimeType: 'image/jpeg', name: nome);
      }
      final imagem = await rootBundle.load(caminho);
      return XFile.fromData(
        imagem.buffer.asUint8List(),
        mimeType: 'image/jpeg',
        name: nome,
      );
    } catch (_) {
      // Foto ausente, sem conexão ou formato inválido: segue sem anexo
      return null;
    }
  }

  // Faixa colorida usada pelo banner de estado
  Widget _faixa({
    required Color cor,
    required IconData icone,
    required String texto,
    Widget? acao,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icone, size: 20, color: cor),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
          ?acao,
        ],
      ),
    );
  }

  // Banner que avisa quando os dados exibidos vêm do cache do aparelho
  Widget _bannerDeEstado() {
    switch (_estado) {
      case EstadoFeed.cache:
        // Busca em andamento: ainda não se sabe se há conexão
        if (_atualizando) return const SizedBox.shrink();
        // A busca falhou: avisa que os dados podem estar desatualizados
        return _faixa(
          // Ocre da paleta: aviso sem ser erro, nos dois temas
          cor: context.cores.alimentacao,
          icone: Icons.cloud_off,
          texto:
              'Dados salvos em ${_formatarData(_dataCache)}. '
              'Podem estar desatualizados.',
          acao: TextButton(
            onPressed: _carregar,
            child: const Text('Tentar atualizar'),
          ),
        );
      // Nos demais estados não há faixa
      case EstadoFeed.atualizado:
      case EstadoFeed.carregando:
      case EstadoFeed.erro:
        return const SizedBox.shrink();
    }
  }

  // Corpo da tela conforme o estado: carregando, erro, lista vazia ou lista
  // de animais
  Widget _corpo() {
    if (_estado == EstadoFeed.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    // Sem conexão e sem cache: tela de erro, a menos que haja animal
    // cadastrado neste aparelho para exibir
    if (_estado == EstadoFeed.erro && _animaisCriados.isEmpty) {
      return AvisoNoCentro(
        icone: Icons.wifi_off,
        titulo: 'Sem conexão e sem dados salvos.',
        texto: 'Conecte-se à internet para carregar os animais.',
        acao: 'Tentar de novo',
        aoAgir: _carregar,
        acaoEmDestaque: true,
      );
    }

    final animais = _animaisVisiveis;
    if (animais.isEmpty) {
      return AvisoNoCentro(
        icone: Icons.pets,
        titulo: _filtros.vazio
            ? 'Nenhum animal encontrado.'
            : 'Nenhum animal com esses filtros.',
        texto: _filtros.vazio
            ? null
            : 'Tire algum filtro para ver mais animais.',
        acao: _filtros.vazio ? null : 'Limpar filtros',
        aoAgir: _filtros.vazio ? null : _limparFiltros,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: animais.length,
      itemBuilder: (context, indice) {
        final animal = animais[indice];
        return CardAnimal(
          animal: animal,
          aoCompartilhar: () => _compartilhar(animal),
          aoChamarNoWhatsApp: () => _chamarNoWhatsApp(animal),
          aoTocar: () => _abrirDetalhes(animal),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.cores.fundo,
        titleSpacing: 16,
        title: Row(
          children: [
            Row(
              children: [
                Image.asset('assets/marca/pata.png', width: 26),
                const SizedBox(width: 6),
                Text(
                  'PATA\nAMIGA',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    color: context.cores.principal,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _pesquisa,
                  onChanged: (valor) => setState(() => _busca = valor),
                  decoration: InputDecoration(
                    hintText: 'Pesquisar',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _busca.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Limpar pesquisa',
                            onPressed: () {
                              _pesquisa.clear();
                              setState(() => _busca = '');
                            },
                          ),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: context.cores.cartao,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: context.cores.borda),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: context.cores.borda),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _abrirFiltros,
              tooltip: 'Filtros',
              color: context.cores.principal,
              icon: Badge(
                isLabelVisible: !_filtros.vazio,
                label: Text('${_filtros.quantos}'),
                backgroundColor: context.cores.principal,
                child: const Icon(Icons.tune),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: EscolhaDeTipo(
              escolhido: _abaAtual,
              aoEscolher: (escolha) => setState(() => _abaAtual = escolha),
              rotulo: rotuloPlural,
              fundoDaOpcao: context.cores.cartao,
            ),
          ),
          if (!_filtros.vazio)
            _FiltrosAplicados(
              filtros: _filtros,
              ongs: PataAmigaScope.of(context).ongs,
              aoTirar: (grupo, opcao) =>
                  setState(() => _filtros = _filtros.alternar(grupo, opcao)),
              aoLimpar: _limparFiltros,
            ),
          _bannerDeEstado(),
          Expanded(child: _corpo()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCadastroAnimal,
        backgroundColor: context.cores.principal,
        foregroundColor: context.sobrePrincipal,
        tooltip: 'Cadastrar animal',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BarraInferior(),
    );
  }
}

// Etiquetas dos filtros aplicados, logo abaixo das abas. Cada uma sai pelo
// X e "Limpar filtros" remove todas
class _FiltrosAplicados extends StatelessWidget {
  const _FiltrosAplicados({
    required this.filtros,
    required this.aoTirar,
    required this.aoLimpar,
    this.ongs = const [],
  });

  final FiltrosDoFeed filtros;
  // Usadas para mostrar o nome da ONG, já que o filtro guarda o id
  final List<Ong> ongs;
  final void Function(GrupoDeFiltro grupo, String opcao) aoTirar;
  final VoidCallback aoLimpar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          for (final grupo in GrupoDeFiltro.values)
            for (final opcao in filtros.de(grupo))
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InputChip(
                  label: Text(
                    grupo == GrupoDeFiltro.ong
                        ? ongs
                                  .where((ong) => '${ong.id}' == opcao)
                                  .firstOrNull
                                  ?.nome ??
                              'ONG'
                        : comMaiuscula(opcao),
                  ),
                  onDeleted: () => aoTirar(grupo, opcao),
                  deleteButtonTooltipMessage: 'Tirar o filtro',
                  backgroundColor: context.cores.principalClara,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: context.cores.principal,
                    fontWeight: FontWeight.w600,
                  ),
                  deleteIconColor: context.cores.principal,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          TextButton(
            onPressed: aoLimpar,
            style: TextButton.styleFrom(
              foregroundColor: context.cores.principal,
            ),
            child: const Text('Limpar filtros'),
          ),
        ],
      ),
    );
  }
}
