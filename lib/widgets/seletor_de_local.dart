import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../dados/bairros_formiga.dart';
import '../services/bairro_service.dart';
import '../tema/cores.dart';
import 'mapa_de_local.dart';

// O lugar escolhido: o ponto do pino e o endereço que ele representa
typedef LocalEscolhido = ({LatLng ponto, String rua, String bairro});

// Marcar um lugar de três formas: escrevendo o endereço, tocando na mira para
// usar a localização ou destravando e arrastando o mapa. Mexer no mapa preenche a busca com
// o endereço do ponto. Avisa a tela a cada mudança
class SeletorDeLocal extends StatefulWidget {
  final LatLng inicio;
  final ValueChanged<LocalEscolhido> aoMudar;

  const SeletorDeLocal({
    super.key,
    this.inicio = centroDeFormiga,
    required this.aoMudar,
  });

  @override
  State<SeletorDeLocal> createState() => _SeletorDeLocalState();
}

class _SeletorDeLocalState extends State<SeletorDeLocal> {
  final _mapa = MapController();
  final _busca = TextEditingController();
  final _bairros = BairroService();
  late LatLng _ponto = widget.inicio;
  ({String rua, String bairro})? _endereco;
  bool _lendoEndereco = false;
  bool _buscando = false;
  bool _buscandoPosicao = false;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    _lerEndereco();
  }

  @override
  void dispose() {
    _mapa.dispose();
    _busca.dispose();
    super.dispose();
  }

  void _avisarATela() => widget.aoMudar((
    ponto: _ponto,
    rua: _endereco?.rua ?? '',
    bairro: _endereco?.bairro ?? '',
  ));

  // O endereço do pino; sem bairro do Android, o ViaCEP completa
  Future<void> _lerEndereco() async {
    final ponto = _ponto;
    setState(() => _lendoEndereco = true);
    ({String rua, String bairro})? lido;
    try {
      final lugares = await Geocoding()
          .placemarkFromCoordinates(ponto.latitude, ponto.longitude)
          .timeout(const Duration(seconds: 8));
      if (lugares.isNotEmpty) {
        final lugar = lugares.first;
        final rua = lugar.thoroughfare?.trim() ?? '';
        var bairro = bairroDoServico(lugar.subLocality, lugar.locality);
        if (bairro.isEmpty) {
          bairro =
              await _bairros.pelaCep(lugar.postalCode) ??
              await _bairros.pelaRua(rua) ??
              '';
        }
        lido = (rua: rua, bairro: bairro);
      }
    } on Exception {
      lido = null;
    }
    if (!mounted || ponto != _ponto) return;
    setState(() {
      _endereco = lido;
      _lendoEndereco = false;
      final lugar = [
        lido?.rua ?? '',
        lido?.bairro ?? '',
      ].where((parte) => parte.isNotEmpty).join(', ');
      if (lugar.isNotEmpty) _busca.text = lugar;
    });
    _avisarATela();
  }

  void _moverPara(LatLng ponto) {
    _ponto = ponto;
    _mapa.move(ponto, 17);
    _avisarATela();
    _lerEndereco();
  }

  Future<void> _buscarNoMapa() async {
    final texto = _busca.text.trim();
    if (texto.isEmpty || _buscando) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _buscando = true;
      _aviso = null;
    });
    String? aviso;
    try {
      final achados = await Geocoding()
          .locationFromAddress('$texto, Formiga, MG, Brasil')
          .timeout(const Duration(seconds: 8));
      if (achados.isEmpty) {
        aviso =
            'Não encontrei esse endereço em Formiga. Confira o nome ou '
            'destrave o mapa e arraste.';
      } else if (mounted) {
        _moverPara(LatLng(achados.first.latitude, achados.first.longitude));
      }
    } on Exception {
      aviso = 'Não foi possível buscar o endereço agora. Arraste o mapa.';
    }
    if (!mounted) return;
    setState(() {
      _buscando = false;
      _aviso = aviso;
    });
  }

  Future<void> _usarMinhaPosicao() async {
    if (_buscandoPosicao) return;
    setState(() => _buscandoPosicao = true);
    String? aviso;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        aviso = 'Ligue a localização do aparelho para usar a mira.';
      } else {
        var permissao = await Geolocator.checkPermission();
        if (permissao == LocationPermission.denied) {
          permissao = await Geolocator.requestPermission();
        }
        if (permissao == LocationPermission.denied ||
            permissao == LocationPermission.deniedForever) {
          aviso = 'Sem permissão de localização. Arraste o mapa até o local.';
        } else {
          final posicao = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              timeLimit: Duration(seconds: 15),
            ),
          );
          if (mounted) {
            _moverPara(LatLng(posicao.latitude, posicao.longitude));
          }
        }
      }
    } on Exception {
      aviso = 'Não foi possível encontrar a localização. Arraste o mapa.';
    }
    if (!mounted) return;
    setState(() {
      _buscandoPosicao = false;
      _aviso = aviso;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lugar = [
      _endereco?.rua ?? '',
      _endereco?.bairro ?? '',
    ].where((parte) => parte.isNotEmpty).join(', ');

    OutlineInputBorder borda(Color cor, [double largura = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cor, width: largura),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Escreva o endereço, toque na mira para usar sua localização ou '
          'destrave o mapa e arraste até o pino.',
          style: TextStyle(fontSize: 13, color: context.cores.textoFraco),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _busca,
          textInputAction: TextInputAction.search,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _buscarNoMapa(),
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: context.cores.fundo,
            hintText: 'Buscar endereço (rua e número)',
            hintStyle: TextStyle(fontSize: 14, color: context.cores.textoFraco),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              tooltip: 'Buscar no mapa',
              onPressed: _buscando ? null : _buscarNoMapa,
              icon: _buscando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.search, color: context.cores.principal),
            ),
            enabledBorder: borda(context.cores.borda),
            focusedBorder: borda(context.cores.principal, 1.5),
          ),
        ),
        if (_aviso != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(
              _aviso!,
              style: TextStyle(fontSize: 12, color: context.cores.destaque),
            ),
          ),
        const SizedBox(height: 10),
        MapaDeLocal(
          controlador: _mapa,
          inicio: _ponto,
          buscandoPosicao: _buscandoPosicao,
          aoUsarMinhaLocalizacao: _usarMinhaPosicao,
          aoArrastar: (centro) {
            _ponto = centro;
            _avisarATela();
            _lerEndereco();
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.place_outlined, size: 16, color: context.cores.principal),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _lendoEndereco
                    ? 'Buscando o endereço deste ponto…'
                    : lugar.isEmpty
                    ? 'Endereço não encontrado. O ponto do mapa será usado.'
                    : lugar,
                style: TextStyle(
                  fontSize: 14,
                  color: lugar.isEmpty || _lendoEndereco
                      ? context.cores.textoFraco
                      : context.cores.principal,
                  fontWeight: lugar.isEmpty || _lendoEndereco
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
