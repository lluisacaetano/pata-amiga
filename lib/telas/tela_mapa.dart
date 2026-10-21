import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../modelos/avistamento.dart';
import '../modelos/camadas_do_mapa.dart';
import '../modelos/ponto_de_alimentacao.dart';
import '../provider/usuario_provider.dart';
import '../routes/route_names.dart';
import '../services/alimentacao_service.dart';
import '../tema/cores.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/escolha_de_tipo.dart';
import '../widgets/etiqueta.dart';
import '../widgets/foto_animal.dart';
import '../widgets/icone_de_tigela.dart';

// Uma cor por camada, a mesma no marcador e na legenda do filtro
Color corDaCamada(TipoRegistro tipo) =>
    tipo == TipoRegistro.perdido ? Cores.destaque : Cores.principal;

// As três camadas do filtro: os dois tipos de animal e os pontos de
// alimentação, que não são animais
enum CamadaDoFiltro { perdidos, resgate, alimentacao }

extension SobreACamada on CamadaDoFiltro {
  String get rotulo => switch (this) {
    CamadaDoFiltro.perdidos => 'Perdidos',
    CamadaDoFiltro.resgate => 'Resgate',
    CamadaDoFiltro.alimentacao => 'Alimentação',
  };

  Color get cor => switch (this) {
    CamadaDoFiltro.perdidos => corDaCamada(TipoRegistro.perdido),
    CamadaDoFiltro.resgate => corDaCamada(TipoRegistro.resgate),
    CamadaDoFiltro.alimentacao => Cores.alimentacao,
  };
}

// Os pontos de alimentação: ocre de ração para comedouro (e para o que é os
// dois), azul de água para bebedouro
Color corDoPonto(TipoDePonto tipo) =>
    tipo == TipoDePonto.bebedouro ? Cores.agua : Cores.alimentacao;

// Cadastrar ponto e registrar abastecimento é só para quem está logado
bool _logado(BuildContext context) =>
    (context.read<UsuarioProvider?>()?.usuario.email ?? '').isNotEmpty;

// Bebedouro é uma gota d'água; comedouro, um osso; o ponto que é os dois,
// o osso com uma gotinha
Widget iconeDoPonto(TipoDePonto tipo, {double tamanho = 20, Color? cor}) =>
    tipo == TipoDePonto.bebedouro
    ? Icon(Icons.water_drop, size: tamanho, color: cor ?? Colors.white)
    : tipo == TipoDePonto.comedouro
    ? IconeDeOsso(tamanho: tamanho, cor: cor ?? Colors.white)
    // Os dois: o osso em cima e a gota embaixo, separados, para não embolar
    // quando o ícone fica pequeno
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

/// Página do mapa: o filtro das camadas em cima e o mapa embaixo.
class PaginaMapa extends StatefulWidget {
  const PaginaMapa({super.key, this.comMapaDeFundo = true, this.focar});

  // Os testes desligam o mapa de fundo, que baixaria imagens da internet
  final bool comMapaDeFundo;
  // Vindo da ficha: o mapa abre com zoom neste animal e o resumo dele aberto
  final Animal? focar;

  @override
  State<PaginaMapa> createState() => _PaginaMapaState();
}

class _PaginaMapaState extends State<PaginaMapa> {
  // As duas camadas abrem ligadas
  Set<CamadaDoFiltro> _ligadas = CamadaDoFiltro.values.toSet();

  Set<TipoRegistro> get _tiposLigados => {
    if (_ligadas.contains(CamadaDoFiltro.perdidos)) TipoRegistro.perdido,
    if (_ligadas.contains(CamadaDoFiltro.resgate)) TipoRegistro.resgate,
  };

