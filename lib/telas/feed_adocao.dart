import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';




import '../modelos/animal.dart';
import '../modelos/dono.dart';
import '../routes/route_names.dart';
import '../tema/cores.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/card_animal.dart';
import '../widgets/escolha_de_tipo.dart';
import '../routes/app_router.dart';
// [SPRINT 3 - NOVO] Camada de dados: API e cache local
import '../services/animal_service.dart';
import '../services/cache_service.dart';


enum EstadoFeed { carregando, cache, atualizado, erro }

class FeedAdocao extends StatefulWidget {
  const FeedAdocao({super.key});

  @override
  State<FeedAdocao> createState() => _FeedAdocaoState();
}

class _FeedAdocaoState extends State<FeedAdocao> {
  // Aba aberta no momento, que decide quais animais o feed mostra
  TipoRegistro _abaAtual = TipoRegistro.adocao;

  final List<Animal> _animaisCriados = [];

  // O que foi digitado no campo de pesquisa
  final _pesquisa = TextEditingController();
  String _busca = '';

  // [SPRINT 3 - NOVO] Serviços de dados
  final _api = AnimalService();
  final _cache = CacheService();

  // [SPRINT 3 - NOVO] Animais que vieram da API ou do cache.
  // Substitui a lista fixa animaisMock.
  List<Animal> _animaisApi = [];

  // [SPRINT 3 - NOVO] Estado atual da tela e dados que o banner usa
  EstadoFeed _estado = EstadoFeed.carregando;
  DateTime? _dataCache; // quando os dados foram salvos / atualizados
  bool _atualizando = false; // true enquanto há uma busca na API em andamento

