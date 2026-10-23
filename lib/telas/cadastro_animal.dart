// Biblioteca dart:async: prazo das consultas de endereço (TimeoutException).
import 'dart:async';

// Pacote flutter/foundation: kIsWeb e Uint8List, para a prévia da foto.
import 'package:flutter/foundation.dart';
// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter/services: TextInputFormatter e PlatformException.
import 'package:flutter/services.dart';
// Pacote geocoding: converte coordenadas em endereço e endereço em coordenadas.
import 'package:geocoding/geocoding.dart';
// Pacote flutter_map: mapa interativo com os blocos do OpenStreetMap.
import 'package:flutter_map/flutter_map.dart';
// Pacote image_picker: abre a câmera ou a galeria para escolher fotos.
import 'package:image_picker/image_picker.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo bairros_formiga.dart: bairros de Formiga e comparação de nomes.
import '../dados/bairros_formiga.dart';
// Arquivo racas.dart: listas de raças por espécie.
import '../dados/racas.dart';
// Arquivo estado_pata_amiga.dart: estado compartilhado do app.
import '../estado/estado_pata_amiga.dart';
// Arquivo animal.dart: modelo do animal e o tipo do registro.
import '../modelos/animal.dart';
// Arquivo dono.dart: contato do responsável pelo animal.
import '../modelos/dono.dart';
// Arquivo ong.dart: modelo da ONG.
import '../modelos/ong.dart';
// Arquivo usuario_provider.dart: dados do usuário logado.
import '../provider/usuario_provider.dart';
// Arquivo animal_service.dart: gravação do animal na API.
import '../services/animal_service.dart';
// Arquivo bairro_service.dart: consulta do bairro pelo ViaCEP.
import '../services/bairro_service.dart';
// Arquivo localizacao_service.dart: leitura da posição atual do aparelho.
import '../services/localizacao_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo proteger_alteracoes.dart: confirma a saída sem salvar.
import '../widgets/proteger_alteracoes.dart';
// Arquivo barra_inferior.dart: barra de navegação inferior.
import '../widgets/barra_inferior.dart';
// Arquivo cuidado.dart: selo de cuidado (castrado, vacinado, vermifugado).
import '../widgets/cuidado.dart';
// Arquivo escolha_de_tipo.dart: seletor do tipo de registro e estilo das abas.
import '../widgets/escolha_de_tipo.dart';
// Arquivo foto_animal.dart: exibição da foto do animal.
import '../widgets/foto_animal.dart';
// Arquivo mapa_de_local.dart: mapa com pino central e o centro de Formiga.
import '../widgets/mapa_de_local.dart';
// Arquivo mascaras.dart: máscara e formatação de telefone.
import '../widgets/mascaras.dart';
// Arquivo selecao_com_busca.dart: campo de seleção com busca (raça e bairro).
import '../widgets/selecao_com_busca.dart';

