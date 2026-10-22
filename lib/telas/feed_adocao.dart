import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../modelos/dono.dart';
import '../modelos/filtros_do_feed.dart';
import '../modelos/ong.dart';
import '../routes/route_names.dart';
import '../tema/cores.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/card_animal.dart';
import '../widgets/escolha_de_tipo.dart';
import '../widgets/painel_de_filtros.dart';
import '../routes/app_router.dart';
// [SPRINT 3 - NOVO] Camada de dados: API e cache local
import '../services/alimentacao_service.dart';
import '../services/animal_service.dart';
import '../services/avistamento_service.dart';
import '../services/cache_service.dart';
import '../services/ong_service.dart';
import '../provider/usuario_provider.dart';
import '../widgets/sino_de_notificacoes.dart';

enum EstadoFeed { carregando, cache, atualizado, erro }

class FeedAdocao extends StatefulWidget {
  // Os dois são opcionais: o app usa os de verdade, e os testes passam
  // versões falsas para não depender da API no ar
  final AnimalService? api;
  final CacheService? cache;
  final AvistamentoService? avistamentos;
  final AlimentacaoService? alimentacao;
  final OngService? ongs;

  const FeedAdocao({
    super.key,
    this.api,
    this.cache,
    this.avistamentos,
    this.alimentacao,
    this.ongs,
  });

  @override
  State<FeedAdocao> createState() => _FeedAdocaoState();
}

class _FeedAdocaoState extends State<FeedAdocao> {
  // Aba aberta no momento, que decide quais animais o feed mostra
  TipoRegistro _abaAtual = TipoRegistro.adocao;

  final List<Animal> _animaisCriados = [];

  // O que foi digitado no campo de pesquisa
  final _pesquisa = TextEditingController();
  String _busca = '';

  // Os filtros aplicados: valem nas três abas e somam com a pesquisa
  FiltrosDoFeed _filtros = const FiltrosDoFeed();

  // [SPRINT 3 - NOVO] Serviços de dados
  late final _api = widget.api ?? AnimalService();
  late final _cache = widget.cache ?? CacheService();
  late final _avistamentos = widget.avistamentos ?? AvistamentoService();
  late final _alimentacao = widget.alimentacao ?? AlimentacaoService();
  late final _ongs = widget.ongs ?? OngService();

  // [SPRINT 3 - NOVO] Animais que vieram da API ou do cache.
  // Substitui a lista fixa animaisMock.
  List<Animal> _animaisApi = [];

  // [SPRINT 3 - NOVO] Estado atual da tela e dados que o banner usa
  EstadoFeed _estado = EstadoFeed.carregando;
  DateTime? _dataCache; // quando os dados foram salvos / atualizados
  bool _atualizando = false; // true enquanto há uma busca na API em andamento

  // [SPRINT 3 - NOVO] Busca os animais ao abrir a tela
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

  // [SPRINT 3 - NOVO] Fluxo principal da sprint:
  //   1. Se existe cache, mostra na hora (estado: cache)
  //      Se não existe, estado: carregando
  //   2. Tenta a API
  //        sucesso -> mostra, SOBRESCREVE o cache (estado: atualizado)
  //        falha   -> com cache, continua no estado cache
  //                   sem cache, estado erro
  // É chamado ao abrir a tela e pelo botão "Tentar atualizar".
  // Os avistamentos vêm à parte: se a API deles falhar, o feed segue igual,
  // só o mapa fica sem o último ponto visto
  Future<void> _carregarAvistamentos() async {
    try {
      final lista = await _avistamentos.buscarTodos();
      if (!mounted) return;
      PataAmigaScope.of(context).atualizarAvistamentos(lista);
    } on Exception {
      // sem avistamentos desta vez
    }
  }

  // Os pontos de alimentação também vêm à parte, pelo mesmo motivo
  Future<void> _carregarAlimentacao() async {
    try {
      final pontos = await _alimentacao.buscarPontos();
      final abastecimentos = await _alimentacao.buscarAbastecimentos();
      if (!mounted) return;
      PataAmigaScope.of(context).atualizarAlimentacao(pontos, abastecimentos);
    } on Exception {
      // sem a camada de alimentação desta vez
    }
  }

  // As ONGs também: sem elas, só a lista do menu e o atalho da ficha somem.
  // Com o app aberto, elas são conferidas de novo a cada 30 segundos: se
  // chegou um pedido para a ONG que a pessoa administra, o celular vibra e
  // o contador do sino sobe
  Timer? _vigia;
  Set<String>? _pedidosConhecidos;
  // Em segundo plano a conferência para: ninguém está vendo o app
  AppLifecycleListener? _ciclo;

