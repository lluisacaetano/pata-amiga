import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../modelos/animal.dart';
import '../tema/cores.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/cuidado.dart';
import '../widgets/escolha_de_tipo.dart';
import '../widgets/foto_animal.dart';

String _comMaiuscula(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

String _exemploDeObservacoes(TipoRegistro tipo) => switch (tipo) {
  TipoRegistro.adocao => 'Temperamento, convívio com crianças e outros animais',
  TipoRegistro.perdido => 'Onde e quando sumiu, coleira, se atende pelo nome',
  TipoRegistro.resgate => 'Onde está, em que estado, se corre risco',
};

// Sem tipo escolhido o cartão do lugar já existe, e usa o texto do caso comum
String _tituloDoLugar(TipoRegistro? tipo) =>
    (tipo ?? TipoRegistro.adocao).tituloDoLugar;

const _nomePadrao = 'Sem nome';
const _maximoDeFotos = 5;
// Aviso de quantidade de imagens selecionadas
const _porExtenso = {2: 'duas', 3: 'três', 4: 'quatro', 5: 'cinco'};
const _ladoDaMiniatura = 84.0;
const _alvoDeToque = 44.0;
// Badge de remover foto
const _desenhoDoBadge = 20.0;
const _quantoSobrevoa = 6.0;
const _folgaDaTira = _quantoSobrevoa + (_alvoDeToque - _desenhoDoBadge) / 2;

const _especies = ['Cachorro', 'Gato'];
const _portes = ['pequeno', 'médio', 'grande'];
const _sexos = ['macho', 'fêmea'];

class CadastroAnimal extends StatefulWidget {
  const CadastroAnimal({super.key});

  @override
  State<CadastroAnimal> createState() => _CadastroAnimalState();
}

class _CadastroAnimalState extends State<CadastroAnimal> {
  TipoRegistro? _tipo;
  bool _tentouCadastrar = false;
  final _seletorDeFotos = ImagePicker();
  bool _buscandoLocalizacao = false;
  final List<XFile> _fotos = [];
  bool _castrado = false;
  bool _vacinado = false;
  bool _vermifugado = false;
  String? _especie;
  String? _porte;
  String? _sexo;

  final _nome = TextEditingController();
  final _raca = TextEditingController();
  final _idade = TextEditingController();
  final _observacoes = TextEditingController();
  final _necessidades = TextEditingController();
  final _localizacao = TextEditingController();
  final _responsavel = TextEditingController();
  final _telefone = TextEditingController();

  bool _faltando(TextEditingController campo) =>
      _tentouCadastrar && campo.text.trim().isEmpty;

  bool _naoEscolhido(String? valor) => _tentouCadastrar && valor == null;

  Future<void> _usarMinhaLocalizacao() async {
    if (_buscandoLocalizacao) return;
    setState(() => _buscandoLocalizacao = true);

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
        _avisar('Sem permissão de localização. Insira o endereço manualmente.');
        return;
      }

      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: _ajustesDeLocalizacao(),
      );
      final lugares = await Geocoding()
          .placemarkFromCoordinates(posicao.latitude, posicao.longitude);
      if (lugares.isEmpty) {
        _avisar('Não achei o endereço deste ponto. Insira o endereço manualmente.');
        return;
      }

      if (!mounted) return;
      setState(() => _localizacao.text = _enderecoDe(lugares.first));
    } on TimeoutException {
      _avisar('A localização demorou demais. Insira o endereço manualmente.');
    } on Exception {
      _avisar('Não foi possível encontrar a localização. Insira o endereço manualmente.');
    } finally {
      if (mounted) setState(() => _buscandoLocalizacao = false);
    }
  }

  // O provedor do Google exige o serviço de precisão ligado e um diálogo a mais
  LocationSettings _ajustesDeLocalizacao() {
    const prazo = Duration(seconds: 15);
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(forceLocationManager: true, timeLimit: prazo);
    }
    return const LocationSettings(timeLimit: prazo);
  }

  // O rótulo do campo pede rua, bairro e cidade, nesta ordem
  String _enderecoDe(Placemark lugar) {
    final partes = <String>[];
    void juntar(String? parte) {
      final texto = parte?.trim() ?? '';
      if (texto.isNotEmpty && !partes.contains(texto)) partes.add(texto);
    }

    juntar(lugar.thoroughfare);
    juntar(lugar.subThoroughfare);
    juntar(lugar.subLocality);
    juntar(lugar.locality);
    return partes.join(', ');
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _adicionarFotos() async {
    final vagas = _maximoDeFotos - _fotos.length;
    if (vagas <= 0) return;

    try {
      final escolhidas = await _seletorDeFotos.pickMultiImage(
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (!mounted || escolhidas.isEmpty) return;

      // A galeria do sistema não respeita o limite de seleção,
      // então guardamos só as primeiras 5 fotos
      setState(() => _fotos.addAll(escolhidas.take(vagas)));
      if (escolhidas.length > vagas) {
        _avisarQueSobrou(escolhidas.length, vagas);
      }
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a galeria neste aparelho.'),
        ),
      );
    }
  }

  void _avisarQueSobrou(int escolhidas, int vagas) {
    final quantas =
        vagas == 1 ? 'a primeira' : 'as ${_porExtenso[vagas] ?? vagas} primeiras';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Você escolheu $escolhidas fotos e cabem $vagas. Guardei $quantas.',
        ),
      ),
    );
  }

  void _reordenarFotos(int indiceAntigo, int novoIndice) {
    setState(() {
      final foto = _fotos.removeAt(indiceAntigo);
      novoIndice = novoIndice.clamp(0, _fotos.length);
      _fotos.insert(novoIndice, foto);
    });
  }

  void _removerFoto(int indice) => setState(() => _fotos.removeAt(indice));

  @override
  void dispose() {
    for (final campo in [
      _nome,
      _raca,
      _idade,
      _observacoes,
      _necessidades,
      _localizacao,
      _responsavel,
      _telefone,
    ]) {
      campo.dispose();
    }
    super.dispose();
  }

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
          'CADASTRAR ANIMAL',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Cores.principal,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Cartao(
              child: _BlocoDeFotos(
                fotos: _fotos,
                aoAdicionar: _adicionarFotos,
                aoReordenar: _reordenarFotos,
                aoRemover: _removerFoto,
              ),
            ),
            _Cartao(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TituloDoCartao(icone: Icons.pets, texto: 'O animal'),
                  const SizedBox(height: 16),
                  const _Rotulo('Tipo'),
                  const SizedBox(height: 6),
                  EscolhaDeTipo(
                    escolhido: _tipo,
                    aoEscolher: (escolha) => setState(() => _tipo = escolha),
                    rotulo: rotuloSingular,
                    fundoDaOpcao: Cores.fundo,
                  ),
                  if (_tipo != null) ...[
                    const SizedBox(height: 16),
                    _Campo(
                      rotulo: 'Nome',
                      controlador: _nome,
                      aviso:
                          'O nome não é obrigatório: sem ele, o animal entra '
                          'como "$_nomePadrao"',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Selecao(
                            rotulo: 'Espécie',
                            opcoes: _especies,
                            valor: _especie,
                            comErro: _naoEscolhido(_especie),
                            aoEscolher: (escolha) =>
                                setState(() => _especie = escolha),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Selecao(
                            rotulo: 'Porte',
                            opcoes: _portes,
                            valor: _porte,
                            comErro: _naoEscolhido(_porte),
                            aoEscolher: (escolha) =>
                                setState(() => _porte = escolha),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Campo(
                            rotulo: 'Raça',
                            controlador: _raca,
                            exemplo: 'Sem raça definida',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Campo(
                            rotulo: 'Idade',
                            controlador: _idade,
                            exemplo: '2 anos',
                            comErro: _faltando(_idade),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Selecao(
                      rotulo: 'Sexo',
                      opcoes: _sexos,
                      valor: _sexo,
                      aoEscolher: (escolha) => setState(() => _sexo = escolha),
                    ),
                    const SizedBox(height: 14),
                    _Campo(
                      rotulo: 'Observações',
                      controlador: _observacoes,
                      exemplo: _exemploDeObservacoes(_tipo!),
                      linhas: 3,
                      comErro: _faltando(_observacoes),
                    ),
                    if (_tipo != TipoRegistro.resgate) ...[
                      const SizedBox(height: 14),
                      _Campo(
                        rotulo: 'Necessidades especiais',
                        controlador: _necessidades,
                        exemplo: 'Remédio de uso contínuo, deficiência, dieta',
                        linhas: 2,
                      ),
                    ],
                    if (_tipo == TipoRegistro.adocao) ...[
                      const SizedBox(height: 16),
                      const _Rotulo('Cuidados'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _Cuidado(
                              rotulo: 'Castrado',
                              marcado: _castrado,
                              aoMarcar: (valor) =>
                                  setState(() => _castrado = valor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Cuidado(
                              rotulo: 'Vacinado',
                              marcado: _vacinado,
                              aoMarcar: (valor) =>
                                  setState(() => _vacinado = valor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Cuidado(
                              rotulo: 'Vermifugado',
                              marcado: _vermifugado,
                              aoMarcar: (valor) =>
                                  setState(() => _vermifugado = valor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            _Cartao(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TituloDoCartao(
                    icone: Icons.location_on_outlined,
                    texto: _tituloDoLugar(_tipo),
                  ),
                  const SizedBox(height: 16),
                  _Campo(
                    rotulo: 'Localização',
                    controlador: _localizacao,
                    exemplo: 'Rua, Bairro e Cidade',
                    comErro: _faltando(_localizacao),
                    acao: IconButton(
                      onPressed:
                          _buscandoLocalizacao ? null : _usarMinhaLocalizacao,
                      // Icone de buscando localização
                      icon: _buscandoLocalizacao
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 20),
                      color: Cores.principal,
                      tooltip: 'Usar minha localização',
                    ),
                  ),
                ],
              ),
            ),
            if (_tipo != null)
              _Cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TituloDoCartao(
                      icone: Icons.person_outline,
                      texto: _tipo!.tituloDoContato,
                    ),
                    const SizedBox(height: 16),
                    _Campo(
                      rotulo: 'Responsável',
                      controlador: _responsavel,
                      comErro: _faltando(_responsavel),
                    ),
                    const SizedBox(height: 14),
                    _Campo(
                      rotulo: 'Telefone',
                      controlador: _telefone,
                      exemplo: '(37) 90000-0000',
                      comErro: _faltando(_telefone),
                      teclado: TextInputType.phone,
                      formatadores: [_MascaraDeTelefone()],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => setState(() => _tentouCadastrar = true),
              icon: const Icon(Icons.pets, size: 18),
              label: const Text('Cadastrar'),
              style: FilledButton.styleFrom(
                backgroundColor: Cores.principal,
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
      ),
      bottomNavigationBar: BarraInferior(
        aoTocar: (indice) {
          if (indice == 0) {
            Navigator.maybePop(context);
          } else {
            avisarProximaSprint(context);
          }
        },
      ),
    );
  }
}

class _BlocoDeFotos extends StatelessWidget {
  final List<XFile> fotos;
  final VoidCallback aoAdicionar;
  final ReorderCallback aoReordenar;
  final ValueChanged<int> aoRemover;

  const _BlocoDeFotos({
    required this.fotos,
    required this.aoAdicionar,
    required this.aoReordenar,
    required this.aoRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TituloDoCartao(
          icone: Icons.photo_camera_outlined,
          texto: 'Fotos',
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: aoAdicionar,
            behavior: HitTestBehavior.opaque,
            child: LayoutBuilder(
              builder: (context, restricoes) {
                final lado = restricoes.maxWidth * 0.62;
                return SizedBox(
                  width: lado,
                  child: fotos.isEmpty
                      ? FotoAnimal(caminho: '', altura: lado)
                      : _FotoDaGaleria(arquivo: fotos.first, altura: lado),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Você pode escolher até $_maximoDeFotos fotos.',
          style: TextStyle(fontSize: 12, color: Cores.textoFraco),
        ),
        if (fotos.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'A primeira foto é a capa. Segure e arraste para ordenar.',
            style: TextStyle(fontSize: 12, color: Cores.textoFraco),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _ladoDaMiniatura + _folgaDaTira,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              onReorderItem: aoReordenar,
              itemCount: fotos.length < _maximoDeFotos
                  ? fotos.length + 1
                  : fotos.length,
              itemBuilder: (context, indice) {
                if (indice == fotos.length) {
                  return Padding(
                    key: const ValueKey('adicionar-foto'),
                    padding: const EdgeInsets.only(right: 10, top: _folgaDaTira),
                    child: _AdicionarFoto(aoTocar: aoAdicionar),
                  );
                }

                return Padding(
                  key: ValueKey(fotos[indice].path),
                  padding: const EdgeInsets.only(right: 10, top: _folgaDaTira),
                  child: ReorderableDelayedDragStartListener(
                    index: indice,
                    child: _Miniatura(
                      arquivo: fotos[indice],
                      ehCapa: indice == 0,
                      aoRemover: () => aoRemover(indice),
                    ),
                  ),
                );
              },
            ),
          ),
          if (fotos.length >= _maximoDeFotos)
            const _Recado('Você chegou no limite de $_maximoDeFotos fotos'),
        ],
      ],
    );
  }
}

class _AdicionarFoto extends StatelessWidget {
  final VoidCallback aoTocar;

  const _AdicionarFoto({required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTocar,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Cores.fundo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Cores.borda),
        ),
        child: const Icon(
          Icons.add_a_photo_outlined,
          size: 22,
          color: Cores.principal,
        ),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  final XFile arquivo;
  final bool ehCapa;
  final VoidCallback aoRemover;

  const _Miniatura({
    required this.arquivo,
    required this.ehCapa,
    required this.aoRemover,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ladoDaMiniatura,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _FotoDaGaleria(arquivo: arquivo, altura: _ladoDaMiniatura),
          ),
          if (ehCapa)
            const Positioned(left: 4, bottom: 4, child: _SeloDeCapa()),
          Positioned(
            top: -_folgaDaTira,
            right: -_folgaDaTira,
            child: _BotaoDeRemover(aoTocar: aoRemover),
          ),
        ],
      ),
    );
  }
}

// Badge de remover foto 
class _BotaoDeRemover extends StatelessWidget {
  final VoidCallback aoTocar;

  const _BotaoDeRemover({required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Remover foto',
      child: InkResponse(
        onTap: aoTocar,
        radius: _alvoDeToque / 2,
        child: SizedBox(
          width: _alvoDeToque,
          height: _alvoDeToque,
          child: Center(
            child: Container(
              width: _desenhoDoBadge,
              height: _desenhoDoBadge,
              decoration: BoxDecoration(
                color: Cores.destaque,
                shape: BoxShape.circle,
                border: Border.all(color: Cores.cartao, width: 1.5),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 12,
                color: Cores.cartao,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Selo de imagem de capa para a primeira foto
class _SeloDeCapa extends StatelessWidget {
  const _SeloDeCapa();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Cores.principal,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          'Capa',
          style: TextStyle(
            color: Cores.cartao,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FotoDaGaleria extends StatefulWidget {
  final XFile arquivo;
  final double altura;

  const _FotoDaGaleria({required this.arquivo, required this.altura});

  @override
  State<_FotoDaGaleria> createState() => _FotoDaGaleriaState();
}

class _FotoDaGaleriaState extends State<_FotoDaGaleria> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.arquivo.readAsBytes();
  }

  @override
  void didUpdateWidget(_FotoDaGaleria anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.arquivo.path != widget.arquivo.path) {
      _bytes = widget.arquivo.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, instantaneo) {
        if (!instantaneo.hasData) {
          return FotoAnimal(caminho: '', altura: widget.altura);
        }

        return ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: SizedBox(
            height: widget.altura,
            width: double.infinity,
            child: Image.memory(instantaneo.data!, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

class _Cartao extends StatelessWidget {
  final Widget child;

  const _Cartao({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: child,
    );
  }
}

class _TituloDoCartao extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _TituloDoCartao({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 16, color: Cores.principal),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            color: Cores.principal,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

InputDecoration _caixa(String? exemplo, {bool comErro = false, Widget? acao}) =>
    InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Cores.fundo,
      hintText: exemplo,
      suffixIcon: acao,
      hintStyle: const TextStyle(fontSize: 14, color: Cores.textoFraco),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: comErro ? Cores.destaque : Cores.borda,
          width: comErro ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: comErro ? Cores.destaque : Cores.principal,
          width: 1.5,
        ),
      ),
    );

class _Campo extends StatelessWidget {
  final String rotulo;
  final TextEditingController controlador;
  final String? exemplo;
  final String? aviso;
  final Widget? acao;
  final int linhas;
  final bool comErro;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatadores;

  const _Campo({
    required this.rotulo,
    required this.controlador,
    this.exemplo,
    this.aviso,
    this.acao,
    this.linhas = 1,
    this.comErro = false,
    this.teclado,
    this.formatadores,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rotulo(rotulo),
        const SizedBox(height: 6),
        TextField(
          controller: controlador,
          maxLines: linhas,
          keyboardType: teclado,
          inputFormatters: formatadores,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 15),
          decoration: _caixa(exemplo, comErro: comErro, acao: acao),
        ),
        if (comErro) const _Recado('Campo obrigatório', erro: true),
        if (aviso != null && !comErro) _Recado(aviso!),
      ],
    );
  }
}

class _Recado extends StatelessWidget {
  final String texto;
  final bool erro;

  const _Recado(this.texto, {this.erro = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 2),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          color: erro ? Cores.destaque : Cores.textoFraco,
        ),
      ),
    );
  }
}

class _Selecao extends StatelessWidget {
  final String rotulo;
  final List<String> opcoes;
  final String? valor;
  final bool comErro;
  final ValueChanged<String?> aoEscolher;

  const _Selecao({
    required this.rotulo,
    required this.opcoes,
    required this.valor,
    required this.aoEscolher,
    this.comErro = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rotulo(rotulo),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isDense: true,
          decoration: _caixa(null, comErro: comErro),
          hint: const Text(
            'Escolher',
            style: TextStyle(fontSize: 14, color: Cores.textoFraco),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Cores.textoFraco),
          style: const TextStyle(fontSize: 15, color: Cores.texto),
          items: [
            for (final opcao in opcoes)
              DropdownMenuItem(value: opcao, child: Text(_comMaiuscula(opcao))),
          ],
          onChanged: aoEscolher,
        ),
        if (comErro) const _Recado('Campo obrigatório', erro: true),
      ],
    );
  }
}

class _Rotulo extends StatelessWidget {
  final String texto;

  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Cores.textoFraco,
      ),
    );
  }
}

class _Cuidado extends StatelessWidget {
  final String rotulo;
  final bool marcado;
  final ValueChanged<bool> aoMarcar;

  const _Cuidado({
    required this.rotulo,
    required this.marcado,
    required this.aoMarcar,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: marcado,
      child: GestureDetector(
        onTap: () => aoMarcar(!marcado),
        behavior: HitTestBehavior.opaque,
        child: Cuidado(rotulo: rotulo, marcado: marcado),
      ),
    );
  }
}

// Vai desenhando (DD) NNNNN-NNNN conforme se digita, e recusa o que não é dígito
class _MascaraDeTelefone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    final digitos = novo.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digitos.length > 11 ? digitos.substring(0, 11) : digitos;

    final escrita = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 0) escrita.write('(');
      if (i == 2) escrita.write(') ');
      if (limitado.length >= 10 && i == limitado.length - 4) escrita.write('-');
      escrita.write(limitado[i]);
    }

    final texto = escrita.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
