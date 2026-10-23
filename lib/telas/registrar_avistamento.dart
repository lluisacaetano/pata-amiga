// Biblioteca dart:io: arquivo da foto escolhida na galeria.
import 'dart:io';

// Pacote flutter/foundation: detecção da versão web (kIsWeb).
import 'package:flutter/foundation.dart';
// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote image_picker: abre a câmera ou a galeria para escolher fotos.
import 'package:image_picker/image_picker.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

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
// Arquivo foto_animal.dart: foto do animal no cabeçalho.
import '../widgets/foto_animal.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo cartao_de_secao.dart: cartão com título de seção do formulário.
import '../widgets/cartao_de_secao.dart';
// Arquivo mapa_de_local.dart: coordenada do centro de Formiga.
import '../widgets/mapa_de_local.dart';
// Arquivo seletor_de_local.dart: seletor de local com busca, mira e mapa.
import '../widgets/seletor_de_local.dart';

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
  final _seletorDeFoto = ImagePicker();

  late DateTime _data = _hoje();
  // Ponto onde o mapa abre e o local marcado pela pessoa no seletor
  late LatLng _inicio;
  late LocalEscolhido _local;
  bool _salvando = false;
  XFile? _foto;

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
    _inicio = ultimo != null
        ? LatLng(ultimo.latitude, ultimo.longitude)
        : widget.animal.temPonto
        ? LatLng(widget.animal.latitude!, widget.animal.longitude!)
        : centroDeFormiga;
    _local = (ponto: _inicio, rua: '', bairro: '');
  }

  // Abre o calendário para escolher o dia do avistamento
  Future<void> _escolherData() async {
    final hoje = _hoje();
    final publicado = widget.animal.publicadoEm;
    final desde = DateTime(publicado.year, publicado.month, publicado.day);
    // Intervalo válido: da publicação do animal até hoje. Uma data de
    // publicação no futuro (relógio adiantado) fica limitada a hoje, para o
    // calendário não receber um intervalo invertido
    final primeira = desde.isAfter(hoje) ? hoje : desde;
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data.isBefore(primeira) ? primeira : _data,
      firstDate: primeira,
      lastDate: hoje,
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
    if (_local.rua.trim().isEmpty || _local.bairro.trim().isEmpty) {
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
      latitude: _local.ponto.latitude,
      longitude: _local.ponto.longitude,
      rua: _local.rua,
      bairro: _local.bairro,
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
          CartaoDeSecao(
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
          CartaoDeSecao(
            icone: Icons.location_on_outlined,
            titulo: 'Onde você viu',
            child: SeletorDeLocal(
              inicio: _inicio,
              aoMudar: (local) => _local = local,
            ),
          ),
          CartaoDeSecao(
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
