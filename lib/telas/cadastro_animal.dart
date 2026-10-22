import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../dados/bairros_formiga.dart';
import '../dados/racas.dart';
import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../modelos/dono.dart';
import '../modelos/ong.dart';
import '../provider/usuario_provider.dart';
import '../services/animal_service.dart';
import '../services/bairro_service.dart';
import '../tema/cores.dart';
import '../widgets/proteger_alteracoes.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/cuidado.dart';
import '../widgets/escolha_de_tipo.dart';
import '../widgets/foto_animal.dart';
import '../widgets/mapa_de_local.dart';
import '../widgets/mascaras.dart';
import '../widgets/selecao_com_busca.dart';

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
  // Um animal resgatado sendo publicado para adoção: o formulário abre com os
  // dados dele e o tipo Adoção marcado
  final Animal? base;
  // Um registro já publicado sendo editado por quem o cadastrou: o
  // formulário abre com todos os dados dele e grava antes de fechar
  final Animal? editando;
  final AnimalService? api;

  const CadastroAnimal({super.key, this.base, this.editando, this.api});

  @override
  State<CadastroAnimal> createState() => _CadastroAnimalState();
}

class _CadastroAnimalState extends State<CadastroAnimal> {
  TipoRegistro? _tipo;
  bool _tentouCadastrar = false;
  final _seletorDeFotos = ImagePicker();
  final _bairros = BairroService();
  bool _buscandoLocalizacao = false;
  bool _salvando = false;
  // Gravando a edição na API
  bool _gravando = false;
  // O ponto do pino no mapa e a rua e o bairro que correspondem a ele. O
  // pino é marcado pela mira, pelo arrasto do mapa ou pela busca; o ponto só
  // vai para o animal se a rua e o bairro continuarem os mesmos: mudados à
  // mão depois, ele já não corresponde ao que está escrito
  final _mapa = MapController();
  LatLng _ponto = centroDeFormiga;
  ({String rua, String bairro})? _enderecoDoPino;
  bool _buscandoNoMapa = false;
  String? _avisoDaBusca;
  final List<XFile> _fotos = [];
  bool _castrado = false;
  bool _vacinado = false;
  bool _vermifugado = false;
  String? _especie;
  String? _porte;
  String? _sexo;

  final _nome = TextEditingController();
  // A raça sai da lista da espécie; "Outra" abre o campo para escrever,
  // como no bairro
  String? _racaEscolhida;
  final _buscaDaRaca = TextEditingController();
  final _outraRaca = TextEditingController();
  final _idade = TextEditingController();
  final _observacoes = TextEditingController();
  final _necessidades = TextEditingController();
  final _rua = TextEditingController();
  // O bairro sai da lista de Formiga; "Outro" abre o campo para escrever
  String? _bairroEscolhido;
  final _buscaDoBairro = TextEditingController();
  final _outroBairro = TextEditingController();
  final _responsavel = TextEditingController();
  final _telefone = TextEditingController();

  // O formulário como abriu, para saber se algo mudou e perguntar antes de
  // sair sem salvar
  String? _inicial;
  String get _assinatura => [
    _tipo,
    _especie,
    _porte,
    _sexo,
    _racaEscolhida,
    _bairroEscolhido,
    _castrado,
    _vacinado,
    _vermifugado,
    _comoOng,
    // O pino do mapa conta: mexer nele sem querer também é uma mudança
    _ponto.latitude.toStringAsFixed(5),
    _ponto.longitude.toStringAsFixed(5),
    ..._fotos.map((foto) => foto.path),
    for (final campo in [
      _nome,
      _outraRaca,
      _idade,
      _observacoes,
      _necessidades,
      _rua,
      _outroBairro,
      _responsavel,
      _telefone,
    ])
      campo.text.trim(),
  ].join('|');

  bool get _alterado =>
      _inicial != null && _assinatura != _inicial && !_salvando && !_gravando;

