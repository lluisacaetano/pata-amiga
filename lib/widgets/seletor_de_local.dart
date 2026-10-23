// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter_map: mapa interativo com os blocos do OpenStreetMap.
import 'package:flutter_map/flutter_map.dart';
// Pacote geocoding: converte coordenadas em endereço e endereço em coordenadas.
import 'package:geocoding/geocoding.dart';
// Pacote geolocator: lê a localização atual do aparelho e pede a permissão.
import 'package:geolocator/geolocator.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';

// Arquivo bairros_formiga.dart: bairros de Formiga e o nome padronizado.
import '../dados/bairros_formiga.dart';
// Arquivo bairro_service.dart: bairro pelo CEP ou pela rua (ViaCEP).
import '../services/bairro_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo mapa_de_local.dart: mapa pequeno com pino fixo no centro.
import 'mapa_de_local.dart';

// Local escolhido: as coordenadas do pino e o endereço correspondente
typedef LocalEscolhido = ({LatLng ponto, String rua, String bairro});

// Seletor de local com três formas de marcar o ponto: digitar o endereço,
// usar a localização do aparelho ou destravar e arrastar o mapa. Ao mover o
// mapa, o campo de busca recebe o endereço do ponto. Cada mudança é
// informada por [aoMudar]
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

  // Informa a tela sobre o ponto e o endereço atuais
  void _avisarATela() => widget.aoMudar((
    ponto: _ponto,
    rua: _endereco?.rua ?? '',
    bairro: _endereco?.bairro ?? '',
  ));

  // Converte o ponto do pino em rua e bairro (geocodificação reversa). Se o
  // aparelho não informar o bairro, consulta o ViaCEP pelo CEP ou pela rua.
  // Descarta o resultado se o pino mudou durante a consulta
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

  // Centraliza o mapa no ponto e atualiza o endereço
  void _moverPara(LatLng ponto) {
    _ponto = ponto;
    _mapa.move(ponto, 17);
    _avisarATela();
    _lerEndereco();
  }

  // Procura o endereço digitado em Formiga e move o mapa para ele
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

  // Usa a localização do aparelho, pedindo a permissão se necessário
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

    // Borda arredondada do campo de busca
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
        // Endereço do ponto atual, ou o estado da consulta
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
