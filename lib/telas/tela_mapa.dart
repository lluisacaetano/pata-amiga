// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter_map: mapa interativo com os blocos do OpenStreetMap.
import 'package:flutter_map/flutter_map.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo estado_pata_amiga.dart: estado compartilhado do app.
import '../estado/estado_pata_amiga.dart';
// Arquivo animal.dart: modelo do animal e o tipo do registro.
import '../modelos/animal.dart';
// Arquivo avistamento.dart: modelo do avistamento de um animal.
import '../modelos/avistamento.dart';
// Arquivo camadas_do_mapa.dart: pinos do mapa e cálculo do que está por perto.
import '../modelos/camadas_do_mapa.dart';
// Arquivo minha_posicao.dart: ponto azul com a posição atual do usuário.
import '../widgets/minha_posicao.dart';
// Arquivo ponto_de_alimentacao.dart: ponto de alimentação e sua situação.
import '../modelos/ponto_de_alimentacao.dart';
// Arquivo texto.dart: o texto "hoje", "ontem" ou "há N dias".
import '../modelos/texto.dart';
// Arquivo usuario_provider.dart: dados do usuário logado.
import '../provider/usuario_provider.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo localizacao_service.dart: leitura da posição atual do aparelho.
import '../services/localizacao_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo barra_inferior.dart: barra de navegação inferior.
import '../widgets/barra_inferior.dart';
// Arquivo escolha_de_tipo.dart: estilo das abas de escolha (estiloDasAbas).
import '../widgets/escolha_de_tipo.dart';
// Arquivo etiqueta.dart: etiqueta com o tipo do registro.
import '../widgets/etiqueta.dart';
// Arquivo foto_animal.dart: exibição da foto do animal.
import '../widgets/foto_animal.dart';
// Arquivo icone_de_osso.dart: ícone de osso dos comedouros.
import '../widgets/icone_de_osso.dart';
// Arquivo pino_da_patinha.dart: pino com patinha usado nos mapas.
import '../widgets/pino_da_patinha.dart';
// Arquivo mapa_de_local.dart: coordenada do centro de Formiga.
import '../widgets/mapa_de_local.dart';

// Cor de cada tipo de animal no mapa, usada no pino e na legenda do filtro:
// perdidos na cor de destaque, resgates na cor principal
Color corDaCamada(BuildContext context, TipoRegistro tipo) =>
    tipo == TipoRegistro.perdido
    ? context.cores.destaque
    : context.cores.principal;

// Camadas que o filtro do mapa liga e desliga: animais perdidos, animais
// para resgate e pontos de alimentação
enum CamadaDoFiltro { perdidos, resgate, alimentacao }

// Rótulo e cor de cada camada, exibidos no filtro
extension SobreACamada on CamadaDoFiltro {
  String get rotulo => switch (this) {
    CamadaDoFiltro.perdidos => 'Perdidos',
    CamadaDoFiltro.resgate => 'Resgate',
    CamadaDoFiltro.alimentacao => 'Alimentação',
  };

  Color cor(BuildContext context) => switch (this) {
    CamadaDoFiltro.perdidos => corDaCamada(context, TipoRegistro.perdido),
    CamadaDoFiltro.resgate => corDaCamada(context, TipoRegistro.resgate),
    CamadaDoFiltro.alimentacao => context.cores.alimentacao,
  };
}

// Cor do pino de um ponto de alimentação: ocre para comedouro (e para o
// ponto que é os dois), azul para bebedouro
Color corDoPonto(BuildContext context, TipoDePonto tipo) =>
    tipo == TipoDePonto.bebedouro
    ? context.cores.agua
    : context.cores.alimentacao;

// Indica se há usuário logado; cadastrar ponto e registrar abastecimento
// exigem login
bool _logado(BuildContext context) =>
    (context.read<UsuarioProvider?>()?.usuario.email ?? '').isNotEmpty;