  @override
  Widget build(BuildContext context) {
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
          'MAPA',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Cores.principal,
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
                              color: camada.cor,
                              shape: BoxShape.circle,
                              gradient: camada == CamadaDoFiltro.alimentacao
                                  ? const LinearGradient(
                                      colors: [
                                        Cores.alimentacao,
                                        Cores.alimentacao,
                                        Cores.agua,
                                        Cores.agua,
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
              style: estiloDasAbas(Cores.cartao),
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

class TelaMapa extends StatefulWidget {
  const TelaMapa({
    super.key,
    required this.ligadas,
    this.mostrarAlimentacao = false,
    this.comMapaDeFundo = true,
    this.focar,
    this.alimentacao,
  });

  final Set<TipoRegistro> ligadas;
  final bool mostrarAlimentacao;
  final bool comMapaDeFundo;
  final Animal? focar;
  final AlimentacaoService? alimentacao;

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final MapController _controller = MapController();

  // Onde o mapa abre: no animal vindo da ficha, ou no centro de Formiga
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
      // O resumo abre depois que o mapa aparece
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

  static const LatLng _centroInicial = LatLng(-20.4647, -45.4264); // Formiga-MG

  LatLng? _minhaPosicao;
  // O painel "Perto de você" abre quando a pessoa toca na mira
  bool _mostrarPerto = false;
  bool _buscandoLocalizacao = false;

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _irParaMinhaLocalizacao() async {
    if (_buscandoLocalizacao) return;
    setState(() => _buscandoLocalizacao = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _aviso('Ative a localização do aparelho.');
        return;
      }

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        _aviso('Permissão de localização negada.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final ponto = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _minhaPosicao = ponto;
        _mostrarPerto = true;
      });
      _controller.move(ponto, 15);
    } catch (e) {
      _aviso('Não foi possível obter a localização.');
    } finally {
      if (mounted) setState(() => _buscandoLocalizacao = false);
    }
  }

  late final _servicoDeAlimentacao = widget.alimentacao ?? AlimentacaoService();

  void _mostrarPonto(PontoDeAlimentacao ponto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Cores.cartao,
      showDragHandle: true,
      builder: (_) =>
          _ResumoDoPonto(ponto: ponto, servico: _servicoDeAlimentacao),
    );
  }

  void _mostrarResumo(Animal animal, Avistamento? ultimo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Cores.cartao,
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
    // Com o painel aberto, os botões sobem para não ficarem atrás dele
    final base = perto == null ? 40.0 : 240.0;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _pinoEmFoco == null
                ? _centroInicial
                : LatLng(_pinoEmFoco.latitude, _pinoEmFoco.longitude),
            initialZoom: _pinoEmFoco == null ? 14 : 17,
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
                        cor: corDaCamada(pino.animal.tipo),
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
                            cor: corDoPonto(ponto.tipo),
                            simbolo: iconeDoPonto(ponto.tipo, tamanho: 22),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            if (_minhaPosicao != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _minhaPosicao!,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            // O crédito do OpenStreetMap é obrigatório pela política de uso
            // dos mapas dele. Fica num botão "i": aparece aberto ao entrar e
            // se recolhe sozinho, sem ocupar o rodapé o tempo todo
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
        // Sem nenhum ponto, o mapa vazio diria nada: o aviso explica por quê
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
        // Quem está logado cadastra um ponto novo, com a camada ligada. O
        // botão tem a mesma cara da mira, logo acima dela
        if (widget.mostrarAlimentacao && _logado(context))
          Positioned(
            right: 16,
            bottom: base + 72,
            child: FloatingActionButton(
              heroTag: 'btn_novo_ponto',
              backgroundColor: Colors.white,
              tooltip: 'Cadastrar ponto de alimentação',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.cadastrarPonto),
              child: const Icon(
                Icons.add_location_alt_outlined,
                color: Cores.principal,
              ),
            ),
          ),
        if (perto != null)
          // Preso à barra inferior, como uma gaveta. O crédito do mapa, que
          // ficaria escondido atrás dele, vai para dentro do painel
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
            backgroundColor: Colors.white,
            tooltip: 'Minha localização',
            onPressed: _irParaMinhaLocalizacao,
            child: _buscandoLocalizacao
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, color: Cores.principal),
          ),
        ),
      ],
    );
  }
}

// O pino do mapa: a patinha do Início num círculo da cor da camada, com uma
// ponta embaixo que marca o lugar exato
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

class PinoDaPatinha extends StatelessWidget {
  const PinoDaPatinha({
    super.key,
    required this.cor,
    this.tamanho = 38,
    this.simbolo,
  });

  final Color cor;
  final double tamanho;
  // A patinha do Início nos animais; a tigela nos pontos de alimentação
  final Widget? simbolo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho + 10,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // A ponta: um quadrado girado, metade escondida atrás do círculo
          Positioned(
            bottom: 2,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(width: 12, height: 12, color: cor),
            ),
          ),
          Container(
            width: tamanho,
            height: tamanho,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child:
                simbolo ??
                Icon(Icons.pets, color: Colors.white, size: tamanho * 0.5),
          ),
        ],
      ),
    );
  }
}

class _AvisoDoMapa extends StatelessWidget {
  const _AvisoDoMapa({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Cores.borda),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Cores.textoFraco, fontSize: 14),
      ),
    );
  }
}