// Primeira letra em maiúscula, para exibir as opções das listas
String _comMaiuscula(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

// Texto de exemplo do campo Observações, adequado a cada tipo de registro
String _exemploDeObservacoes(TipoRegistro tipo) => switch (tipo) {
  TipoRegistro.adocao => 'Temperamento, convívio com crianças e outros animais',
  TipoRegistro.perdido => 'Onde e quando sumiu, coleira, se atende pelo nome',
  TipoRegistro.resgate => 'Onde está, em que estado, se corre risco',
};

// Título do cartão de endereço; sem tipo escolhido, usa o texto da adoção
String _tituloDoLugar(TipoRegistro? tipo) =>
    (tipo ?? TipoRegistro.adocao).tituloDoLugar;

const _nomePadrao = 'Sem nome';
const _maximoDeFotos = 5;
// Números por extenso usados no aviso de fotos que excederam o limite
const _porExtenso = {2: 'duas', 3: 'três', 4: 'quatro', 5: 'cinco'};
// Medidas da tira de miniaturas. O botão de remover tem 20 px desenhados,
// mas área de toque de 44 px, e sobressai do canto da miniatura; a folga
// reserva espaço acima da tira para essa área não ser cortada
const _ladoDaMiniatura = 84.0;
const _alvoDeToque = 44.0;
const _desenhoDoBadge = 20.0;
const _quantoSobrevoa = 6.0;
const _folgaDaTira = _quantoSobrevoa + (_alvoDeToque - _desenhoDoBadge) / 2;

const _especies = ['Cachorro', 'Gato'];
const _portes = ['pequeno', 'médio', 'grande'];
const _sexos = ['macho', 'fêmea'];

// Formulário de registro de animal (adoção, perdido ou resgate). Também
// serve para publicar para adoção um animal resgatado e para editar um
// registro já publicado
class CadastroAnimal extends StatefulWidget {
  // Animal resgatado que será publicado para adoção: o formulário abre com
  // os dados dele e o tipo Adoção marcado
  final Animal? base;
  // Registro já publicado em edição: o formulário abre com todos os dados
  // e grava as alterações na API antes de fechar
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
  final _localizacao = const LocalizacaoService(
    alternativa: 'Insira o endereço manualmente.',
  );
  bool _buscandoLocalizacao = false;
  bool _salvando = false;
  // Indica que a edição está sendo gravada na API
  bool _gravando = false;
  // Ponto do pino no mapa e o endereço que corresponde a ele. O pino é
  // marcado pela mira, pelo arrasto do mapa ou pela busca. A coordenada só
  // é salva se a rua e o bairro digitados continuarem iguais a esse endereço
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
  // Raça escolhida na lista da espécie; "Outra" abre um campo de texto livre
  String? _racaEscolhida;
  final _buscaDaRaca = TextEditingController();
  final _outraRaca = TextEditingController();
  final _idade = TextEditingController();
  final _observacoes = TextEditingController();
  final _necessidades = TextEditingController();
  final _rua = TextEditingController();
  // Bairro escolhido na lista de Formiga; "Outro" abre um campo de texto livre
  String? _bairroEscolhido;
  final _buscaDoBairro = TextEditingController();
  final _outroBairro = TextEditingController();
  final _responsavel = TextEditingController();
  final _telefone = TextEditingController();

  // Retrato do formulário ao abrir. Comparado com o estado atual, indica se
  // há alterações não salvas para confirmar antes de sair
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
    // A posição do pino também conta como alteração
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
    // Tira o retrato depois do primeiro quadro, com os campos já preenchidos
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
    // Num cadastro novo, o contato começa com os dados de quem está logado
    // e continua editável. Sem UsuarioProvider na árvore (testes da tela
    // isolada), os campos começam vazios
    final usuario = context.read<UsuarioProvider?>()?.usuario;
    if (usuario == null) return;
    // Membro de ONG começa publicando em nome dela; a escolha pode mudar
    _comoOng = _minhaOng != null;
    _preencherContato();
  }

  // ONG do usuário logado, se ele fizer parte de uma. Lê sem registrar
  // dependência, para uso no initState e nas ações
  Ong? get _minhaOng {
    final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
    return PataAmigaScope.talvez(context)?.ongDe(email);
  }

  // Mesma consulta, para o build: registra dependência no estado do app, de
  // modo que a opção "Publicar como" aparece quando as ONGs terminam de
  // carregar depois de a tela abrir
  Ong? _minhaOngNoBuild(BuildContext context) {
    final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
    return context
        .dependOnInheritedWidgetOfExactType<PataAmigaScope>()
        ?.notifier
        ?.ongDe(email);
  }

  // Indica se o animal é publicado em nome da ONG ou do próprio usuário
  bool _comoOng = false;

  // Preenche o contato com os dados da ONG ou do usuário, conforme a escolha
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

  // Acha a opção da lista equivalente ao valor, ignorando maiúsculas (a API
  // guarda "cachorro" e a lista exibe "Cachorro")
  String? _opcao(List<String> opcoes, String valor) {
    for (final opcao in opcoes) {
      if (opcao.toLowerCase() == valor.trim().toLowerCase()) return opcao;
    }
    return null;
  }

  // Copia os dados do animal de base. Observações e endereço ficam em branco,
  // pois na adoção o animal já está com quem o acolheu
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
    // As fotos existentes entram na mesma lista das novas, podendo ser
    // removidas e reordenadas da mesma forma
    _fotos.addAll(base.fotos.take(_maximoDeFotos).map(XFile.new));
  }

  // Preenche todos os campos para edição, inclusive tipo, endereço, ponto
  // no mapa, contato e observações
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
    // Exibe o telefone com a máscara, mesmo que tenha sido salvo só com dígitos
    _telefone.text = formatarTelefone(registro.dono.telefone);
  }

  bool _faltando(TextEditingController campo) =>
      _tentouCadastrar && campo.text.trim().isEmpty;

  bool _naoEscolhido(String? valor) => _tentouCadastrar && valor == null;

  // Usa o GPS para posicionar o pino e preencher a rua e o bairro
  Future<void> _usarMinhaLocalizacao() async {
    if (_buscandoLocalizacao) return;
    setState(() => _buscandoLocalizacao = true);

    try {
      final posicao = await _localizacao.posicaoAtual();
      // Prazo para a consulta do endereço, que depende da internet e pode
      // não responder com conexão ruim
      final lugares = await Geocoding()
          .placemarkFromCoordinates(posicao.latitude, posicao.longitude)
          .timeout(const Duration(seconds: 10));
      if (lugares.isEmpty) {
        _avisar(
          'Não achei o endereço deste ponto. Insira o endereço manualmente.',
        );
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
    } on ErroDeLocalizacao catch (erro) {
      _avisar(erro.texto);
    } on TimeoutException {
      _avisar(
        'A busca do endereço demorou demais. Insira o endereço '
        'manualmente.',
      );
    } on Exception {
      _avisar(
        'Não foi possível encontrar o endereço. Insira o endereço manualmente.',
      );
    } finally {
      if (mounted) setState(() => _buscandoLocalizacao = false);
    }
  }

  // Monta rua (com número, quando disponível) e bairro a partir do resultado
  // da geocodificação; a cidade é sempre Formiga
  ({String rua, String bairro}) _enderecoDe(Placemark lugar) {
    final rua = lugar.thoroughfare?.trim() ?? '';
    final numero = lugar.subThoroughfare?.trim() ?? '';
    return (
      rua: numero.isEmpty || rua.isEmpty ? rua : '$rua, $numero',
      bairro: bairroDoServico(lugar.subLocality, lugar.locality),
    );
  }

  // Seleciona o bairro na lista quando o nome corresponde; se não, escolhe
  // "Outro" e preenche o campo livre com o nome recebido
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

  // Seleciona a raça na lista da espécie quando corresponde; se não,
  // escolhe "Outra" e preenche o campo livre
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

  // Troca a espécie e limpa a raça se ela não existir na nova lista
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

  // Completa o bairro pelo ViaCEP (CEP ou nome da rua) quando a
  // geocodificação do aparelho não o informa
  Future<({String rua, String bairro})> _comBairro(Placemark lugar) async {
    final endereco = _enderecoDe(lugar);
    if (endereco.bairro.isNotEmpty) return endereco;
    final bairro =
        await _bairros.pelaCep(lugar.postalCode) ??
        await _bairros.pelaRua(endereco.rua) ??
        '';
    return (rua: endereco.rua, bairro: bairro);
  }

  // Ao arrastar o mapa, preenche rua e bairro com o endereço do novo ponto.
  // Respostas de pontos antigos são descartadas
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
      // Sem endereço, o pino permanece onde foi deixado
    }
  }

  // Busca a rua digitada e move o mapa até ela para o usuário conferir o pino
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
            [
              rua,
              bairro,
              'Formiga, MG, Brasil',
            ].where((parte) => parte.isNotEmpty).join(', '),
          )
          .timeout(const Duration(seconds: 8));
      if (achados.isEmpty) {
        aviso =
            'Não encontrei essa rua em Formiga. Confira o nome ou '
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

  // Mostra uma mensagem curta no rodapé, se a tela ainda existir
  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // Abre a galeria e adiciona fotos até o limite
  Future<void> _adicionarFotos() async {
    final vagas = _maximoDeFotos - _fotos.length;
    if (vagas <= 0) return;

    try {
      final escolhidas = await _seletorDeFotos.pickMultiImage(
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (!mounted || escolhidas.isEmpty) return;

      // A galeria do sistema não aplica o limite; guarda só as que cabem
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

  // Avisa quantas fotos foram descartadas por exceder o limite
  void _avisarQueSobrou(int escolhidas, int vagas) {
    final quantas = vagas == 1
        ? 'a primeira'
        : 'as ${_porExtenso[vagas] ?? vagas} primeiras';
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

  // O telefone é usado no contato por WhatsApp, por isso exige DDD
  bool get _telefoneValido =>
      _telefone.text.replaceAll(RegExp(r'\D'), '').length >= 10;

  final _rolagem = ScrollController();

  // Chaves dos cartões do formulário, para rolar até o que tem erro
  final _cartaoDasFotos = GlobalKey();
  final _cartaoDoAnimal = GlobalKey();
  final _cartaoDoLugar = GlobalKey();
  final _cartaoDoContato = GlobalKey();

  // Rola até o primeiro cartão com campo obrigatório faltando, na ordem em
  // que aparecem na tela
  void _rolarAtePrimeiroErro() {
    final vazio = [
      _idade,
      _observacoes,
    ].any((campo) => campo.text.trim().isEmpty);
    final GlobalKey alvo;
    if (_fotos.isEmpty) {
      alvo = _cartaoDasFotos;
    } else if (_tipo == null ||
        _especie == null ||
        _porte == null ||
        vazio ||
        (_racaEscolhida == outraRaca && _raca.isEmpty)) {
      alvo = _cartaoDoAnimal;
    } else if (_rua.text.trim().isEmpty || _bairro.isEmpty) {
      alvo = _cartaoDoLugar;
    } else {
      alvo = _cartaoDoContato;
    }
    final contexto = alvo.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Indica se todos os campos obrigatórios estão preenchidos (os mesmos que
  // ficam marcados em vermelho quando faltam)
  bool get _completo =>
      // A foto é obrigatória para o animal ser reconhecido no feed
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

  // Converte o endereço digitado em coordenada para o animal aparecer no
  // mapa. Em caso de falha ou demora devolve null e o cadastro segue sem
  // ponto, pois o mapa não deve impedir o cadastro
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
      // ou da cidade. O ponto só é aceito se ficar no bairro escolhido, em
      // Formiga, para evitar marcar o animal num lugar errado
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

  // Valida o formulário e monta o animal. No cadastro novo, devolve o
  // animal à tela anterior, que o envia à API; na edição, grava aqui mesmo
  Future<void> _cadastrar() async {
    if (_salvando || _gravando) return;
    setState(() => _tentouCadastrar = true);
    if (!_completo) {
      _rolarAtePrimeiroErro();
      return;
    }

    final nome = _nome.text.trim();
    final rua = _rua.text.trim();
    final bairro = _bairro;
    // O ponto do pino vale se o endereço não mudou; campos vazios no
    // endereço lido (GPS sem bairro, por exemplo) não invalidam o ponto
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
        // Grava só os dígitos, no mesmo formato da ONG; a tela exibe com a
        // máscara
        telefone: _telefone.text.replaceAll(RegExp(r'\D'), ''),
      ),
      responsavelEmail: context.read<UsuarioProvider?>()?.usuario.email ?? '',
      // Na edição, mantém o vínculo com a ONG que o registro já tinha
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

  // Grava a edição na API mantendo os campos que o formulário não exibe:
  // id, situação, data da publicação, responsável, peso e cor
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
    // Pede confirmação ao sair com alterações não salvas
    return ProtegerAlteracoes(
      alterado: () => _alterado,
      child: Scaffold(
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
            widget.editando != null
                ? 'EDITAR REGISTRO'
                : widget.base == null
                ? 'CADASTRAR ANIMAL'
                : 'PUBLICAR PARA ADOÇÃO',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: context.cores.principal,
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
                key: _cartaoDasFotos,
                child: _BlocoDeFotos(
                  fotos: _fotos,
                  aoAdicionar: _adicionarFotos,
                  aoReordenar: _reordenarFotos,
                  aoRemover: _removerFoto,
                  semFoto: _tentouCadastrar && _fotos.isEmpty,
                ),
              ),
              _Cartao(
                key: _cartaoDoAnimal,
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
                      fundoDaOpcao: context.cores.fundo,
                    ),
                    // Os demais campos só aparecem depois de escolhido o tipo
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
                        // A chave recria o campo quando a espécie muda
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
                        aoEscolher: (escolha) =>
                            setState(() => _sexo = escolha),
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
                          exemplo:
                              'Remédio de uso contínuo, deficiência, dieta',
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
                key: _cartaoDoLugar,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search, size: 20),
                        color: context.cores.principal,
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
                    Text(
                      'Busque a rua pela lupa, toque na mira para usar sua '
                      'localização ou destrave o mapa e arraste até o pino.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.cores.textoFraco,
                      ),
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
                  key: _cartaoDoContato,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TituloDoCartao(
                        icone: Icons.person_outline,
                        texto: _tipo!.tituloDoContato,
                      ),
                      const SizedBox(height: 16),
                      // Membro de ONG escolhe se publica em nome próprio ou
                      // da ONG; só os da ONG aparecem no perfil dela
                      if (_minhaOngNoBuild(context) case final ong?
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
                            style: estiloDasAbas(context, context.cores.fundo),
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
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.sobrePrincipal,
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
        ),
        bottomNavigationBar: BarraInferior(),
      ),
    );
  }
}

// Seção de fotos: capa em destaque, tira de miniaturas reordenáveis e
// botão para adicionar
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

  // Exibe o erro de foto obrigatória
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
        Text(
          'Você pode escolher até $_maximoDeFotos fotos.',
          style: TextStyle(fontSize: 12, color: context.cores.textoFraco),
        ),
        if (semFoto) const _Recado('Adicione pelo menos uma foto.', erro: true),
        if (fotos.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'A primeira foto é a capa. Segure e arraste para ordenar.',
            style: TextStyle(fontSize: 12, color: context.cores.textoFraco),
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
                    padding: const EdgeInsets.only(
                      right: 10,
                      top: _folgaDaTira,
                    ),
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

// Quadrado com ícone de câmera para adicionar mais fotos
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
          color: context.cores.fundo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cores.borda),
        ),
        child: Icon(
          Icons.add_a_photo_outlined,
          size: 22,
          color: context.cores.principal,
        ),
      ),
    );
  }
}