// Ícone de um ponto de alimentação: gota para bebedouro, osso para
// comedouro e os dois combinados para o ponto que é comedouro e bebedouro
Widget iconeDoPonto(TipoDePonto tipo, {double tamanho = 20, Color? cor}) =>
    tipo == TipoDePonto.bebedouro
    ? Icon(Icons.water_drop, size: tamanho, color: cor ?? Colors.white)
    : tipo == TipoDePonto.comedouro
    ? IconeDeOsso(tamanho: tamanho, cor: cor ?? Colors.white)
    // Osso no canto superior e gota no inferior, separados para continuarem
    // legíveis em tamanhos pequenos
    : SizedBox(
        width: tamanho,
        height: tamanho,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: IconeDeOsso(
                tamanho: tamanho * 0.72,
                cor: cor ?? Colors.white,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                Icons.water_drop,
                size: tamanho * 0.52,
                color: cor ?? Colors.white,
              ),
            ),
          ],
        ),
      );

// Página do mapa: filtro de camadas no topo, mapa abaixo e a barra de
// navegação inferior
class PaginaMapa extends StatefulWidget {
  const PaginaMapa({super.key, this.comMapaDeFundo = true, this.focar});

  // Desliga as imagens de fundo do OpenStreetMap; usado nos testes, que não
  // devem acessar a internet
  final bool comMapaDeFundo;
  // Animal em destaque: o mapa abre com zoom nele e com o resumo aberto
  final Animal? focar;

  @override
  State<PaginaMapa> createState() => _PaginaMapaState();
}

class _PaginaMapaState extends State<PaginaMapa> {
  // Todas as camadas começam ligadas
  Set<CamadaDoFiltro> _ligadas = CamadaDoFiltro.values.toSet();