  @override
  void initState() {
    super.initState();
    // O ponto de partida é o formulário já preenchido pelo initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicial = _assinatura;
    });
    final base = widget.base;
    if (base != null) _preencherCom(base);
    final editando = widget.editando;
    if (editando != null) {
      _preencherTudo(editando);
      return;
    }
    // Quem cadastra costuma ser o responsável, então o contato já vem
    // preenchido com o de quem está logado. Continua editável, porque numa
    // ONG quem cadastra nem sempre é quem atende. Sem provider na árvore,
    // como nos testes da tela sozinha, os campos só começam vazios
    final usuario = context.read<UsuarioProvider?>()?.usuario;
    if (usuario == null) return;
    // Quem faz parte de uma ONG começa publicando em nome dela, e pode trocar
    _comoOng = _minhaOng != null;
    _preencherContato();
  }

  // A ONG de quem está logado, se houver
  Ong? get _minhaOng {
    final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
    return PataAmigaScope.talvez(context)?.ongDe(email);
  }

  // Se o animal sai em nome da ONG ou da própria pessoa
  bool _comoOng = false;

  // O contato acompanha a escolha: o da ONG ou o de quem está logado
  void _preencherContato() {
    final ong = _minhaOng;
    if (_comoOng && ong != null) {
      _responsavel.text = ong.nome;
      _telefone.text = formatarTelefone(ong.telefone);
      return;
    }
    final usuario = context.read<UsuarioProvider?>()?.usuario;
    _responsavel.text = usuario?.nome.trim() ?? '';
    _telefone.text = usuario?.telefone.trim() ?? '';
  }

  // A opção da lista com o mesmo nome, sem ligar para maiúsculas: a API
  // guarda "cachorro" e a lista mostra "Cachorro"
  String? _opcao(List<String> opcoes, String valor) {
    for (final opcao in opcoes) {
      if (opcao.toLowerCase() == valor.trim().toLowerCase()) return opcao;
    }
    return null;
  }

  // O que vale para a adoção vem do resgate; observações e endereço ficam em
  // branco, porque o animal agora está com quem o acolheu
  void _preencherCom(Animal base) {
    _tipo = TipoRegistro.adocao;
    if (base.nome != _nomePadrao) _nome.text = base.nome;
    _especie = _opcao(_especies, base.especie);
    _porte = _opcao(_portes, base.porte);
    _sexo = _opcao(_sexos, base.sexo);
    _escolherRaca(base.raca);
    _idade.text = base.idade;
    _castrado = base.castrado;
    _vacinado = base.vacinado;
    _vermifugado = base.vermifugado;
    _necessidades.text = base.necessidadesEspeciais;
    // As fotos que o animal já tem entram na mesma lista das escolhidas
    // agora: dá para tirar, reordenar e trocar a capa do mesmo jeito
    _fotos.addAll(base.fotos.take(_maximoDeFotos).map(XFile.new));
  }

  // Na edição vem tudo, inclusive o tipo, o local, o contato e as
  // observações, e o ponto do mapa continua valendo enquanto a rua e o
  // bairro não mudarem
  void _preencherTudo(Animal registro) {
    _preencherCom(registro);
    _tipo = registro.tipo;
    _observacoes.text = registro.observacoes;
    _rua.text = registro.rua;
    _escolherBairroDoGps(registro.bairro);
    if (registro.temPonto) {
      _ponto = LatLng(registro.latitude!, registro.longitude!);
      _enderecoDoPino = (rua: registro.rua, bairro: registro.bairro);
    }
    _comoOng = registro.ongId != null;
    _responsavel.text = registro.dono.nome;
    // A API guarda só os dígitos; no campo, o telefone sempre com a máscara
    _telefone.text = formatarTelefone(registro.dono.telefone);
  }

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
      // O serviço de endereços depende da internet; sem prazo, a mira fica
      // girando para sempre quando a conexão está ruim
      final lugares = await Geocoding()
          .placemarkFromCoordinates(posicao.latitude, posicao.longitude)
          .timeout(const Duration(seconds: 10));
      if (lugares.isEmpty) {
        _avisar('Não achei o endereço deste ponto. Insira o endereço manualmente.');
        return;
      }

      if (!mounted) return;
      final endereco = await _comBairro(lugares.first);
      if (!mounted) return;
      setState(() {
        _rua.text = endereco.rua;
        _escolherBairroDoGps(endereco.bairro);
        _ponto = LatLng(posicao.latitude, posicao.longitude);
        _enderecoDoPino = endereco;
      });
      _mapa.move(_ponto, 17);
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

  // A rua leva o número quando o GPS o encontra; a cidade não entra, porque
  // o app é de Formiga
  ({String rua, String bairro}) _enderecoDe(Placemark lugar) {
    final rua = lugar.thoroughfare?.trim() ?? '';
    final numero = lugar.subThoroughfare?.trim() ?? '';
    return (
      rua: numero.isEmpty || rua.isEmpty ? rua : '$rua, $numero',
      bairro: bairroDoServico(lugar.subLocality, lugar.locality),
    );
  }

  // O GPS escreve o bairro do jeito dele: se bater com a lista, ele já vem
  // escolhido; se não bater, vai para "Outro" com o nome que o GPS deu
  void _escolherBairroDoGps(String bairro) {
    if (bairro.isEmpty) return;
    final daLista = bairroDaLista(bairro);
    if (daLista != null) {
      _bairroEscolhido = daLista;
      _buscaDoBairro.text = daLista;
    } else {
      _bairroEscolhido = outroBairro;
      _buscaDoBairro.text = outroBairro;
      _outroBairro.text = bairro;
    }
  }

  // A raça já cadastrada: se bater com a lista da espécie, vem escolhida; se
  // não bater, vai para "Outra" com o nome que estava escrito
  void _escolherRaca(String raca) {
    if (raca.trim().isEmpty) return;
    final daLista = racaDaLista(_especie, raca);
    if (daLista != null) {
      _racaEscolhida = daLista;
      _buscaDaRaca.text = daLista;
    } else {
      _racaEscolhida = outraRaca;
      _buscaDaRaca.text = outraRaca;
      _outraRaca.text = raca.trim();
    }
  }

  // Trocar a espécie apaga a raça que não existe na outra lista
  void _escolherEspecie(String? especie) {
    setState(() {
      _especie = especie;
      final raca = _racaEscolhida;
      if (raca != null &&
          raca != outraRaca &&
          !racasDa(especie).contains(raca)) {
        _racaEscolhida = null;
        _buscaDaRaca.clear();
      }
    });
  }

  String get _raca => _racaEscolhida == outraRaca
      ? _outraRaca.text.trim()
      : _racaEscolhida ?? '';

  String get _bairro => _bairroEscolhido == outroBairro
      ? _outroBairro.text.trim()
      : _bairroEscolhido ?? '';

  // O Android raramente sabe o bairro em Formiga; quando não vem, o ViaCEP
  // completa pelo CEP do ponto ou pelo nome da rua
  Future<({String rua, String bairro})> _comBairro(Placemark lugar) async {
    final endereco = _enderecoDe(lugar);
    if (endereco.bairro.isNotEmpty) return endereco;
    final bairro =
        await _bairros.pelaCep(lugar.postalCode) ??
        await _bairros.pelaRua(endereco.rua) ??
        '';
    return (rua: endereco.rua, bairro: bairro);
  }

  // Arrastou o mapa: o endereço do novo ponto preenche a rua e o bairro
  Future<void> _aoArrastarOMapa(LatLng centro) async {
    _ponto = centro;
    try {
      final lugares = await Geocoding()
          .placemarkFromCoordinates(centro.latitude, centro.longitude)
          .timeout(const Duration(seconds: 8));
      if (!mounted || centro != _ponto) return;
      if (lugares.isEmpty) {
        setState(() => _enderecoDoPino = (rua: '', bairro: ''));
        return;
      }
      final endereco = await _comBairro(lugares.first);
      if (!mounted || centro != _ponto) return;
      setState(() {
        _rua.text = endereco.rua;
        _escolherBairroDoGps(endereco.bairro);
        _enderecoDoPino = endereco;
        _avisoDaBusca = null;
      });
    } on Exception {
      // Sem o endereço, o pino continua onde a pessoa deixou
    }
  }

  // Escreveu a rua: a lupa leva o mapa até ela, e a pessoa confere o pino
  Future<void> _buscarNoMapa() async {
    final rua = _rua.text.trim();
    if (rua.isEmpty || _buscandoNoMapa) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _buscandoNoMapa = true;
      _avisoDaBusca = null;
    });
    final bairro = _bairro;
    String? aviso;
    try {
      final achados = await Geocoding()
          .locationFromAddress(
            [rua, bairro, 'Formiga, MG, Brasil']
                .where((parte) => parte.isNotEmpty)
                .join(', '),
          )
          .timeout(const Duration(seconds: 8));
      if (achados.isEmpty) {
        aviso = 'Não encontrei essa rua em Formiga. Confira o nome ou '
            'destrave o mapa e arraste.';
      } else if (mounted) {
        _ponto = LatLng(achados.first.latitude, achados.first.longitude);
        _enderecoDoPino = (rua: rua, bairro: bairro);
        _mapa.move(_ponto, 17);
      }
    } on Exception {
      aviso = 'Não foi possível buscar a rua agora. Arraste o mapa.';
    }
    if (!mounted) return;
    setState(() {
      _buscandoNoMapa = false;
      _avisoDaBusca = aviso;
    });
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

  // Os mesmos campos que ficam vermelhos quando faltam
  // O telefone vira o WhatsApp do animal: precisa do DDD
  bool get _telefoneValido =>
      _telefone.text.replaceAll(RegExp(r'\D'), '').length >= 10;

  final _rolagem = ScrollController();

  bool get _completo =>
      // Sem foto, ninguém reconhece nem se encanta pelo animal no feed
      _fotos.isNotEmpty &&
      _tipo != null &&
      _especie != null &&
      _porte != null &&
      [
        _idade,
        _observacoes,
        _rua,
        _responsavel,
        _telefone,
      ].every((campo) => campo.text.trim().isNotEmpty) &&
      _telefoneValido &&
      _bairro.isNotEmpty &&
      (_racaEscolhida != outraRaca || _raca.isNotEmpty);

  // Devolve o animal ao feed, que é quem o põe na lista
  // Sem a mira, o endereço digitado vira um ponto da rua, para o animal
  // também aparecer no mapa. Se o serviço não achar ou demorar, o cadastro
  // segue sem ponto: o mapa é um extra, não pode travar o cadastro
  Future<({double latitude, double longitude})?> _pontoDaRua(
    String rua,
    String bairro,
  ) async {
    try {
      final servico = Geocoding();
      final achados = await servico
          .locationFromAddress('$rua, $bairro, Formiga, MG, Brasil')
          .timeout(const Duration(seconds: 8));
      if (achados.isEmpty) return null;
      final ponto = achados.first;

      // Com a rua escrita errado, o serviço pode devolver o centro do bairro
      // ou da cidade sem avisar. Por isso o ponto só vale se ficar no bairro
      // escolhido, em Formiga; na dúvida, é melhor ficar fora do mapa do que
      // aparecer num lugar errado
      final lugares = await servico
          .placemarkFromCoordinates(ponto.latitude, ponto.longitude)
          .timeout(const Duration(seconds: 8));
      if (lugares.isEmpty) return null;
      final lugar = lugares.first;
      final emFormiga = mesmoBairro(lugar.locality ?? '', 'Formiga');
      final noBairro = mesmoBairro(lugar.subLocality ?? '', bairro);
      if (!emFormiga || !noBairro) return null;

      return (latitude: ponto.latitude, longitude: ponto.longitude);
    } on Exception {
      return null;
    }
  }

  Future<void> _cadastrar() async {
    if (_salvando || _gravando) return;
    setState(() => _tentouCadastrar = true);
    if (!_completo) {
      // O botão fica no fim e os campos em vermelho mais acima: a tela sobe
      // e avisa, para ninguém achar que o botão não funcionou
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Preencha os campos obrigatórios marcados em vermelho.',
            ),
          ),
        );
      _rolagem.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    final nome = _nome.text.trim();
    final rua = _rua.text.trim();
    final bairro = _bairro;
    // Se o GPS não achou o bairro, a pessoa o escolhe sem invalidar o ponto
    final lido = _enderecoDoPino;
    final mesmoLugar =
        lido != null &&
        (lido.rua.isEmpty || rua == lido.rua) &&
        (lido.bairro.isEmpty || mesmoBairro(bairro, lido.bairro));
    var coordenada = mesmoLugar
        ? (latitude: _ponto.latitude, longitude: _ponto.longitude)
        : null;
    if (coordenada == null) {
      setState(() => _salvando = true);
      coordenada = await _pontoDaRua(rua, bairro);
      if (!mounted) return;
      setState(() => _salvando = false);
    }
    final animal = Animal(
      nome: nome.isEmpty ? _nomePadrao : nome,
      especie: _especie!,
      raca: _raca,
      sexo: _sexo ?? 'não informado',
      porte: _porte!,
      idade: _idade.text.trim(),
      peso: '',
      cor: '',
      rua: rua,
      bairro: bairro,
      cidade: 'Formiga',
      tipo: _tipo!,
      castrado: _castrado,
      vacinado: _vacinado,
      vermifugado: _vermifugado,
      observacoes: _observacoes.text.trim(),
      necessidadesEspeciais: _necessidades.text.trim(),
      dono: Dono(
        nome: _responsavel.text.trim(),
        telefone: _telefone.text.trim(),
      ),
      responsavelEmail: context.read<UsuarioProvider?>()?.usuario.email ?? '',
      // Na edição, o animal da ONG continua da ONG
      ongId: widget.editando?.ongId ?? (_comoOng ? _minhaOng?.id : null),
      fotos: _fotos.map((foto) => foto.path).toList(),
      publicadoEm: DateTime.now(),
      latitude: coordenada?.latitude,
      longitude: coordenada?.longitude,
    );

    final editando = widget.editando;
    if (editando == null) {
      Navigator.pop(context, animal);
      return;
    }
    await _salvarEdicao(editando, animal);
  }

  // O registro editado mantém o que o formulário não mostra: o id, a
  // situação, a data da publicação e quem o cadastrou
  Future<void> _salvarEdicao(Animal original, Animal novo) async {
    final editado = Animal.fromJson({
      ...novo.toJson(),
      if (original.id != null) 'id': original.id,
      'status': original.status.name,
      'publicadoEm': original.publicadoEm.toIso8601String(),
      'responsavelEmail': original.responsavelEmail.isNotEmpty
          ? original.responsavelEmail
          : novo.responsavelEmail,
      'peso': original.peso,
      'cor': original.cor,
    });
    setState(() => _gravando = true);
    try {
      await (widget.api ?? AnimalService()).atualizarAnimal(editado);
    } on Exception {
      if (!mounted) return;
      setState(() => _gravando = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar as alterações. Tente de novo.',
            ),
          ),
        );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, editado);
  }

  @override
  void dispose() {
    _rolagem.dispose();
    _mapa.dispose();
    for (final campo in [
      _nome,
      _buscaDaRaca,
      _outraRaca,
      _idade,
      _observacoes,
      _necessidades,
      _rua,
      _buscaDoBairro,
      _outroBairro,
      _responsavel,
      _telefone,
    ]) {
      campo.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Com algo mudado e não salvo, voltar pergunta antes de sair
    return ProtegerAlteracoes(
      alterado: () => _alterado,
      child: Scaffold(
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
        title: Text(
          widget.editando != null
              ? 'EDITAR REGISTRO'
              : widget.base == null
              ? 'CADASTRAR ANIMAL'
              : 'PUBLICAR PARA ADOÇÃO',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Cores.principal,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _rolagem,
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
                semFoto: _tentouCadastrar && _fotos.isEmpty,
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
                  // Sem o tipo, o resto do formulário nem aparece
                  if (_tentouCadastrar && _tipo == null)
                    const _Recado(
                      'Escolha se é adoção, perdido ou resgate.',
                      erro: true,
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
                            aoEscolher: _escolherEspecie,
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
                    SelecaoComBusca(
                      // A lista muda com a espécie; a chave refaz o campo
                      key: ValueKey(_especie),
                      rotulo: 'Raça',
                      dica: _especie == null
                          ? 'Escolha a espécie primeiro'
                          : 'Digite para buscar a raça',
                      habilitada: _especie != null,
                      controlador: _buscaDaRaca,
                      opcoes: (digitado) => filtrarRacas(_especie, digitado),
                      daLista: (texto) => racaDaLista(_especie, texto),
                      rodape: const [
                        (valor: semRacaDefinida, texto: semRacaDefinida),
                        (valor: outraRaca, texto: 'Outra raça'),
                      ],
                      aoEscolher: (raca) =>
                          setState(() => _racaEscolhida = raca),
                    ),
                    if (_racaEscolhida == outraRaca) ...[
                      const SizedBox(height: 14),
                      _Campo(
                        rotulo: 'Qual é a raça?',
                        controlador: _outraRaca,
                        exemplo: 'Informe o nome da raça',
                        comErro: _faltando(_outraRaca),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _Campo(
                      rotulo: 'Idade',
                      controlador: _idade,
                      exemplo: '2 anos',
                      comErro: _faltando(_idade),
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
                    rotulo: 'Rua e número',
                    controlador: _rua,
                    exemplo: 'Informe a rua e o número',
                    comErro: _faltando(_rua),
                    aviso: _avisoDaBusca,
                    acao: IconButton(
                      onPressed: _buscandoNoMapa ? null : _buscarNoMapa,
                      icon: _buscandoNoMapa
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search, size: 20),
                      color: Cores.principal,
                      tooltip: 'Buscar no mapa',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SelecaoComBusca(
                    rotulo: 'Bairro',
                    dica: 'Digite para buscar o bairro',
                    controlador: _buscaDoBairro,
                    opcoes: filtrarBairros,
                    daLista: bairroDaLista,
                    rodape: const [
                      (valor: outroBairro, texto: 'Outro bairro'),
                    ],
                    comErro: _tentouCadastrar && _bairroEscolhido == null,
                    aoEscolher: (bairro) =>
                        setState(() => _bairroEscolhido = bairro),
                  ),
                  if (_bairroEscolhido == outroBairro) ...[
                    const SizedBox(height: 14),
                    _Campo(
                      rotulo: 'Qual é o bairro?',
                      controlador: _outroBairro,
                      exemplo: 'Informe o nome do bairro',
                      comErro: _faltando(_outroBairro),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const _Rotulo('Ponto no mapa'),
                  const SizedBox(height: 4),
                  const Text(
                    'Busque a rua pela lupa, toque na mira para usar sua '
                    'localização ou destrave o mapa e arraste até o pino.',
                    style: TextStyle(fontSize: 12, color: Cores.textoFraco),
                  ),
                  const SizedBox(height: 8),
                  MapaDeLocal(
                    controlador: _mapa,
                    inicio: _ponto,
                    altura: 220,
                    buscandoPosicao: _buscandoLocalizacao,
                    aoUsarMinhaLocalizacao: _usarMinhaLocalizacao,
                    aoArrastar: _aoArrastarOMapa,
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
                    // Quem faz parte de uma ONG escolhe em nome de quem
                    // publica: só os da ONG aparecem no perfil dela
                    if (_minhaOng case final ong?
                        when widget.editando?.ongId == null) ...[
                      const _Rotulo('Publicar como'),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<bool>(
                          segments: [
                            const ButtonSegment(
                              value: false,
                              label: Text('Eu'),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(
                                ong.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          selected: {_comoOng},
                          showSelectedIcon: false,
                          onSelectionChanged: (escolha) => setState(() {
                            _comoOng = escolha.first;
                            _preencherContato();
                          }),
                          style: estiloDasAbas(Cores.fundo),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
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
                      comErro: _tentouCadastrar && !_telefoneValido,
                      erro: _faltando(_telefone)
                          ? null
                          : 'Digite um telefone com DDD.',
                      teclado: TextInputType.phone,
                      formatadores: [MascaraDeTelefone()],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _salvando || _gravando ? null : _cadastrar,
              icon: _salvando || _gravando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      widget.editando != null ? Icons.check : Icons.pets,
                      size: 18,
                    ),
              label: Text(
                _salvando
                    ? 'Localizando a rua…'
                    : _gravando
                    ? 'Salvando…'
                    : widget.editando != null
                    ? 'Salvar alterações'
                    : 'Cadastrar',
              ),
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
      bottomNavigationBar: BarraInferior(),
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
    this.semFoto = false,
  });

  // Tentou cadastrar sem nenhuma foto
  final bool semFoto;

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
        if (semFoto)
          const _Recado('Adicione pelo menos uma foto.', erro: true),
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

  // A foto que o animal já tinha pode vir da internet ou do app, e não do
  // celular: essa a FotoAnimal já sabe mostrar
  bool get _jaPublicada =>
      kIsWeb ? false : !widget.arquivo.path.startsWith('/');

  @override
  void initState() {
    super.initState();
    if (!_jaPublicada) _bytes = widget.arquivo.readAsBytes();
  }

  @override
  void didUpdateWidget(_FotoDaGaleria anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.arquivo.path != widget.arquivo.path && !_jaPublicada) {
      _bytes = widget.arquivo.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_jaPublicada) {
      return FotoAnimal(caminho: widget.arquivo.path, altura: widget.altura);
    }
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
  // O texto do erro, quando não é só o campo vazio
  final String? erro;

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
    this.erro,
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
        if (comErro) _Recado(erro ?? 'Campo obrigatório', erro: true),
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
