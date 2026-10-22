import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../dados/bairros_formiga.dart';
import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../modelos/avistamento.dart';
import '../provider/usuario_provider.dart';
import '../services/avistamento_service.dart';
import '../services/bairro_service.dart';
import '../widgets/foto_animal.dart';
import '../tema/cores.dart';
import '../widgets/mapa_de_local.dart';

// Quem viu um animal perdido conta quando e onde, e pode mandar uma foto.
// Devolve o avistamento gravado para a ficha, que oferece avisar o tutor
class RegistrarAvistamento extends StatefulWidget {
  final Animal animal;
  final AvistamentoService? servico;

  const RegistrarAvistamento({super.key, required this.animal, this.servico});

  @override
  State<RegistrarAvistamento> createState() => _RegistrarAvistamentoState();
}

class _RegistrarAvistamentoState extends State<RegistrarAvistamento> {
  late final _servico = widget.servico ?? AvistamentoService();
  final _mapa = MapController();
  final _seletorDeFoto = ImagePicker();

  late DateTime _data = _hoje();
  late LatLng _ponto;
  ({String rua, String bairro})? _endereco;
  bool _buscandoEndereco = false;
  bool _buscandoPosicao = false;
  bool _salvando = false;
  XFile? _foto;
  // Quem prefere escrever o endereço: a busca leva o mapa até lá
  final _busca = TextEditingController();
  bool _buscandoNoMapa = false;
  String? _avisoDaBusca;

  static DateTime _hoje() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  @override
  void initState() {
    super.initState();
    // O mapa abre onde o animal foi visto por último, ou onde foi cadastrado
    final ultimo = ultimoAvistamento(
      widget.animal,
      PataAmigaScope.talvez(context)?.avistamentos ?? const [],
    );
    _ponto = ultimo != null
        ? LatLng(ultimo.latitude, ultimo.longitude)
        : widget.animal.temPonto
        ? LatLng(widget.animal.latitude!, widget.animal.longitude!)
        : centroDeFormiga;
    _lerEndereco();
  }

  @override
  void dispose() {
    _mapa.dispose();
    _busca.dispose();
    super.dispose();
  }

