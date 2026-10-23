// Biblioteca dart:io: Platform, para detectar a execução em teste.
import 'dart:io';

// Pacote flutter/foundation: utilitários base, como kIsWeb.
import 'package:flutter/foundation.dart';
// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter_map: mapa interativo com os blocos do OpenStreetMap.
import 'package:flutter_map/flutter_map.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo pino_da_patinha.dart: pino com patinha usado nos mapas.
import 'pino_da_patinha.dart';

// Indica execução em teste: nesse caso os blocos do mapa não são baixados
// da internet
final bool _emTeste =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

// Centro de Formiga (MG), ponto inicial padrão dos mapas
const centroDeFormiga = LatLng(-20.4647, -45.4264);

// Mapa pequeno para marcar um local: o pino fica fixo no centro e o ponto
// escolhido é o centro do mapa. Usado nos cadastros de animal, ONG, ponto
// de alimentação e avistamento. Começa travado para que rolar a tela não
// mova o mapa por engano; o botão do topo destrava. O botão de localização
// funciona mesmo travado
class MapaDeLocal extends StatefulWidget {
  final MapController controlador;
  final LatLng inicio;
  // Chamado com o novo centro quando a pessoa termina de mover o mapa
  final ValueChanged<LatLng> aoArrastar;
  final VoidCallback aoUsarMinhaLocalizacao;
  final bool buscandoPosicao;
  final double altura;

  const MapaDeLocal({
    super.key,
    required this.controlador,
    required this.inicio,
    required this.aoArrastar,
    required this.aoUsarMinhaLocalizacao,
    this.buscandoPosicao = false,
    this.altura = 240,
  });

  @override
  State<MapaDeLocal> createState() => _MapaDeLocalState();
}

class _MapaDeLocalState extends State<MapaDeLocal> {
  bool _travado = true;

  void _aoMover(MapEvent evento) {
    // Considera só o fim de um gesto da pessoa; movimentos feitos pelo
    // controlador (busca ou localização) são tratados por quem os fez
    final fimDeGesto =
        evento is MapEventMoveEnd ||
        evento is MapEventFlingAnimationEnd ||
        evento is MapEventDoubleTapZoomEnd;
    if (fimDeGesto && evento.source != MapEventSource.mapController) {
      widget.aoArrastar(evento.camera.center);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.altura,
        child: Stack(
          children: [
            // Travado, o mapa ignora toques e a rolagem da tela passa direto
            IgnorePointer(
              ignoring: _travado,
              child: FlutterMap(
                mapController: widget.controlador,
                options: MapOptions(
                  initialCenter: widget.inicio,
                  initialZoom: 16,
                  onMapEvent: _aoMover,
                ),
                children: [
                  if (!_emTeste)
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'br.edu.ifmg.pata_amiga',
                    ),
                  if (!_emTeste)
                    const RichAttributionWidget(
                      alignment: AttributionAlignment.bottomLeft,
                      showFlutterMapAttribution: false,
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                ],
              ),
            ),
            // Pino fixo; o recuo inferior faz a ponta coincidir com o centro
            IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: PinoDaPatinha(cor: context.cores.destaque),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: context.cores.cartao,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: 'Usar minha localização',
                  onPressed: widget.buscandoPosicao
                      ? null
                      : widget.aoUsarMinhaLocalizacao,
                  icon: widget.buscandoPosicao
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.my_location, color: context.cores.principal),
                ),
              ),
            ),
            // Botão de travar e destravar: claro quando travado, na cor
            // principal quando o mapa pode ser movido
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: _travado ? context.cores.cartao : context.cores.principal,
                  elevation: 2,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => setState(() => _travado = !_travado),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _travado ? Icons.lock_outline : Icons.lock_open,
                            size: 16,
                            color: _travado ? context.cores.principal : context.sobrePrincipal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _travado ? 'Destravar o mapa' : 'Travar o mapa',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _travado ? context.cores.principal : context.sobrePrincipal,
                            ),
                          ),
                        ],
                      ),
                    ),
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

// Prévia estática do mapa com o pino no ponto informado. Funciona como
// botão: o toque executa [aoTocar], normalmente abrindo o mapa completo
class PreviaDoMapa extends StatelessWidget {
  final LatLng ponto;
  final Color cor;
  final VoidCallback aoTocar;
  final double altura;

  const PreviaDoMapa({
    super.key,
    required this.ponto,
    required this.cor,
    required this.aoTocar,
    this.altura = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver no mapa',
      child: GestureDetector(
        onTap: aoTocar,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: altura,
            child: Stack(
              children: [
                IgnorePointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: ponto,
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      if (!_emTeste)
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'br.edu.ifmg.pata_amiga',
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: ponto,
                            width: 38,
                            height: 48,
                            alignment: Alignment.topCenter,
                            child: PinoDaPatinha(cor: cor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.cores.cartao,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22000000), blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 16,
                          color: context.cores.principal,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ver no mapa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.cores.principal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Atribuição exigida pela licença do OpenStreetMap
                if (!_emTeste)
                  Positioned(
                    left: 8,
                    bottom: 6,
                    child: Text(
                      '© OpenStreetMap',
                      style: TextStyle(fontSize: 9, color: context.cores.textoFraco),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