// O resumo que sobe ao tocar no pino: foto, nome, onde e quando, e o
// caminho para a ficha completa, de onde se chega ao contato
class _ResumoDoAnimal extends StatelessWidget {
  const _ResumoDoAnimal({required this.animal, this.ultimo});

  final Animal animal;
  // Com avistamento, o pino está onde o animal foi visto por último
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
                style: const TextStyle(
                  color: Cores.destaque,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Cores.principal,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lugar,
                    style: const TextStyle(
                      color: Cores.principal,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  ' · ${animal.publicadoHa(DateTime.now())}',
                  style: const TextStyle(color: Cores.textoFraco, fontSize: 13),
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
                // O navegador é guardado antes de fechar o painel, porque o
                // contexto dele deixa de existir assim que ele fecha
                final navegador = Navigator.of(context);
                navegador.pop();
                navegador.pushNamed(AppRoutes.details, arguments: animal);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Cores.principal,
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

// O resumo do ponto de alimentação: o tipo, onde fica, a situação e quando
// foi abastecido pela última vez. Quem está logado registra que abasteceu
class _ResumoDoPonto extends StatefulWidget {
  const _ResumoDoPonto({required this.ponto, required this.servico});

  final PontoDeAlimentacao ponto;
  final AlimentacaoService servico;

  @override
  State<_ResumoDoPonto> createState() => _ResumoDoPontoState();
}

class _ResumoDoPontoState extends State<_ResumoDoPonto> {
  // A confirmação confere se a pessoa está no ponto antes de gravar
  Future<void> _abasteci() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.registrarAbastecimento,
      arguments: widget.ponto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final agora = DateTime.now();
    final ultimo = ultimoAbastecimento(widget.ponto, estado.abastecimentos);
    final situacao = situacaoDoPonto(ultimo, agora);
    final ponto = widget.ponto;

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
                    color: corDoPonto(ponto.tipo).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: iconeDoPonto(
                      ponto.tipo,
                      tamanho: 24,
                      cor: corDoPonto(ponto.tipo),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // A etiqueta fica embaixo do título: "Precisa de
                // abastecimento" ao lado de "Comedouro e bebedouro" não cabe
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
                color: Cores.fundo,
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: Cores.textoFraco,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    ultimo == null
                        ? 'Ainda não foi abastecido'
                        : [
                            'Último abastecimento '
                                '${haQuantoTempo(ultimo.data, agora)}',
                            if (ultimo.registradoPor.isNotEmpty)
                              'por ${ultimo.registradoPor}',
                          ].join(', '),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Cores.principal,
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
                    onPressed: jaRegistrou ? null : _abasteci,
                    icon: Icon(
                      jaRegistrou ? Icons.check_circle : Icons.check,
                      size: 18,
                    ),
                    label: Text(
                      jaRegistrou ? 'Você já registrou hoje' : 'Abasteci hoje',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Cores.principal,
                      disabledBackgroundColor: Cores.principalClara,
                      disabledForegroundColor: Cores.principal,
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

// Verde quando está abastecido; coral quando precisa de atenção
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
            ? Cores.principalClara
            : urgente
            ? Cores.destaque
            : Cores.destaque.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        situacao.rotulo,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ok
              ? Cores.principal
              : urgente
              ? Colors.white
              : Cores.destaque,
        ),
      ),
    );
  }
}

// O que está a até 1 km de quem tocou na mira, nas camadas ligadas, do mais
// perto para o mais longe. Tocar num item leva o mapa até ele
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
      color: Cores.cartao,
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
                  const Icon(
                    Icons.near_me_outlined,
                    size: 18,
                    color: Cores.principal,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Perto de você',
                      style: TextStyle(
                        color: Cores.principal,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // O crédito obrigatório do mapa, que o painel cobriria
                  const Text(
                    '© OpenStreetMap',
                    style: TextStyle(fontSize: 10, color: Cores.textoFraco),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: aoFechar,
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Cores.textoFraco,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Cores.borda),
            Expanded(
              child: itens.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Nada a até 1 km de você nas camadas ligadas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Cores.textoFraco),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: itens.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        indent: 60,
                        color: Cores.borda,
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

class _LinhaPerto extends StatelessWidget {
  const _LinhaPerto({required this.item, required this.aoTocar});

  final ItemPerto item;
  final ValueChanged<ItemPerto> aoTocar;

  @override
  Widget build(BuildContext context) {
    final animal = item.animal?.animal;
    final ponto = item.ponto;
    final cor = animal != null
        ? corDaCamada(animal.tipo)
        : corDoPonto(ponto!.tipo);
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Cores.textoFraco,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              textoDaDistancia(item.metros),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Cores.principal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
