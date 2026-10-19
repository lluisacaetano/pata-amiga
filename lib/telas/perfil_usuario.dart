import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../modelos/usuario.dart';
import '../provider/usuario_provider.dart';
import '../routes/route_names.dart';
import '../tema/cores.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/escolha_de_tipo.dart';
import '../widgets/etiqueta.dart';
import '../widgets/foto_animal.dart';

enum _SecaoPerfil { curtidos, meusCadastros }

class PerfilUsuario extends StatefulWidget {
  const PerfilUsuario({super.key});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  // Abre nos curtidos, que é a lista que a pessoa mais volta para consultar
  _SecaoPerfil _secao = _SecaoPerfil.curtidos;

  // O feed é sempre a primeira tela depois do login. Voltar só uma tela
  // levaria ao mapa quando o perfil foi aberto por ele
  void _voltarAoFeed() {
    Navigator.of(context).popUntil((rota) => rota.isFirst);
  }

  void _abrirDetalhes(Animal animal) {
    Navigator.pushNamed(context, AppRoutes.details, arguments: animal);
  }

  // Tira dos curtidos e deixa desfazer, porque o coração fica fácil de tocar
  // sem querer em cima da foto
  Future<void> _removerCurtida(EstadoPataAmiga estado, Animal animal) async {
    await estado.removerCurtida(animal.nome);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${animal.nome} saiu dos seus curtidos.'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => estado.alternarCurtida(animal.nome),
          ),
        ),
      );
  }

  Future<void> _sair() async {
    await context.read<UsuarioProvider>().encerrarSessao();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.welcome, (rota) => false);
  }

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final usuario = context.watch<UsuarioProvider>().usuario;
    final curtidos = estado.animaisCurtidos;
    final cadastros = estado.meusCadastros;

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
          'MEU PERFIL',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Cores.principal,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout, color: Cores.principal),
            onPressed: _sair,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Cabecalho(
            usuario: usuario,
            aoEditar: () =>
                Navigator.pushNamed(context, AppRoutes.editarPerfil),
          ),
          const SizedBox(height: 24),
          _SeletorDeSecao(
            secao: _secao,
            aoEscolher: (secao) => setState(() => _secao = secao),
          ),
          const SizedBox(height: 16),
          if (_secao == _SecaoPerfil.curtidos)
            curtidos.isEmpty
                ? _ListaVazia(
                    icone: Icons.favorite_border,
                    titulo: 'Nenhum animal curtido ainda',
                    texto:
                        'Toque no coração de um animal no feed para guardá-lo '
                        'aqui e decidir com calma.',
                    aoVerAnimais: _voltarAoFeed,
                  )
                : _GradeDeCurtidos(
                    animais: curtidos,
                    aoAbrir: _abrirDetalhes,
                    aoRemover: (animal) => _removerCurtida(estado, animal),
                  )
          else
            cadastros.isEmpty
                ? _ListaVazia(
                    icone: Icons.pets_outlined,
                    titulo: 'Nenhum animal cadastrado ainda',
                    texto:
                        'Os animais que você cadastrar pelo botão + do feed '
                        'aparecem aqui.',
                    aoVerAnimais: _voltarAoFeed,
                  )
                : Column(
                    children: [
                      for (final animal in cadastros)
                        _LinhaDeCadastro(
                          animal: animal,
                          aoAbrir: () => _abrirDetalhes(animal),
                        ),
                    ],
                  ),
        ],
      ),
      bottomNavigationBar: BarraInferior(
        atual: 3,
        aoTocar: (indice) {
          if (indice == 0) {
            _voltarAoFeed();
          } else if (indice != 3) {
            avisarProximaSprint(context);
          }
        },
      ),
    );
  }
}

// Foto, nome e contato abertos no fundo da tela, sem cartão em volta: é a
// pessoa, não um bloco de dados
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.usuario, required this.aoEditar});

  final Usuario usuario;
  final VoidCallback aoEditar;

  @override
  Widget build(BuildContext context) {
    final nome = usuario.nome.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Avatar(caminho: usuario.foto),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome.isEmpty ? 'Sem nome' : nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Cores.texto,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (usuario.email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _Contato(icone: Icons.mail_outline, texto: usuario.email),
                  ],
                  if (usuario.telefone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _Contato(
                      icone: Icons.phone_outlined,
                      texto: usuario.telefone,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: aoEditar,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Editar perfil'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Cores.principal,
            side: const BorderSide(color: Cores.principal),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.caminho});

  final String? caminho;

  @override
  Widget build(BuildContext context) {
    final foto = caminho;
    final ImageProvider<Object>? imagem = foto == null || foto.isEmpty
        ? null
        : kIsWeb
        ? NetworkImage(foto)
        : FileImage(File(foto));
    // O anel claro destaca a foto do fundo da tela
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Cores.principalClara,
      ),
      child: CircleAvatar(
        radius: 36,
        backgroundColor: Cores.principalClara,
        backgroundImage: imagem,
        child: imagem == null
            ? const Icon(Icons.person_outline, size: 36, color: Cores.principal)
            : null,
      ),
    );
  }
}