  // Leva o mapa até o endereço digitado. O ponto salvo continua sendo o do
  // pino, então a pessoa vê onde o endereço caiu e ainda pode arrastar
  Future<void> _buscarNoMapa() async {
    final texto = _busca.text.trim();
    if (texto.isEmpty || _buscandoNoMapa) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _buscandoNoMapa = true;
      _avisoDaBusca = null;
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
        _ponto = LatLng(achados.first.latitude, achados.first.longitude);
        _mapa.move(_ponto, 17);
        _lerEndereco();
      }
    } on Exception {
      aviso = 'Não foi possível buscar o endereço agora. Arraste o mapa.';
    }
    if (!mounted) return;
    setState(() {
      _buscandoNoMapa = false;
      _avisoDaBusca = aviso;
    });
  }

  // O endereço do ponto do pino, para a pessoa conferir onde marcou
  Future<void> _lerEndereco() async {
    setState(() => _buscandoEndereco = true);
    final ponto = _ponto;
    ({String rua, String bairro})? lido;
    try {
      final lugares = await Geocoding()
          .placemarkFromCoordinates(ponto.latitude, ponto.longitude)
          .timeout(const Duration(seconds: 8));
      if (lugares.isNotEmpty) {
        final lugar = lugares.first;
        final rua = lugar.thoroughfare?.trim() ?? '';
        var bairro = bairroDoServico(lugar.subLocality, lugar.locality);
        // Sem bairro do Android, o ViaCEP completa pelo CEP ou pela rua
        if (bairro.isEmpty) {
          final servico = BairroService();
          bairro =
              await servico.pelaCep(lugar.postalCode) ??
              await servico.pelaRua(rua) ??
              '';
        }
        lido = (rua: rua, bairro: bairro);
      }
    } on Exception {
      lido = null;
    }
    // Se o pino mudou enquanto buscava, este endereço já não vale
    if (!mounted || ponto != _ponto) return;
    setState(() {
      _endereco = lido;
      _buscandoEndereco = false;
      // O campo de busca acompanha o pino: mexeu no mapa, o endereço aparece
      final lugar = [
        lido?.rua ?? '',
        lido?.bairro ?? '',
      ].where((parte) => parte.isNotEmpty).join(', ');
      if (lugar.isNotEmpty) _busca.text = lugar;
    });
  }

  Future<void> _irParaMinhaPosicao() async {
    if (_buscandoPosicao) return;
    setState(() => _buscandoPosicao = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _avisar('Ligue a localização do aparelho para usar esta opção.');
        return;
      }
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        _avisar('Sem permissão de localização. Arraste o mapa até o local.');
        return;
      }
      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      _ponto = LatLng(posicao.latitude, posicao.longitude);
      _mapa.move(_ponto, 17);
      _lerEndereco();
    } on Exception {
      _avisar('Não foi possível encontrar a localização. Arraste o mapa.');
    } finally {
      if (mounted) setState(() => _buscandoPosicao = false);
    }
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      // Não dá para ter visto antes de o animal sumir, nem no futuro
      firstDate: DateTime(
        widget.animal.publicadoEm.year,
        widget.animal.publicadoEm.month,
        widget.animal.publicadoEm.day,
      ),
      lastDate: _hoje(),
      helpText: 'Quando você viu?',
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<void> _escolherFoto() async {
    try {
      final foto = await _seletorDeFoto.pickImage(source: ImageSource.gallery);
      if (foto != null && mounted) setState(() => _foto = foto);
    } on Exception {
      _avisar('Não foi possível abrir a galeria neste aparelho.');
    }
  }

  Future<void> _registrar() async {
    if (_salvando) return;
    // O endereço é obrigatório: é ele que diz ao tutor onde procurar
    final endereco = _endereco;
    if (endereco == null ||
        endereco.rua.trim().isEmpty ||
        endereco.bairro.trim().isEmpty) {
      _avisar(
        'Marque no mapa onde o animal foi visto, com rua e bairro, antes de '
        'registrar.',
      );
      return;
    }
    setState(() => _salvando = true);
    final nome = context.read<UsuarioProvider?>()?.usuario.nome.trim() ?? '';
    final novo = Avistamento(
      animal: widget.animal.chave,
      data: _data,
      latitude: _ponto.latitude,
      longitude: _ponto.longitude,
      rua: _endereco?.rua ?? '',
      bairro: _endereco?.bairro ?? '',
      foto: _foto?.path ?? '',
      registradoPor: nome,
      registradoEm: DateTime.now(),
    );
    try {
      final gravado = await _servico.registrar(novo);
      if (!mounted) return;
      Navigator.pop(context, gravado);
    } on Exception {
      if (!mounted) return;
      setState(() => _salvando = false);
      _avisar('Não foi possível registrar agora. Tente de novo.');
    }
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String get _textoDaData {
    String dois(int numero) => numero.toString().padLeft(2, '0');
    final data = '${dois(_data.day)}/${dois(_data.month)}/${_data.year}';
    final dias = _hoje().difference(_data).inDays;
    if (dias == 0) return 'Hoje, $data';
    if (dias == 1) return 'Ontem, $data';
    return data;
  }

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
          'REGISTRAR AVISTAMENTO',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _CabecalhoDoAnimal(animal: widget.animal),
          _Cartao(
            icone: Icons.event_outlined,
            titulo: 'Quando',
            child: InkWell(
              onTap: _escolherData,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: context.cores.fundo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.cores.borda),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _textoDaData,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: context.cores.principal,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _Cartao(
            icone: Icons.location_on_outlined,
            titulo: 'Onde',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Escreva o endereço, toque na mira para usar sua localização '
                  'ou destrave o mapa e arraste até o pino ficar onde você viu o animal.',
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
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: context.cores.textoFraco,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Buscar no mapa',
                      onPressed: _buscandoNoMapa ? null : _buscarNoMapa,
                      icon: _buscandoNoMapa
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.search, color: context.cores.principal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.cores.borda),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.cores.principal,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (_avisoDaBusca != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 2),
                    child: Text(
                      _avisoDaBusca!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.cores.destaque,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                MapaDeLocal(
                  controlador: _mapa,
                  inicio: _ponto,
                  buscandoPosicao: _buscandoPosicao,
                  aoUsarMinhaLocalizacao: _irParaMinhaPosicao,
                  aoArrastar: (centro) {
                    _ponto = centro;
                    _lerEndereco();
                  },
                ),
                const SizedBox(height: 10),
                _EnderecoDoPino(
                  buscando: _buscandoEndereco,
                  endereco: _endereco,
                ),
              ],
            ),
          ),
          _Cartao(
            icone: Icons.photo_camera_outlined,
            titulo: 'Foto (opcional)',
            child: _foto == null
                ? OutlinedButton.icon(
                    onPressed: _escolherFoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Escolher uma foto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.cores.principal,
                      side: BorderSide(color: context.cores.principal),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: kIsWeb
                              ? Image.network(_foto!.path, fit: BoxFit.cover)
                              : Image.file(
                                  File(_foto!.path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: context.cores.cartao,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Remover foto',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _foto = null),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _salvando ? null : _registrar,
            icon: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.visibility_outlined, size: 18),
            label: Text(_salvando ? 'Registrando…' : 'Registrar avistamento'),
            style: FilledButton.styleFrom(
              backgroundColor: context.cores.principal,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Quem está sendo procurado: a foto e o nome, com o convite para registrar
class _CabecalhoDoAnimal extends StatelessWidget {
  const _CabecalhoDoAnimal({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: FotoAnimal(
              caminho: animal.foto,
              altura: 64,
              raio: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você viu ${animal.nome}?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Marque quando e onde, para ajudar quem está procurando.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cores.textoFraco,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnderecoDoPino extends StatelessWidget {
  const _EnderecoDoPino({required this.buscando, required this.endereco});

  final bool buscando;
  final ({String rua, String bairro})? endereco;

  @override
  Widget build(BuildContext context) {
    final lugar = [
      endereco?.rua ?? '',
      endereco?.bairro ?? '',
    ].where((parte) => parte.isNotEmpty).join(', ');
    final texto = buscando
        ? 'Buscando o endereço deste ponto…'
        : lugar.isEmpty
        ? 'Endereço não encontrado. O ponto do mapa será usado.'
        : lugar;
    return Row(
      children: [
        Icon(Icons.place_outlined, size: 16, color: context.cores.principal),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              color: lugar.isEmpty || buscando
                  ? context.cores.textoFraco
                  : context.cores.principal,
              fontWeight: lugar.isEmpty || buscando
                  ? FontWeight.normal
                  : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// O mesmo cartão do cadastro de animal: branco, borda clara e título verde
class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.icone,
    required this.titulo,
    required this.child,
  });

  final IconData icone;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: context.cores.principal),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  color: context.cores.principal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
