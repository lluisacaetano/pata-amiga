import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../tema/cores.dart';
import '../widgets/barra_inferior.dart';

class CaoDoacao {
  final String id;
  final String nome;
  final double lat;
  final double lng;

  const CaoDoacao({
    required this.id,
    required this.nome,
    required this.lat,
    required this.lng,
  });
}

/// Página do mapa: Scaffold com a barra inferior (aba Mapa selecionada).
class PaginaMapa extends StatelessWidget {
  const PaginaMapa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        title: const Text('Mapa'),
      ),
      body: const TelaMapa(),
      bottomNavigationBar: BarraInferior(atual: 1),
    );
  }
}
class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

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

  // Dados de teste. Depois troque pelos dados do Firebase.
  static const List<CaoDoacao> _caes = [
    CaoDoacao(id: '1', nome: 'Thor', lat: -20.4647, lng: -45.4264),
    CaoDoacao(id: '2', nome: 'Luna', lat: -20.4690, lng: -45.4310),
    CaoDoacao(id: '3', nome: 'Bob', lat: -20.4610, lng: -45.4200),
  ];

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

  void _mostrarDetalhes(CaoDoacao cao) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pets, color: Colors.red),
                const SizedBox(width: 8),
                Text(cao.nome,
                    style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Disponível para doação'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: const MapOptions(
            initialCenter: _centroInicial,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.edu.ifmg.pata_amiga',
            ),
            CircleLayer(
              circles: _caes
                  .map((c) => CircleMarker(
                        point: LatLng(c.lat, c.lng),
                        radius: 150,
                        useRadiusInMeter: true,
                        color: Colors.red.withValues(alpha: 0.15),
                        borderColor: Colors.red.withValues(alpha: 0.3),
                        borderStrokeWidth: 1,
                      ))
                  .toList(),
            ),
            MarkerLayer(
              markers: _caes
                  .map((c) => Marker(
                        point: LatLng(c.lat, c.lng),
                        width: 48,
                        height: 48,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () => _mostrarDetalhes(c),
                          child: const _PinPatinha(),
                        ),
                      ))
                  .toList(),
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
            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap contributors'),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 40,
          child: FloatingActionButton(
            heroTag: 'btn_minha_localizacao',
            backgroundColor: Colors.white,
            onPressed: _irParaMinhaLocalizacao,
            child: _buscandoLocalizacao
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, color: Colors.blueGrey),
          ),
        ),
      ],
    );
  }
}

class _PinPatinha extends StatelessWidget {
  const _PinPatinha();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.topCenter,
      children: [
        Icon(Icons.location_on, color: Colors.red, size: 48),
        Padding(
          padding: EdgeInsets.only(top: 9),
          child: Icon(Icons.pets, color: Colors.white, size: 18),
        ),
      ],
    );
  }
}