class _Contato extends StatelessWidget {
  const _Contato({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 15, color: Cores.textoFraco),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Cores.textoFraco, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// As mesmas abas do feed, com o mesmo estilo, para a pessoa reconhecer o gesto
class _SeletorDeSecao extends StatelessWidget {
  const _SeletorDeSecao({required this.secao, required this.aoEscolher});

  final _SecaoPerfil secao;
  final ValueChanged<_SecaoPerfil> aoEscolher;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_SecaoPerfil>(
        segments: const [
          ButtonSegment(value: _SecaoPerfil.curtidos, label: Text('Curtidos')),
          ButtonSegment(
            value: _SecaoPerfil.meusCadastros,
            label: Text('Meus cadastros'),
          ),
        ],
        selected: {secao},
        showSelectedIcon: false,
        onSelectionChanged: (escolha) => aoEscolher(escolha.first),
        style: estiloDasAbas(Cores.cartao),
      ),
    );
  }
}

// Os curtidos em grade de fotos, como a pessoa os viu no feed: é pela foto
// que ela reconhece o animal que tinha guardado
class _GradeDeCurtidos extends StatelessWidget {
  const _GradeDeCurtidos({
    required this.animais,
    required this.aoAbrir,
    required this.aoRemover,
  });

  final List<Animal> animais;
  final ValueChanged<Animal> aoAbrir;
  final ValueChanged<Animal> aoRemover;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: animais.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 240,
      ),
      itemBuilder: (context, indice) {
        final animal = animais[indice];
        return _CartaoCurtido(
          animal: animal,
          aoAbrir: () => aoAbrir(animal),
          aoRemover: () => aoRemover(animal),
        );
      },
    );
  }
}

class _CartaoCurtido extends StatelessWidget {
  const _CartaoCurtido({
    required this.animal,
    required this.aoAbrir,
    required this.aoRemover,
  });

  final Animal animal;
  final VoidCallback aoAbrir;
  final VoidCallback aoRemover;

  @override
  Widget build(BuildContext context) {
    return _CartaoDoFeed(
      aoTocar: aoAbrir,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A foto fica com o que sobrar da altura do card, para o texto
          // embaixo nunca estourar
          Expanded(
            child: LayoutBuilder(
              builder: (context, restricoes) => Stack(
                children: [
                  FotoAnimal(
                    caminho: animal.foto,
                    altura: restricoes.maxHeight,
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Cores.cartao,
                      shape: const CircleBorder(),
                      elevation: 1,
                      child: IconButton(
                        tooltip: 'Remover dos curtidos',
                        visualDensity: VisualDensity.compact,
                        onPressed: aoRemover,
                        icon: const Icon(
                          Icons.favorite,
                          color: Cores.principal,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            animal.nome.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Etiqueta(rotuloSingular(animal.tipo)),
              // Disponível ou adotado só diz algo sobre adoção
              if (animal.tipo == TipoRegistro.adocao) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    comMaiuscula(animal.status.rotulo),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Cores.textoFraco,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          _Lugar(animal: animal),
        ],
      ),
    );
  }
}

// Os cadastros em lista, porque aqui o que importa é a situação de cada
// registro e há quanto tempo ele foi publicado, mais do que a foto
class _LinhaDeCadastro extends StatelessWidget {
  const _LinhaDeCadastro({required this.animal, required this.aoAbrir});

  final Animal animal;
  final VoidCallback aoAbrir;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _CartaoDoFeed(
        aoTocar: aoAbrir,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: FotoAnimal(caminho: animal.foto, altura: 76),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.nome.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Etiqueta(rotuloSingular(animal.tipo)),
                      if (animal.status == StatusAnimal.adotado)
                        Etiqueta(animal.status.rotulo, cheia: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _Lugar(animal: animal, comData: true),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Cores.textoFraco),
          ],
        ),
      ),
    );
  }
}

// Mesma moldura do card do feed: branco, borda clara e canto de 16
class _CartaoDoFeed extends StatelessWidget {
  const _CartaoDoFeed({
    required this.child,
    required this.aoTocar,
    required this.padding,
  });

  final Widget child;
  final VoidCallback aoTocar;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Cores.cartao,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// O lugar em verde com o alfinete, como no card do feed. Nos cadastros vem
// junto há quanto tempo foi publicado
class _Lugar extends StatelessWidget {
  const _Lugar({required this.animal, this.comData = false});

  final Animal animal;
  final bool comData;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 15,
          color: Cores.principal,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${animal.bairro}, ${animal.cidade}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Cores.principal,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (comData)
          Text(
            ' · ${animal.publicadoHa(DateTime.now())}',
            style: const TextStyle(color: Cores.textoFraco, fontSize: 13),
          ),
      ],
    );
  }
}

// Lista vazia aponta o caminho: o feed é onde se curte e de onde se cadastra
class _ListaVazia extends StatelessWidget {
  const _ListaVazia({
    required this.icone,
    required this.titulo,
    required this.texto,
    required this.aoVerAnimais,
  });

  final IconData icone;
  final String titulo;
  final String texto;
  final VoidCallback aoVerAnimais;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Cores.principalClara,
            child: Icon(icone, size: 30, color: Cores.principal),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Cores.texto,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Cores.textoFraco,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: aoVerAnimais,
            style: TextButton.styleFrom(foregroundColor: Cores.principal),
            child: const Text(
              'Ver animais no feed',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
