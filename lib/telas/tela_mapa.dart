import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../modelos/camadas_do_mapa.dart';
import '../routes/route_names.dart';
import '../tema/cores.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/escolha_de_tipo.dart';
import '../widgets/etiqueta.dart';
import '../widgets/foto_animal.dart';

// Uma cor por camada, a mesma no marcador e na legenda do filtro
Color corDaCamada(TipoRegistro tipo) =>
    tipo == TipoRegistro.perdido ? Cores.destaque : Cores.principal;

/// Página do mapa: o filtro das camadas em cima e o mapa embaixo.
class PaginaMapa extends StatefulWidget {
  const PaginaMapa({super.key, this.comMapaDeFundo = true});

  // Os testes desligam o mapa de fundo, que baixaria imagens da internet
  final bool comMapaDeFundo;

  @override
  State<PaginaMapa> createState() => _PaginaMapaState();
}

class _PaginaMapaState extends State<PaginaMapa> {
  // As duas camadas abrem ligadas
  Set<TipoRegistro> _ligadas = camadasDoMapa.toSet();

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
            child: SegmentedButton<TipoRegistro>(
              segments: [
                for (final tipo in camadasDoMapa)
                  ButtonSegment(
                    value: tipo,
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
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: corDaCamada(tipo),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(rotuloPlural(tipo)),
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
              ligadas: _ligadas,
              comMapaDeFundo: widget.comMapaDeFundo,
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
    this.comMapaDeFundo = true,
  });

  final Set<TipoRegistro> ligadas;
  final bool comMapaDeFundo;

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final MapController _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const LatLng _centroInicial = LatLng(-20.4647, -45.4264); // Formiga-MG

  LatLng? _minhaPosicao;
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
      setState(() => _minhaPosicao = ponto);
      _controller.move(ponto, 15);
    } catch (e) {
      _aviso('Não foi possível obter a localização.');
    } finally {
      if (mounted) setState(() => _buscandoLocalizacao = false);
    }
  }

  void _mostrarResumo(Animal animal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Cores.cartao,
      showDragHandle: true,
      builder: (_) => _ResumoDoAnimal(animal: animal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animais = animaisNoMapa(
      PataAmigaScope.of(context).animais,
      widget.ligadas,
    );

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: const MapOptions(
            initialCenter: _centroInicial,
            initialZoom: 14,
          ),
          children: [
            if (widget.comMapaDeFundo)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.edu.ifmg.pata_amiga',
              ),
            MarkerLayer(
              markers: [
                for (final animal in animais)
                  Marker(
                    point: LatLng(animal.latitude!, animal.longitude!),
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _mostrarResumo(animal),
                      child: _Pino(
                        cor: corDaCamada(animal.tipo),
                        rotulo: animal.nome,
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
        if (animais.isEmpty)
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: _AvisoDoMapa(
              texto: widget.ligadas.isEmpty
                  ? 'Ligue Perdidos ou Resgate para ver os animais no mapa.'
                  : 'Nenhum animal com localização nestas camadas ainda.',
            ),
          ),
        Positioned(
          right: 16,
          bottom: 40,
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

class _Pino extends StatelessWidget {
  const _Pino({required this.cor, required this.rotulo});

  final Color cor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: rotulo,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Icon(Icons.location_on, color: cor, size: 48),
          const Padding(
            padding: EdgeInsets.only(top: 9),
            child: Icon(Icons.pets, color: Colors.white, size: 18),
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
  const _ResumoDoAnimal({required this.animal});

  final Animal animal;

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
                  style: const TextStyle(
                    color: Cores.textoFraco,
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