  Set<TipoRegistro> get _tiposLigados => {
    if (_ligadas.contains(CamadaDoFiltro.perdidos)) TipoRegistro.perdido,
    if (_ligadas.contains(CamadaDoFiltro.resgate)) TipoRegistro.resgate,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'MAPA',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<CamadaDoFiltro>(
              segments: [
                for (final camada in CamadaDoFiltro.values)
                  ButtonSegment(
                    value: camada,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // O pontinho é a legenda: a cor do marcador, dentro
                        // de um círculo branco para aparecer também quando a
                        // aba está selecionada e o fundo fica verde
                        Container(
                          width: 14,
                          height: 14,
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          // Alimentação tem duas cores: metade ocre, metade
                          // azul, como os pinos de comedouro e bebedouro
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: camada.cor(context),
                              shape: BoxShape.circle,
                              gradient: camada == CamadaDoFiltro.alimentacao
                                  ? LinearGradient(
                                      colors: [
                                        context.cores.alimentacao,
                                        context.cores.alimentacao,
                                        context.cores.agua,
                                        context.cores.agua,
                                      ],
                                      stops: [0, 0.5, 0.5, 1],
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            camada.rotulo,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              selected: _ligadas,
              multiSelectionEnabled: true,
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (ligadas) =>
                  setState(() => _ligadas = ligadas),
              style: estiloDasAbas(context, context.cores.cartao),
            ),
          ),
          Expanded(
            child: TelaMapa(
              ligadas: _tiposLigados,
              mostrarAlimentacao: _ligadas.contains(CamadaDoFiltro.alimentacao),
              comMapaDeFundo: widget.comMapaDeFundo,
              focar: widget.focar,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BarraInferior(atual: 1),
    );
  }
}

// O mapa em si: pinos dos animais e dos pontos de alimentação, posição do
// usuário, painel "Perto de você" e botões de localização e de novo ponto
class TelaMapa extends StatefulWidget {
  const TelaMapa({
    super.key,
    required this.ligadas,
    this.mostrarAlimentacao = false,
    this.comMapaDeFundo = true,
    this.focar,
  });

  final Set<TipoRegistro> ligadas;
  final bool mostrarAlimentacao;
  final bool comMapaDeFundo;
  final Animal? focar;

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final MapController _controller = MapController();

  // Pino do animal em destaque, se houver; define onde o mapa abre
  late final PinoDoMapa? _pinoEmFoco = _acharPinoEmFoco();

  PinoDoMapa? _acharPinoEmFoco() {
    final alvo = widget.focar;
    final estado = PataAmigaScope.talvez(context);
    if (alvo == null || estado == null) return null;
    final pinos = pinosDoMapa(
      [alvo],
      estado.avistamentos,
      camadasDoMapa.toSet(),
    );
    return pinos.isEmpty ? null : pinos.single;
  }

  @override
  void initState() {
    super.initState();
    final pino = _pinoEmFoco;
    if (pino != null) {
      // Abre o resumo só depois do primeiro quadro, quando o mapa já existe
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarResumo(pino.animal, pino.ultimo);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Posição do usuário, usada no "Perto de você" e para enquadrar o animal
  // em destaque. Abre com a última posição conhecida; a mira a atualiza
  late LatLng? _minhaPosicao = _posicaoConhecida();

  LatLng? _posicaoConhecida() {
    final posicao = PataAmigaScope.talvez(context)?.posicao;
    return posicao == null ? null : LatLng(posicao.latitude, posicao.longitude);
  }

  // O painel "Perto de você" aparece depois que o usuário toca na mira
  bool _mostrarPerto = false;
  bool _buscandoLocalizacao = false;

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // Confere serviço e permissão de localização, centraliza o mapa na posição
  // atual e abre o painel com o que está por perto
  Future<void> _irParaMinhaLocalizacao() async {
    if (_buscandoLocalizacao) return;
    setState(() => _buscandoLocalizacao = true);

    try {
      final pos = await const LocalizacaoService().posicaoAtual();
      final ponto = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _minhaPosicao = ponto;
        _mostrarPerto = true;
      });
      // A posição vale para o ponto azul de todos os mapas
      PataAmigaScope.talvez(context)?.atualizarPosicao(pos);
      _controller.move(ponto, 15);
    } on ErroDeLocalizacao catch (erro) {
      _aviso(erro.texto);
    } finally {
      if (mounted) setState(() => _buscandoLocalizacao = false);
    }
  }

  // Abre a folha inferior com o resumo do ponto de alimentação
  void _mostrarPonto(PontoDeAlimentacao ponto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cores.cartao,
      showDragHandle: true,
      builder: (_) => _ResumoDoPonto(ponto: ponto),
    );
  }

  // Abre a folha inferior com o resumo do animal
  void _mostrarResumo(Animal animal, Avistamento? ultimo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cores.cartao,
      showDragHandle: true,
      builder: (_) => _ResumoDoAnimal(animal: animal, ultimo: ultimo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final pinos = pinosDoMapa(
      estado.animais,
      estado.avistamentos,
      widget.ligadas,
    );
    final eu = _minhaPosicao;
    final perto = _mostrarPerto && eu != null
        ? pertoDe(
            eu.latitude,
            eu.longitude,
            animais: pinos,
            pontos: widget.mostrarAlimentacao ? estado.pontos : const [],
          )
        : null;
    // Distância dos botões ao rodapé: sobem quando o painel está aberto
    final base = perto == null ? 40.0 : 240.0;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _pinoEmFoco == null
                ? centroDeFormiga
                : LatLng(_pinoEmFoco.latitude, _pinoEmFoco.longitude),
            initialZoom: _pinoEmFoco == null ? 14 : 17,
            // Com um animal em destaque e a posição do usuário conhecida, o
            // mapa abre enquadrando os dois, acima do resumo que sobe
            initialCameraFit: switch ((_pinoEmFoco, _minhaPosicao)) {
              (final pino?, final eu?) => CameraFit.coordinates(
                coordinates: [LatLng(pino.latitude, pino.longitude), eu],
                padding: const EdgeInsets.fromLTRB(60, 60, 60, 460),
                maxZoom: 17,
              ),
              _ => null,
            },
          ),
          children: [
            if (widget.comMapaDeFundo)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.edu.ifmg.pata_amiga',
              ),
            MarkerLayer(
              markers: [
                for (final pino in pinos)
                  Marker(
                    point: LatLng(pino.latitude, pino.longitude),
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _mostrarResumo(pino.animal, pino.ultimo),
                      child: _Pino(
                        cor: corDaCamada(context, pino.animal.tipo),
                        rotulo: pino.animal.nome,
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.mostrarAlimentacao)
              MarkerLayer(
                markers: [
                  for (final ponto in estado.pontos)
                    Marker(
                      point: LatLng(ponto.latitude, ponto.longitude),
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _mostrarPonto(ponto),
                        child: Semantics(
                          button: true,
                          label: ponto.lugar.isEmpty
                              ? ponto.tipo.rotulo
                              : '${ponto.tipo.rotulo} ${ponto.lugar}',
                          child: PinoDaPatinha(
                            cor: corDoPonto(context, ponto.tipo),
                            simbolo: iconeDoPonto(ponto.tipo, tamanho: 22),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            const CamadaDaMinhaPosicao(),
            // Crédito do OpenStreetMap, exigido pela política de uso dos
            // mapas. Aparece aberto ao entrar e se recolhe num botão "i"
            if (widget.comMapaDeFundo)
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                popupInitialDisplayDuration: Duration(seconds: 4),
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
          ],
        ),
        // Aviso quando nenhuma camada ligada tem pontos para mostrar
        if (pinos.isEmpty &&
            !(widget.mostrarAlimentacao && estado.pontos.isNotEmpty))
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: _AvisoDoMapa(
              texto: widget.ligadas.isEmpty && !widget.mostrarAlimentacao
                  ? 'Ligue uma camada do filtro para ver os pontos no mapa.'
                  : 'Nada para mostrar nestas camadas ainda.',
            ),
          ),
        // Botão de cadastrar ponto, visível para quem está logado e com a
        // camada de alimentação ligada; fica logo acima do botão da mira
        if (widget.mostrarAlimentacao && _logado(context))
          Positioned(
            right: 16,
            bottom: base + 72,
            child: FloatingActionButton(
              heroTag: 'btn_novo_ponto',
              backgroundColor: context.cores.cartao,
              tooltip: 'Cadastrar ponto de alimentação',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.cadastrarPonto),
              child: Icon(
                Icons.add_location_alt_outlined,
                color: context.cores.principal,
              ),
            ),
          ),
        if (perto != null)
          // Painel fixo no rodapé. Ele cobre o crédito do mapa, por isso
          // repete o crédito no próprio cabeçalho
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _PertoDeVoce(
              itens: perto,
              aoFechar: () => setState(() => _mostrarPerto = false),
              aoTocar: (item) {
                final animal = item.animal;
                final ponto = item.ponto;
                if (animal != null) {
                  _controller.move(
                    LatLng(animal.latitude, animal.longitude),
                    17,
                  );
                  _mostrarResumo(animal.animal, animal.ultimo);
                } else if (ponto != null) {
                  _controller.move(LatLng(ponto.latitude, ponto.longitude), 17);
                  _mostrarPonto(ponto);
                }
              },
            ),
          ),
        Positioned(
          right: 16,
          bottom: base,
          child: FloatingActionButton(
            heroTag: 'btn_minha_localizacao',
            backgroundColor: context.cores.cartao,
            tooltip: 'Minha localização',
            onPressed: _irParaMinhaLocalizacao,
            child: _buscandoLocalizacao
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.cores.principal,
                    ),
                  )
                : Icon(Icons.my_location, color: context.cores.principal),
          ),
        ),
      ],
    );
  }
}

// Pino de um animal no mapa, com o nome do animal para leitores de tela
class _Pino extends StatelessWidget {
  const _Pino({required this.cor, required this.rotulo});

  final Color cor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: rotulo,
      child: PinoDaPatinha(cor: cor),
    );
  }
}

