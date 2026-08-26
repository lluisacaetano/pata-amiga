import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dados/animais_mock.dart';
import '../modelos/animal.dart';
import '../tema/cores.dart';
import '../widgets/card_animal.dart';

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

  Future<void> _compartilhar(Animal animal) async {
    final situacao = switch (animal.tipo) {
      TipoRegistro.adocao => 'Disponível para adoção',
      TipoRegistro.perdido => 'Está perdido',
      TipoRegistro.resgate => 'Precisa de resgate',
    };

    final texto =
        '${animal.nome}, ${animal.sexo}, porte ${animal.porte}, '
        '${animal.idade}, em ${animal.cidade}.\n'
        '$situacao.\n\n'
        'Responsável: ${animal.dono.nome}\n'
        'Telefone: ${animal.dono.telefone}\n\n'
        'Divulgado pelo Pata Amiga.';

    // O compartilhamento só aceita arquivo, e a foto é um asset, então converte
    final imagem = await rootBundle.load(animal.foto);
    final arquivo = XFile.fromData(
      imagem.buffer.asUint8List(),
      mimeType: 'image/jpeg',
      name: '${animal.nome}.jpg',
    );

    await SharePlus.instance.share(
      ShareParams(text: texto, files: [arquivo]),
    );
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
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: animaisMock.length,
        itemBuilder: (context, indice) {
          final animal = animaisMock[indice];
          return CardAnimal(
            animal: animal,
            curtido: _curtidos.contains(animal.nome),
            aoCurtir: () => _alternarCurtida(animal),
            aoCompartilhar: () => _compartilhar(animal),
            aoConversar: _emBreve,
            aoTocar: _emBreve,
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (indice) {
          if (indice != 0) _emBreve();
        },
        selectedItemColor: Cores.principal,
        unselectedItemColor: Cores.textoFraco,
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
