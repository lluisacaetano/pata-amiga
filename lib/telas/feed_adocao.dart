import 'package:flutter/material.dart';
import '../dados/animais_mock.dart';
import '../modelos/animal.dart';
import '../tema/cores.dart';
import '../widgets/card_animal.dart';
import '../widgets/chip_filtro.dart';
import 'cadastro_animal.dart';
import 'detalhes_animal.dart';

class FeedAdocao extends StatefulWidget {
  const FeedAdocao({super.key});

  @override
  State<FeedAdocao> createState() => _FeedAdocaoState();
}

class _FeedAdocaoState extends State<FeedAdocao> {
  final List<Animal> _animais = List.of(animaisMock);
  final Set<String> _curtidos = {};
  TipoRegistro _abaAtual = TipoRegistro.adocao;
  String _busca = '';

  List<Animal> get _animaisVisiveis {
    final termo = _busca.trim().toLowerCase();
    return _animais.where((animal) {
      if (animal.tipo != _abaAtual) return false;
      if (termo.isEmpty) return true;
      return animal.nome.toLowerCase().contains(termo) ||
          animal.especie.toLowerCase().contains(termo) ||
          animal.raca.toLowerCase().contains(termo);
    }).toList();
  }

  void _alternarCurtida(Animal animal) {
    setState(() {
      if (_curtidos.contains(animal.nome)) {
        _curtidos.remove(animal.nome);
      } else {
        _curtidos.add(animal.nome);
      }
    });
  }

  Future<void> _abrirCadastro() async {
    final novo = await Navigator.push<Animal>(
      context,
      MaterialPageRoute(builder: (_) => const CadastroAnimal()),
    );
    if (novo == null) return;
    setState(() {
      _animais.insert(0, novo);
      _abaAtual = novo.tipo;
    });
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final visiveis = _animaisVisiveis;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        titleSpacing: 16,
        title: Row(
          children: [
            const Text(
              'PATA\nAMIGA',
              style: TextStyle(
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.bold,
                color: Cores.principal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  onChanged: (valor) => setState(() => _busca = valor),
                  decoration: InputDecoration(
                    hintText: 'pesquisar',
                    prefixIcon: const Icon(Icons.search, size: 20),
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
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (final tipo in TipoRegistro.values) ...[
                  ChipFiltro(
                    rotulo: tipo.rotulo,
                    selecionado: _abaAtual == tipo,
                    aoTocar: () => setState(() => _abaAtual = tipo),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: visiveis.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Nenhum animal cadastrado nesta aba por enquanto.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Cores.textoFraco),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: visiveis.length,
                    itemBuilder: (context, indice) {
                      final animal = visiveis[indice];
                      return CardAnimal(
                        animal: animal,
                        curtido: _curtidos.contains(animal.nome),
                        aoCurtir: () => _alternarCurtida(animal),
                        aoTocar: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetalhesAnimal(animal: animal),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCadastro,
        backgroundColor: Cores.principal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Cores.principal,
        unselectedItemColor: Cores.textoFraco,
        onTap: (indice) {
          if (indice != 0) {
            _aviso('Esta tela entra em uma próxima sprint.');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'adoção'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'mapa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_outlined),
            label: 'reportar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'perfil',
          ),
        ],
      ),
    );
  }
}