  void _vigiar() => _vigia ??= Timer.periodic(
    const Duration(seconds: 30),
    (_) => _carregarOngs(),
  );

  void _pararDeVigiar() {
    _vigia?.cancel();
    _vigia = null;
  }

  Future<void> _carregarOngs() async {
    try {
      final ongs = await _ongs.buscarOngs();
      if (!mounted) return;
      PataAmigaScope.of(context).atualizarOngs(ongs);
      final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
      final pedidos = notificacoesPara(ongs, email);
      final conhecidos = _pedidosConhecidos;
      _pedidosConhecidos = pedidos;
      if (conhecidos != null && !conhecidos.containsAll(pedidos)) {
        await avisarNovaNotificacao();
      }
    } on Exception {
      // sem as ONGs desta vez
    }
  }

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

    unawaited(_carregarAvistamentos());
    unawaited(_carregarAlimentacao());
    unawaited(_carregarOngs());
    _vigiar();
    _ciclo ??= AppLifecycleListener(
      onPause: _pararDeVigiar,
      onResume: () {
        _carregarOngs();
        _vigiar();
      },
    );
    try {
      final novos = await _api.buscarAnimais();
      await _cache.salvarAnimais(novos); // o cache nunca fica congelado
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
      // Sem internet, servidor fora do ar ou timeout
      if (!mounted) return;
      setState(() {
        _atualizando = false;
        if (salvos == null) _estado = EstadoFeed.erro;
        // Se havia cache, o estado continua "cache", e a faixa laranja do
        // topo já avisa que os dados podem estar desatualizados
      });
    }
  }

  // [SPRINT 3 - NOVO] Formata a data do cache, ex.: "14/10 às 21:05"
  String _formatarData(DateTime? data) {
    if (data == null) return 'data desconhecida';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(data.day)}/${dois(data.month)} às '
        '${dois(data.hour)}:${dois(data.minute)}';
  }

  /*
   Future<void> _abrirCadastroAnimal() async {
    final animal = (await Navigator.pushNamed(
      context,
      AppRoutes.registerAnimal,
    )) as Animal?;
    if (!mounted || animal == null) return;

    setState(() => _animaisCriados.insert(0, animal));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${animal.nome} foi adicionado ao feed.')),
    );
  }
  */

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
      // A API pode estar indisponível; o registro continua visível neste aparelho.
    }

    await estado.registrarCadastro(animal);
    if (!mounted) return;
    // O animal novo tem que aparecer na hora: abre a aba do tipo dele e
    // limpa a busca, que poderia escondê-lo. Como o feed vai do mais recente
    // para o mais antigo, ele fica no topo
    _pesquisa.clear();
    setState(() {
      _abaAtual = animal.tipo;
      _busca = '';
    });
    if (salvoNaApi) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${animal.nome} foi salvo na API.')),
      );
      // Busca a lista de novo: o animal volta com o id da API e o cache
      // local também é atualizado.
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

  Future<void> _abrirDetalhes(Animal animal) async {
    final animalRetornado = (await Navigator.pushNamed(
      context,
      AppRoutes.details,
      arguments: animal,
    )) as Animal?;
    if (!mounted || animalRetornado == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Você voltou dos detalhes de ${animalRetornado.nome}.'),
      ),
    );
  }

  List<Animal> get _animaisVisiveis => _visiveis(_filtros);

  // Do estado compartilhado, e não das listas do feed: assim um status
  // mudado na ficha aparece aqui na hora
  List<Animal> get _todosOsAnimais {
    final estado = PataAmigaScope.of(context);
    return estado.animais.isNotEmpty
        ? estado.animais
        : [..._animaisApi, ..._animaisCriados];
  }

  List<Animal> _visiveis(FiltrosDoFeed filtros) {
    final termo = _busca.trim().toLowerCase();
    // [SPRINT 3 - ALTERADO] antes: [...animaisMock, ..._animaisCriados]
    // Do estado compartilhado, e não das listas do feed: assim um status
    // mudado na ficha aparece aqui na hora
    final estado = PataAmigaScope.of(context);
    final todos = estado.animais.isNotEmpty
        ? estado.animais
        : [..._animaisApi, ..._animaisCriados];
    final encontrados = todos.where((animal) {
      // Com desfecho (adotado, encontrado ou resgatado), sai do feed
      if (animal.finalizado) return false;
      if (animal.tipo != _abaAtual) return false;
      if (!filtros.combina(animal)) return false;
      if (termo.isEmpty) return true;
      return animal.nome.toLowerCase().contains(termo) ||
          animal.raca.toLowerCase().contains(termo) ||
          animal.especie.toLowerCase().contains(termo);
    }).toList();
    // O feed é cronológico decrescente: o que foi publicado por último abre
    encontrados.sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));
    return encontrados;
  }

  // O painel conta, a cada toque, quantos animais da aba vão aparecer
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

  // Junta os cuidados marcados numa frase só, concordando com o sexo
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

  // Abre a conversa direto no WhatsApp do responsável
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

    // [SPRINT 3 - ALTERADO] Só anexa a foto se o animal tiver uma.
    // Antes, rootBundle.load('') dava erro com animal sem foto vindo da API.
    final arquivos = <XFile>[];
    if (animal.foto.isNotEmpty) {
      // O compartilhamento só aceita arquivo, e a foto é um asset, então converte
      final imagem = await rootBundle.load(animal.foto);
      arquivos.add(
        XFile.fromData(
          imagem.buffer.asUint8List(),
          mimeType: 'image/jpeg',
          name: '${animal.nome}.jpg',
        ),
      );
    }

    await SharePlus.instance.share(ShareParams(text: texto, files: arquivos));
  }

  // [SPRINT 3 - NOVO] Faixa colorida do banner de estado
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

  // [SPRINT 3 - NOVO] Banner que diz ao usuário de onde vêm os dados.
  // É isto que a Sprint Review precisa mostrar em modo avião.
  Widget _bannerDeEstado() {
    switch (_estado) {
      case EstadoFeed.cache:
        // Busca em andamento: ainda não é "sem conexão", então não avisa nada
        if (_atualizando) return const SizedBox.shrink();
        // A busca falhou: mostra o aviso de dado possivelmente desatualizado
        return _faixa(
          cor: Colors.orange,
          icone: Icons.cloud_off,
          texto:
              'Dados salvos em ${_formatarData(_dataCache)}. '
              'Podem estar desatualizados.',
          acao: TextButton(
            onPressed: _carregar,
            child: const Text('Tentar atualizar'),
          ),
        );
      // Com internet, o feed só mostra os animais: a faixa fica para quando
      // os dados vêm do aparelho
      case EstadoFeed.atualizado:
      case EstadoFeed.carregando:
      case EstadoFeed.erro:
        return const SizedBox.shrink();
    }
  }

  // [SPRINT 3 - NOVO] Corpo da tela conforme o estado.
  // A lista de animais é a mesma de antes; só ganhou os casos
  // carregando e erro à sua volta.
  Widget _corpo() {
    if (_estado == EstadoFeed.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    // Sem conexão e sem cache, mas com animal cadastrado neste aparelho, o
    // feed mostra esse animal em vez da tela de erro
    if (_estado == EstadoFeed.erro && _animaisCriados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off,
                size: 56,
                color: context.cores.principal.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 14),
              Text(
                'Sem conexão e sem dados salvos.\n'
                'Conecte-se à internet para carregar os animais.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.cores.textoFraco),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final animais = _animaisVisiveis;
    if (animais.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pets,
                size: 56,
                color: context.cores.principal.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 14),
              Text(
                _filtros.vazio
                    ? 'Nenhum animal encontrado.'
                    : 'Nenhum animal com esses filtros.',
                style: TextStyle(color: context.cores.textoFraco),
              ),
              if (!_filtros.vazio)
                TextButton(
                  onPressed: _limparFiltros,
                  style: TextButton.styleFrom(
                    foregroundColor: context.cores.principal,
                  ),
                  child: const Text('Limpar filtros'),
                ),
            ],
          ),
        ),
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
              aoTirar: (grupo, opcao) => setState(
                () => _filtros = _filtros.alternar(grupo, opcao),
              ),
              aoLimpar: _limparFiltros,
            ),
          // [SPRINT 3 - NOVO] Banner de estado (cache / atualizado)
          _bannerDeEstado(),
          // [SPRINT 3 - ALTERADO] O Expanded com a lista agora vem do _corpo()
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

// Os filtros aplicados, logo abaixo das abas: cada um sai no X, e "Limpar"
// tira todos de uma vez
class _FiltrosAplicados extends StatelessWidget {
  const _FiltrosAplicados({
    required this.filtros,
    required this.aoTirar,
    required this.aoLimpar,
    this.ongs = const [],
  });

  final FiltrosDoFeed filtros;
  // Para a etiqueta da ONG mostrar o nome, e não o id que o filtro guarda
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
                        : rotuloDaOpcao(opcao),
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
            style: TextButton.styleFrom(foregroundColor: context.cores.principal),
            child: const Text('Limpar filtros'),
          ),
        ],
      ),
    );
  }
}