// Miniatura de uma foto, com selo de capa e botão de remover
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

// Botão de remover foto: desenho pequeno com área de toque de 44 px
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
                color: context.cores.destaque,
                shape: BoxShape.circle,
                border: Border.all(color: context.cores.cartao, width: 1.5),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 12,
                color: context.cores.cartao,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Selo "Capa" exibido na primeira foto
class _SeloDeCapa extends StatelessWidget {
  const _SeloDeCapa();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cores.principal,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          'Capa',
          style: TextStyle(
            color: context.cores.cartao,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Exibe uma foto escolhida no aparelho ou uma foto já publicada
class _FotoDaGaleria extends StatefulWidget {
  final XFile arquivo;
  final double altura;

  const _FotoDaGaleria({required this.arquivo, required this.altura});

  @override
  State<_FotoDaGaleria> createState() => _FotoDaGaleriaState();
}

class _FotoDaGaleriaState extends State<_FotoDaGaleria> {
  late Future<Uint8List> _bytes;

  // Foto já publicada (URL ou asset do app), e não um arquivo do aparelho;
  // nesse caso a exibição fica com a FotoAnimal
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

// Cartão de seção do formulário
class _Cartao extends StatelessWidget {
  final Widget child;

  const _Cartao({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: child,
    );
  }
}

// Título de seção com ícone, na cor principal
class _TituloDoCartao extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _TituloDoCartao({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 16, color: context.cores.principal),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(
            color: context.cores.principal,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Decoração padrão dos campos, com borda de erro quando necessário
InputDecoration _caixa(
  BuildContext context,
  String? exemplo, {
  bool comErro = false,
  Widget? acao,
}) => InputDecoration(
  isDense: true,
  filled: true,
  fillColor: context.cores.fundo,
  hintText: exemplo,
  suffixIcon: acao,
  hintStyle: TextStyle(fontSize: 14, color: context.cores.textoFraco),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: comErro ? context.cores.destaque : context.cores.borda,
      width: comErro ? 1.5 : 1,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: comErro ? context.cores.destaque : context.cores.principal,
      width: 1.5,
    ),
  ),
);

// Campo de texto com rótulo, mensagem de erro e aviso opcional
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
  // Mensagem de erro específica; sem ela, usa "Campo obrigatório"
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
          decoration: _caixa(context, exemplo, comErro: comErro, acao: acao),
        ),
        if (comErro) _Recado(erro ?? 'Campo obrigatório', erro: true),
        if (aviso != null && !comErro) _Recado(aviso!),
      ],
    );
  }
}

// Texto pequeno abaixo de um campo: aviso ou erro
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
          color: erro ? context.cores.destaque : context.cores.textoFraco,
        ),
      ),
    );
  }
}

// Lista suspensa com rótulo e mensagem de campo obrigatório
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
          decoration: _caixa(context, null, comErro: comErro),
          hint: Text(
            'Escolher',
            style: TextStyle(fontSize: 14, color: context.cores.textoFraco),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: context.cores.textoFraco,
          ),
          style: TextStyle(fontSize: 15, color: context.cores.texto),
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

// Rótulo de campo em maiúsculas
class _Rotulo extends StatelessWidget {
  final String texto;

  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: context.cores.textoFraco,
      ),
    );
  }
}

// Opção de cuidado (castrado, vacinado, vermifugado) que alterna ao tocar
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
