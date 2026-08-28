import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dados/animais_mock.dart';
import '../modelos/animal.dart';
import '../modelos/dono.dart';
import '../tema/cores.dart';
import '../widgets/card_animal.dart';
import '../widgets/escolha_de_tipo.dart';
import 'cadastro_animal.dart';

class FeedAdocao extends StatefulWidget {
  const FeedAdocao({super.key});

  @override
  State<FeedAdocao> createState() => _FeedAdocaoState();
}

class _FeedAdocaoState extends State<FeedAdocao> {
  // Guarda o nome dos animais que o usuário curtiu
  Set<String> _curtidos = {};

  // Chave usada para gravar as curtidas no armazenamento do aparelho
  static const _chaveCurtidos = 'curtidos';

  // Aba aberta no momento, que decide quais animais o feed mostra
  TipoRegistro _abaAtual = TipoRegistro.adocao;

  // O que foi digitado no campo de pesquisa
  final _pesquisa = TextEditingController();
  String _busca = '';

  @override
  void dispose() {
    _pesquisa.dispose();
    super.dispose();
  }

  List<Animal> get _animaisVisiveis {
    final termo = _busca.trim().toLowerCase();
    return animaisMock.where((animal) {
      if (animal.tipo != _abaAtual) return false;
      if (termo.isEmpty) return true;
      return animal.nome.toLowerCase().contains(termo) ||
          animal.raca.toLowerCase().contains(termo) ||
          animal.especie.toLowerCase().contains(termo);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _carregarCurtidas();
  }

  Future<void> _carregarCurtidas() async {
    final armazenamento = await SharedPreferences.getInstance();
    final salvos = armazenamento.getStringList(_chaveCurtidos) ?? [];
    if (!mounted) return;
    setState(() => _curtidos = salvos.toSet());
  }

  // Enquanto a funcionalidade não existe, o toque avisa em vez de não fazer
  // nada, para o usuário saber que o botão não está quebrado
  void _emBreve() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Esta tela entra em uma próxima sprint.'),
          duration: Duration(seconds: 2),
        ),
      );
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

    // O compartilhamento só aceita arquivo, e a foto é um asset, então converte
    final imagem = await rootBundle.load(animal.foto);
    final arquivo = XFile.fromData(
      imagem.buffer.asUint8List(),
      mimeType: 'image/jpeg',
      name: '${animal.nome}.jpg',
    );

    await SharePlus.instance.share(ShareParams(text: texto, files: [arquivo]));
  }

  Future<void> _alternarCurtida(Animal animal) async {
    setState(() {
      if (_curtidos.contains(animal.nome)) {
        _curtidos.remove(animal.nome);
      } else {
        _curtidos.add(animal.nome);
      }
    });

    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setStringList(_chaveCurtidos, _curtidos.toList());
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
          Expanded(
            child: _animaisVisiveis.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: _animaisVisiveis.length,
                    itemBuilder: (context, indice) {
                      final animal = _animaisVisiveis[indice];
                      return CardAnimal(
                        animal: animal,
                        curtido: _curtidos.contains(animal.nome),
                        aoCurtir: () => _alternarCurtida(animal),
                        aoCompartilhar: () => _compartilhar(animal),
                        aoChamarNoWhatsApp: () => _chamarNoWhatsApp(animal),
                        aoTocar: _emBreve,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const CadastroAnimal())),
        backgroundColor: Cores.principal,
        foregroundColor: Colors.white,
        tooltip: 'Cadastrar animal',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Cores.cartao,
        onTap: (indice) {
          if (indice != 0) _emBreve();
        },
        selectedItemColor: Cores.principal,
        unselectedItemColor: Cores.textoFraco,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adoção'),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_outlined),
            label: 'Reportar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