// Caixa de aviso exibida sobre o mapa
class _AvisoDoMapa extends StatelessWidget {
  const _AvisoDoMapa({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cores.borda),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.cores.textoFraco, fontSize: 14),
      ),
    );
  }
}

// Resumo de um animal ao tocar no pino: foto, nome, tipo, local, último
// avistamento e botão para a ficha completa
class _ResumoDoAnimal extends StatelessWidget {
  const _ResumoDoAnimal({required this.animal, this.ultimo});

  final Animal animal;
  // Último avistamento; quando existe, o pino fica no local dele
  final Avistamento? ultimo;

  @override
  Widget build(BuildContext context) {
    final lugar = [
      animal.rua,
      animal.bairro,
    ].where((parte) => parte.trim().isNotEmpty).join(', ');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FotoAnimal(caminho: animal.foto, altura: 170),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    animal.nome.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Etiqueta(rotuloSingular(animal.tipo)),
              ],
            ),
            const SizedBox(height: 6),
            if (ultimo != null) ...[
              Text(
                [
                  'Visto pela última vez ${ultimo!.vistoHa(DateTime.now())}',
                  if (ultimo!.lugar.isNotEmpty) ultimo!.lugar,
                ].join(', '),
                style: TextStyle(
                  color: context.cores.destaque,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: context.cores.principal,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lugar,
                    style: TextStyle(
                      color: context.cores.principal,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  ' · ${animal.publicadoHa(DateTime.now())}',
                  style: TextStyle(
                    color: context.cores.textoFraco,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (animal.observacoes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                animal.observacoes,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                // Guarda o Navigator antes de fechar a folha, pois o context
                // dela deixa de ser válido após o pop
                final navegador = Navigator.of(context);
                navegador.pop();
                navegador.pushNamed(AppRoutes.details, arguments: animal);
              },
              style: FilledButton.styleFrom(
                backgroundColor: context.cores.principal,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Ver ficha completa',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Resumo de um ponto de alimentação: tipo, local, situação e último
// abastecimento. Quem está logado pode registrar um abastecimento
class _ResumoDoPonto extends StatelessWidget {
  const _ResumoDoPonto({required this.ponto});

  final PontoDeAlimentacao ponto;

  // Abre a tela de registro, que confere a localização antes de gravar
  void _abasteci(BuildContext context) => Navigator.pushNamed(
    context,
    AppRoutes.registrarAbastecimento,
    arguments: ponto,
  );

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final agora = DateTime.now();
    final ultimo = ultimoAbastecimento(ponto, estado.abastecimentos);
    final situacao = situacaoDoPonto(ultimo, agora);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: corDoPonto(
                      context,
                      ponto.tipo,
                    ).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: iconeDoPonto(
                      ponto.tipo,
                      tamanho: 24,
                      cor: corDoPonto(context, ponto.tipo),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Etiqueta abaixo do título, pois os textos longos não cabem
                // lado a lado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ponto.tipo.rotulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _EtiquetaDaSituacao(situacao),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.cores.fundo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ponto.lugar.isNotEmpty)
                    Text(
                      ponto.lugar,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (ponto.referencia.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      ponto.referencia,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.cores.textoFraco,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    ultimo == null
                        ? 'Ainda não foi abastecido'
                        : [
                            'Último abastecimento '
                                '${haQuantosDias(ultimo.data, agora)}',
                            if (ultimo.registradoPor.isNotEmpty)
                              'por ${ultimo.registradoPor}',
                          ].join(', '),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.cores.principal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (ultimo != null && ultimo.foto.isNotEmpty) ...[
              const SizedBox(height: 10),
              FotoAnimal(caminho: ultimo.foto, altura: 140),
            ],
            if (_logado(context) && ponto.id != null) ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final email =
                      context.read<UsuarioProvider?>()?.usuario.email ?? '';
                  final jaRegistrou = jaAbasteceuHoje(
                    ponto.id,
                    email,
                    estado.abastecimentos,
                    agora,
                  );
                  return FilledButton.icon(
                    onPressed: jaRegistrou ? null : () => _abasteci(context),
                    icon: Icon(
                      jaRegistrou ? Icons.check_circle : Icons.check,
                      size: 18,
                    ),
                    label: Text(
                      jaRegistrou ? 'Você já registrou hoje' : 'Abasteci hoje',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.cores.principal,
                      disabledBackgroundColor: context.cores.principalClara,
                      disabledForegroundColor: context.cores.principal,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Etiqueta da situação do ponto: cor principal quando abastecido e cor de
// destaque (cheia quando urgente) quando precisa de atenção
class _EtiquetaDaSituacao extends StatelessWidget {
  const _EtiquetaDaSituacao(this.situacao);

  final SituacaoDoPonto situacao;

  @override
  Widget build(BuildContext context) {
    final ok = situacao == SituacaoDoPonto.abastecido;
    final urgente = situacao == SituacaoDoPonto.precisa;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok
            ? context.cores.principalClara
            : urgente
            ? context.cores.destaque
            : context.cores.destaque.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        situacao.rotulo,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ok
              ? context.cores.principal
              : urgente
              ? Colors.white
              : context.cores.destaque,
        ),
      ),
    );
  }
}

// Painel "Perto de você": o que está a até 1 km do usuário nas camadas
// ligadas, do mais perto ao mais longe. Tocar num item leva o mapa até ele
class _PertoDeVoce extends StatelessWidget {
  const _PertoDeVoce({
    required this.itens,
    required this.aoFechar,
    required this.aoTocar,
  });

  final List<ItemPerto> itens;
  final VoidCallback aoFechar;
  final ValueChanged<ItemPerto> aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cores.cartao,
      elevation: 6,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 224,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 4, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.near_me_outlined,
                    size: 18,
                    color: context.cores.principal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Perto de você',
                      style: TextStyle(
                        color: context.cores.principal,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Crédito obrigatório do mapa, coberto pelo painel
                  Text(
                    '© OpenStreetMap',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.cores.textoFraco,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: aoFechar,
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: context.cores.textoFraco,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.cores.borda),
            Expanded(
              child: itens.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Nada a até 1 km de você nas camadas ligadas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.cores.textoFraco),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: itens.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 60,
                        color: context.cores.borda,
                      ),
                      itemBuilder: (context, indice) =>
                          _LinhaPerto(item: itens[indice], aoTocar: aoTocar),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Uma linha do painel: animal ou ponto, com local e distância
class _LinhaPerto extends StatelessWidget {
  const _LinhaPerto({required this.item, required this.aoTocar});

  final ItemPerto item;
  final ValueChanged<ItemPerto> aoTocar;

  @override
  Widget build(BuildContext context) {
    final animal = item.animal?.animal;
    final ponto = item.ponto;
    final cor = animal != null
        ? corDaCamada(context, animal.tipo)
        : corDoPonto(context, ponto!.tipo);
    final titulo = animal != null ? animal.nome : ponto!.tipo.rotulo;
    final lugar = animal != null
        ? [
            animal.rua,
            animal.bairro,
          ].where((parte) => parte.trim().isNotEmpty).join(', ')
        : ponto!.lugar;
    final simbolo = animal != null
        ? const Icon(Icons.pets, color: Colors.white, size: 16)
        : iconeDoPonto(ponto!.tipo, tamanho: 16);

    return InkWell(
      onTap: () => aoTocar(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: simbolo,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lugar.isNotEmpty)
                    Text(
                      lugar,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.cores.textoFraco,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              textoDaDistancia(item.metros),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.cores.principal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
