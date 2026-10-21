import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../tema/cores.dart';
import '../telas/tela_mapa.dart';

// Nos testes o mapa de fundo fica desligado, porque baixaria imagens da
// internet; no aparelho ele sempre aparece
final bool _emTeste =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

const centroDeFormiga = LatLng(-20.4647, -45.4264);

// Um mapa pequeno com o pino parado no meio: quem se move é o mapa, e o
// ponto escolhido é sempre o centro. Usado no cadastro de animal e no
// registro de avistamento
class MapaDeLocal extends StatelessWidget {
  final MapController controlador;
  final LatLng inicio;
  // Chamado quando a pessoa termina de arrastar o mapa, com o novo centro
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

  void _aoMover(MapEvent evento) {
    // Só o fim de um gesto da pessoa conta; o mapa movido pelo app (a busca
    // ou a mira) já avisa por conta própria
    final fimDeGesto =
        evento is MapEventMoveEnd ||
        evento is MapEventFlingAnimationEnd ||
        evento is MapEventDoubleTapZoomEnd;
    if (fimDeGesto && evento.source != MapEventSource.mapController) {
      aoArrastar(evento.camera.center);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: altura,
        child: Stack(
          children: [
            FlutterMap(
              mapController: controlador,
              options: MapOptions(
                initialCenter: inicio,
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
            // A ponta do pino marca o centro do mapa
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
                  onPressed: buscandoPosicao ? null : aoUsarMinhaLocalizacao,
                  icon: buscandoPosicao
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.my_location, color: context.cores.principal),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Uma prévia do mapa, parada, com o pino no ponto do animal. Serve de botão:
// tocar leva ao mapa grande com zoom nele
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
                // O crédito do OpenStreetMap, obrigatório também na prévia
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