  // [SPRINT 3 - NOVO] Busca os animais ao abrir a tela
  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _pesquisa.dispose();
    super.dispose();
  }

  // [SPRINT 3 - NOVO] Fluxo principal da sprint:
  //   1. Se existe cache, mostra na hora (estado: cache)
  //      Se não existe, estado: carregando
  //   2. Tenta a API
  //        sucesso -> mostra, SOBRESCREVE o cache (estado: atualizado)
  //        falha   -> com cache, continua no estado cache
  //                   sem cache, estado erro
  // É chamado ao abrir a tela e pelo botão "Tentar atualizar".
  Future<void> _carregar() async {
    final salvos = await _cache.lerAnimais();
    final dataSalva = await _cache.dataDoCache();
    if (!mounted) return;

    setState(() {
      _atualizando = true;
      if (salvos != null) {
        _animaisApi = salvos;
        _dataCache = dataSalva;
        _estado = EstadoFeed.cache;
      } else {
        _estado = EstadoFeed.carregando;
      }
    });

    try {
      final novos = await _api.buscarAnimais();
      await _cache.salvarAnimais(novos); // o cache nunca fica congelado
      if (!mounted) return;
      setState(() {
        _animaisApi = novos;
        _dataCache = DateTime.now();
        _estado = EstadoFeed.atualizado;
        _atualizando = false;
      });
    } catch (_) {
      // Sem internet, servidor fora do ar ou timeout
      if (!mounted) return;
      setState(() {
        _atualizando = false;
        if (salvos == null) _estado = EstadoFeed.erro;
        // Se havia cache, o estado continua "cache"
      });
      if (salvos != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Não foi possível atualizar. Mostrando dados salvos.'),
            ),
          );
      }
    }
  }

  // [SPRINT 3 - NOVO] Formata a data do cache, ex.: "14/10 às 21:05"
  String _formatarData(DateTime? data) {
    if (data == null) return 'data desconhecida';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(data.day)}/${dois(data.month)} às '
        '${dois(data.hour)}:${dois(data.minute)}';
  }

  /*
   Future<void> _abrirCadastroAnimal() async {
    final animal = (await Navigator.pushNamed(
      context,
      AppRoutes.registerAnimal,
    )) as Animal?;
    if (!mounted || animal == null) return;

    setState(() => _animaisCriados.insert(0, animal));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${animal.nome} foi adicionado ao feed.')),
    );
  }
  */

    Future<void> _abrirCadastroAnimal() async {
    final animal = (await Navigator.pushNamed(
      context,
      AppRoutes.registerAnimal,
    )) as Animal?;
    if (!mounted || animal == null) return;

    
    try {
      await _api.criarAnimal(animal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${animal.nome} foi salvo na API.')),
      );
      // Busca a lista de novo: o animal volta com o id da API e o cache
      // local também é atualizado.
      await _carregar();
    } catch (_) {
     
      if (!mounted) return;
      setState(() => _animaisCriados.insert(0, animal));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${animal.nome} foi adicionado só neste aparelho. '
            'Não foi possível enviar à API.',
          ),
        ),
      );
    }
  }

  Future<void> _abrirDetalhes(Animal animal) async {
    final animalRetornado = (await Navigator.pushNamed(
      context,
      AppRoutes.details,
      arguments: animal,
    )) as Animal?;
    if (!mounted || animalRetornado == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Você voltou dos detalhes de ${animalRetornado.nome}.'),
      ),
    );
  }

  List<Animal> get _animaisVisiveis {
    final termo = _busca.trim().toLowerCase();
    // [SPRINT 3 - ALTERADO] antes: [...animaisMock, ..._animaisCriados]
    final encontrados = [..._animaisApi, ..._animaisCriados].where((animal) {
      if (animal.tipo != _abaAtual) return false;
      if (termo.isEmpty) return true;
      return animal.nome.toLowerCase().contains(termo) ||
          animal.raca.toLowerCase().contains(termo) ||
          animal.especie.toLowerCase().contains(termo);
    }).toList();
    // O feed é cronológico decrescente: o que foi publicado por último abre
    encontrados.sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));
    return encontrados;
  }

  // Junta os cuidados marcados numa frase só, concordando com o sexo
  String _saude(Animal animal) {
    final a = animal.sexo == 'fêmea' ? 'a' : 'o';
    final itens = [
      if (animal.castrado) 'castrad$a',
      if (animal.vacinado) 'vacinad$a',
      if (animal.vermifugado) 'vermifugad$a',
    ];
    if (itens.isEmpty) return '';
    final frase = itens.length == 1
        ? itens.first
        : '${itens.sublist(0, itens.length - 1).join(', ')} e ${itens.last}';
    return frase[0].toUpperCase() + frase.substring(1);
  }

  // Abre a conversa direto no WhatsApp do responsável
  Future<void> _chamarNoWhatsApp(Animal animal) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final texto = Uri.encodeComponent(
      'Olá! Vi ${animal.nome} no Pata Amiga e queria saber mais.',
    );
    final endereco = Uri.parse(
      'https://wa.me/${animal.dono.numeroNoWhatsApp}?text=$texto',
    );

    final abriu = await launchUrl(
      endereco,
      mode: LaunchMode.externalApplication,
    );
    if (!abriu) {
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o WhatsApp neste aparelho.'),
            duration: Duration(seconds: 3),
          ),
        );
    }
  }

  Future<void> _compartilhar(Animal animal) async {
    final situacao = switch (animal.tipo) {
      TipoRegistro.adocao => 'Disponível para adoção',
      TipoRegistro.perdido => 'Está perdido',
      TipoRegistro.resgate => 'Precisa de resgate',
    };

    final saude = _saude(animal);

    final texto = [
      animal.nome,
      '${animal.especie}, ${animal.raca}, ${animal.sexo}, '
          'porte ${animal.porte}, ${animal.idade}, ${animal.cor}',
      '${animal.bairro}, ${animal.cidade}',
      if (saude.isNotEmpty) saude,
      '',
      '$situacao.',
      if (animal.observacoes.isNotEmpty) animal.observacoes,
      '',
      'Contato: ${animal.dono.nome}, ${animal.dono.telefone}',
      '',
      'Divulgado pelo Pata Amiga',
    ].join('\n');

    // [SPRINT 3 - ALTERADO] Só anexa a foto se o animal tiver uma.
    // Antes, rootBundle.load('') dava erro com animal sem foto vindo da API.
    final arquivos = <XFile>[];
    if (animal.foto.isNotEmpty) {
      // O compartilhamento só aceita arquivo, e a foto é um asset, então converte
      final imagem = await rootBundle.load(animal.foto);
      arquivos.add(
        XFile.fromData(
          imagem.buffer.asUint8List(),
          mimeType: 'image/jpeg',
          name: '${animal.nome}.jpg',
        ),
      );
    }

    await SharePlus.instance.share(ShareParams(text: texto, files: arquivos));
  }

  // [SPRINT 3 - NOVO] Faixa colorida do banner de estado
  Widget _faixa({
    required Color cor,
    required IconData icone,
    required String texto,
    Widget? acao,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icone, size: 20, color: cor),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
          if (acao != null) acao,
        ],
      ),
    );
  }

  // [SPRINT 3 - NOVO] Banner que diz ao usuário de onde vêm os dados.
  // É isto que a Sprint Review precisa mostrar em modo avião.
  Widget _bannerDeEstado() {
    switch (_estado) {
      case EstadoFeed.cache:
        // Busca em andamento: ainda não é "sem conexão", só está atualizando
        if (_atualizando) {
          return _faixa(
            cor: Colors.blueGrey,
            icone: Icons.sync,
            texto: 'Atualizando... mostrando dados salvos enquanto isso.',
          );
        }
        // A busca falhou: mostra o aviso de dado possivelmente desatualizado
        return _faixa(
          cor: Colors.orange,
          icone: Icons.cloud_off,
          texto: 'Dados salvos em ${_formatarData(_dataCache)}. '
              'Podem estar desatualizados.',
          acao: TextButton(
            onPressed: _carregar,
            child: const Text('Tentar atualizar'),
          ),
        );
      case EstadoFeed.atualizado:
        return _faixa(
          cor: Colors.green,
          icone: Icons.cloud_done,
          texto: 'Atualizado em ${_formatarData(_dataCache)}.',
        );
      case EstadoFeed.carregando:
      case EstadoFeed.erro:
        return const SizedBox.shrink();
    }
  }

  // [SPRINT 3 - NOVO] Corpo da tela conforme o estado.
  // A lista de animais é a mesma de antes; só ganhou os casos
  // carregando e erro à sua volta.
  Widget _corpo() {
    if (_estado == EstadoFeed.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_estado == EstadoFeed.erro) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off,
                size: 56,
                color: Cores.principal.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sem conexão e sem dados salvos.\n'
                'Conecte-se à internet para carregar os animais.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Cores.textoFraco),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final animais = _animaisVisiveis;
    if (animais.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pets,
                size: 56,
                color: Cores.principal.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 14),
              const Text(
                'Nenhum animal encontrado.',
                style: TextStyle(color: Cores.textoFraco),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: animais.length,
      itemBuilder: (context, indice) {
        final animal = animais[indice];
        return CardAnimal(
          animal: animal,
          aoCompartilhar: () => _compartilhar(animal),
          aoChamarNoWhatsApp: () => _chamarNoWhatsApp(animal),
          aoTocar: () => _abrirDetalhes(animal),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        titleSpacing: 16,
        title: Row(
          children: [
            Row(
              children: [
                Image.asset('assets/marca/pata.png', width: 26),
                const SizedBox(width: 6),
                const Text(
                  'PATA\nAMIGA',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    color: Cores.principal,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _pesquisa,
                  onChanged: (valor) => setState(() => _busca = valor),
                  decoration: InputDecoration(
                    hintText: 'Pesquisar',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _busca.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Limpar pesquisa',
                            onPressed: () {
                              _pesquisa.clear();
                              setState(() => _busca = '');
                            },
                          ),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: Cores.cartao,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Cores.borda),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Cores.borda),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: EscolhaDeTipo(
              escolhido: _abaAtual,
              aoEscolher: (escolha) => setState(() => _abaAtual = escolha),
              rotulo: rotuloPlural,
              fundoDaOpcao: Cores.cartao,
            ),
          ),
          // [SPRINT 3 - NOVO] Banner de estado (cache / atualizado)
          _bannerDeEstado(),
          // [SPRINT 3 - ALTERADO] O Expanded com a lista agora vem do _corpo()
          Expanded(child: _corpo()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCadastroAnimal,
        backgroundColor: Cores.principal,
        foregroundColor: Colors.white,
        tooltip: 'Cadastrar animal',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BarraInferior(
        atual: 0,
        aoTocar: (indice) {
          if (indice == 1) {
            Navigator.pushNamed(context, AppRoutes.mapa);
          } else if (indice == 3) {
            Navigator.pushNamed(context, AppRoutes.perfilUsuario);
          } else if (indice != 0) {
            avisarProximaSprint(context);
          }
        },
      ),
    );
  }
}