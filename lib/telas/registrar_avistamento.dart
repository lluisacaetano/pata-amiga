// Biblioteca dart:async: tempo limite das buscas de endereço.
import 'dart:async';
// Biblioteca dart:io: arquivo da foto escolhida na galeria.
import 'dart:io';

// Pacote flutter/foundation: detecção da versão web (kIsWeb).
import 'package:flutter/foundation.dart';
// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter_map: mapa interativo com os blocos do OpenStreetMap.
import 'package:flutter_map/flutter_map.dart';
// Pacote geocoding: converte coordenadas em endereço e endereço em coordenadas.
import 'package:geocoding/geocoding.dart';
// Pacote geolocator: lê a localização atual do aparelho e pede a permissão.
import 'package:geolocator/geolocator.dart';
// Pacote image_picker: abre a câmera ou a galeria para escolher fotos.
import 'package:image_picker/image_picker.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo bairros_formiga.dart: bairro informado pelo geocoder.
import '../dados/bairros_formiga.dart';
// Arquivo estado_pata_amiga.dart: avistamentos já registrados.
import '../estado/estado_pata_amiga.dart';
// Arquivo animal.dart: modelo do animal.
import '../modelos/animal.dart';
// Arquivo avistamento.dart: modelo do avistamento e o último registro.
import '../modelos/avistamento.dart';
// Arquivo usuario_provider.dart: nome de quem registra.
import '../provider/usuario_provider.dart';
// Arquivo avistamento_service.dart: gravação do avistamento na API.
import '../services/avistamento_service.dart';
// Arquivo bairro_service.dart: consulta de bairro no ViaCEP.
import '../services/bairro_service.dart';
// Arquivo foto_animal.dart: foto do animal no cabeçalho.
import '../widgets/foto_animal.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo mapa_de_local.dart: mapa com pino e centro de Formiga.
import '../widgets/mapa_de_local.dart';

// Formulário para registrar que um animal perdido foi visto: data, local no
// mapa e foto opcional. Ao gravar, devolve o avistamento à ficha do animal,
// que oferece avisar o responsável
class RegistrarAvistamento extends StatefulWidget {
  // Animal que foi visto
  final Animal animal;
  // Serviço opcional, para os testes injetarem uma versão falsa
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
  // Campo de busca por endereço, que move o mapa até o local digitado
  final _busca = TextEditingController();
  bool _buscandoNoMapa = false;
  String? _avisoDaBusca;

  // Data de hoje sem a hora, para comparar dias
  static DateTime _hoje() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  @override
  void initState() {
    super.initState();
    // O mapa abre no último avistamento; sem ele, no local do cadastro do
    // animal; sem os dois, no centro de Formiga
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

  // Move o mapa até o endereço digitado. O ponto gravado é sempre o do
  // pino, que o usuário ainda pode ajustar arrastando o mapa
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

  // Converte o ponto do pino em rua e bairro, para o usuário conferir e para
  // preencher o campo de busca
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
        // Quando o geocoder não informa o bairro, consulta o ViaCEP pelo CEP
        // ou pela rua
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
    // Descarta o resultado se o pino mudou durante a busca
    if (!mounted || ponto != _ponto) return;
    setState(() {
      _endereco = lido;
      _buscandoEndereco = false;
      // O campo de busca passa a mostrar o endereço do pino
      final lugar = [
        lido?.rua ?? '',
        lido?.bairro ?? '',
      ].where((parte) => parte.isNotEmpty).join(', ');
      if (lugar.isNotEmpty) _busca.text = lugar;
    });
  }

  // Move o pino para a localização atual do aparelho, pedindo permissão
  // quando necessário
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

  // Abre o calendário para escolher o dia do avistamento
  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      // Intervalo válido: da publicação do animal até hoje
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

  // Abre a galeria para anexar uma foto opcional
  Future<void> _escolherFoto() async {
    try {
      final foto = await _seletorDeFoto.pickImage(source: ImageSource.gallery);
      if (foto != null && mounted) setState(() => _foto = foto);
    } on Exception {
      _avisar('Não foi possível abrir a galeria neste aparelho.');
    }
  }

  // Valida o endereço e grava o avistamento na API
  Future<void> _registrar() async {
    if (_salvando) return;
    // Rua e bairro são obrigatórios, pois indicam ao responsável onde
    // procurar
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

  // Mostra uma mensagem curta no rodapé, substituindo a anterior
  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // Data escolhida no formato dd/mm/aaaa, com "Hoje" ou "Ontem" quando couber
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
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.sobrePrincipal,
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

// Cabeçalho com a foto e o nome do animal procurado
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

// Linha que mostra o endereço do pino ou o andamento da busca
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

// Cartão de seção do formulário, com ícone e título
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
