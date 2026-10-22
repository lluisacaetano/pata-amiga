import 'package:flutter/material.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../modelos/ong.dart';
import '../routes/route_names.dart';
import '../services/ong_service.dart';
import '../tema/cores.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/avatar_da_ong.dart';

// As ONGs e abrigos de Formiga, pelo item "ONGs" do menu: para quem quer
// adotar, ajudar ou doar chegar à ONG sem precisar passar antes por um animal
class ListaOngs extends StatefulWidget {
  final OngService? servico;

  const ListaOngs({super.key, this.servico});

  @override
  State<ListaOngs> createState() => _ListaOngsState();
}

class _ListaOngsState extends State<ListaOngs> {
  late final _servico = widget.servico ?? OngService();
  final _pesquisa = TextEditingController();
  String _busca = '';
  bool _carregando = true;
  bool _semConexao = false;

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

  // Busca de novo ao abrir: uma ONG pode ter sido criada depois do feed
  Future<void> _carregar() async {
    try {
      final ongs = await _servico.buscarOngs();
      if (!mounted) return;
      PataAmigaScope.of(context).atualizarOngs(ongs);
      setState(() {
        _carregando = false;
        _semConexao = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _semConexao = true;
      });
    }
  }

  // A busca é pelo nome da ONG, sem ligar para maiúsculas e acentos
  bool _combina(Ong ong) {
    final busca = Ong.nomeComparavel(_busca);
    return busca.isEmpty || Ong.nomeComparavel(ong.nome).contains(busca);
  }

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final ongs = estado.ongs.where(_combina).toList()
      // Sempre em ordem alfabética, com "Órfãos" junto do "O", e não no fim
      ..sort(
        (a, b) =>
            Ong.nomeComparavel(a.nome).compareTo(Ong.nomeComparavel(b.nome)),
      );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.cores.fundo,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'ONGS E ABRIGOS',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: context.cores.principal,
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TextField(
              controller: _pesquisa,
              onChanged: (texto) => setState(() => _busca = texto),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: context.cores.cartao,
                hintText: 'Buscar pelo nome da ONG',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: context.cores.textoFraco,
                ),
                prefixIcon: Icon(Icons.search, color: context.cores.textoFraco),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: context.cores.borda),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: context.cores.principal,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_semConexao)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Sem conexão: a lista pode estar desatualizada. Puxe para '
                  'baixo para tentar de novo.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cores.textoFraco,
                  ),
                ),
              ),
            if (_carregando && estado.ongs.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: context.cores.principal,
                  ),
                ),
              )
            else if (ongs.isEmpty)
              _ListaVazia(buscando: _busca.trim().isNotEmpty)
            else
              for (final ong in ongs)
                _CartaoDaOng(
                  ong: ong,
                  emAberto: estado
                      .animaisDa(ong)
                      .where((animal) => !animal.finalizado)
                      .toList(),
                ),
          ],
        ),
      ),
      bottomNavigationBar: const BarraInferior(atual: 3),
    );
  }
}

// O card da ONG, no padrão dos cards do feed, com a foto de perfil dela em
// círculo, como um perfil; sem foto, as iniciais
class _CartaoDaOng extends StatelessWidget {
  const _CartaoDaOng({required this.ong, required this.emAberto});

  final Ong ong;
  final List<Animal> emAberto;

  @override
  Widget build(BuildContext context) {
    final quantos = emAberto.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: context.cores.cartao,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.cores.borda),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.perfilOng, arguments: ong),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AvatarDaOng(ong: ong, raio: 34),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ong.nome,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (ong.bairro.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: context.cores.principal,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${ong.bairro}, Formiga',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.cores.principal,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: context.cores.borda),
                Row(
                  children: [
                    Icon(
                      Icons.pets_outlined,
                      size: 18,
                      color: context.cores.textoFraco,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        switch (quantos) {
                          0 => 'Nenhum animal em aberto',
                          1 => '1 animal em aberto',
                          _ => '$quantos animais em aberto',
                        },
                        style: TextStyle(
                          fontSize: 13,
                          color: context.cores.textoFraco,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia({required this.buscando});

  final bool buscando;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            size: 44,
            color: context.cores.principal,
          ),
          const SizedBox(height: 12),
          Text(
            buscando
                ? 'Nenhuma ONG com esse nome.'
                : 'Nenhuma ONG cadastrada ainda.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (!buscando) ...[
            const SizedBox(height: 6),
            Text(
              'Representa uma ONG ou abrigo? Crie o perfil dela em Editar '
              'perfil.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.cores.textoFraco),
            ),
          ],
        ],
      ),
    );
  }
}
