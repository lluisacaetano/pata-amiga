// Biblioteca dart:io: acesso a arquivos do aparelho, como a foto de perfil.
import 'dart:io';

// Pacote flutter/foundation: kIsWeb, para carregar a foto na web.
import 'package:flutter/foundation.dart';
// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo estado_pata_amiga.dart: estado compartilhado do app.
import '../estado/estado_pata_amiga.dart';
// Arquivo animal.dart: modelo do animal, tipo e status do registro.
import '../modelos/animal.dart';
// Arquivo usuario.dart: modelo do usuário.
import '../modelos/usuario.dart';
// Arquivo usuario_provider.dart: sessão e perfil da pessoa logada.
import '../provider/usuario_provider.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo animal_service.dart: serviço de animais da API.
import '../services/animal_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo acoes_do_registro.dart: ações sobre um registro de animal.
import '../widgets/acoes_do_registro.dart';
// Arquivo barra_inferior.dart: barra de navegação inferior.
import '../widgets/barra_inferior.dart';
// Arquivo vinculo_com_ong.dart: vínculo da pessoa com a ONG.
import '../widgets/vinculo_com_ong.dart';
// Arquivo escolha_de_tipo.dart: nome do tipo no singular e estilo das abas.
import '../widgets/escolha_de_tipo.dart';
// Arquivo etiqueta.dart: etiqueta de tipo e status.
import '../widgets/etiqueta.dart';
// Arquivo foto_animal.dart: foto do animal.
import '../widgets/foto_animal.dart';
// Arquivo mascaras.dart: formatação do telefone.
import '../widgets/mascaras.dart';
// Arquivo sino_de_notificacoes.dart: sino de notificações da conta.
import '../widgets/sino_de_notificacoes.dart';

// Abas do perfil
enum _SecaoPerfil { curtidos, meusCadastros }

// Itens do menu de três pontos da barra superior
enum _OpcaoDoMenu { denuncias, aparencia, acessibilidade, sair }

// Grupos de "Meus registros", na ordem de exibição: primeiro os que ainda
// estão em aberto, depois cada desfecho
const _gruposDeRegistro = [
  (titulo: 'Em aberto', status: StatusAnimal.disponivel),
  (titulo: 'Adotados', status: StatusAnimal.adotado),
  (titulo: 'Resgatados', status: StatusAnimal.resgatado),
  (titulo: 'Encontrados', status: StatusAnimal.encontrado),
];

// Perfil da pessoa logada: dados de contato, vínculo com ONG, notificações,
// curtidos e os animais que ela registrou, agrupados por status
class PerfilUsuario extends StatefulWidget {
  // Serviço injetável para os testes; sem ele, usa o AnimalService padrão
  final AnimalService? api;

  const PerfilUsuario({super.key, this.api});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  // Abre na aba de curtidos, a mais consultada
  _SecaoPerfil _secao = _SecaoPerfil.curtidos;

  // Volta até a primeira rota da pilha, que é sempre o feed depois do login.
  // Um pop simples poderia cair no mapa, se o perfil foi aberto por ele
  void _voltarAoFeed() {
    Navigator.of(context).popUntil((rota) => rota.isFirst);
  }

  void _abrirDetalhes(Animal animal) {
    Navigator.pushNamed(context, AppRoutes.details, arguments: animal);
  }

  // Remove dos curtidos e oferece "Desfazer", porque o coração sobre a foto
  // é fácil de tocar sem querer
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

  // Um grupo de "Meus registros": título com a quantidade e a grade de
  // cards. Grupo vazio não é exibido
  List<Widget> _grupo(
    String titulo,
    List<Animal> animais,
    EstadoPataAmiga estado,
    String email,
  ) {
    if (animais.isEmpty) return const [];
    return [
      _TituloDoGrupo(titulo: titulo, quantidade: animais.length),
      // Grade de duas colunas, como a dos curtidos
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          for (final animal in animais)
            _CartaoDeRegistro(
              animal: animal,
              aoAbrir: () => _abrirDetalhes(animal),
              ong: estado.ongDe(email)?.nome,
              // Sem permissão para alterar (por exemplo, cadastro feito por
              // outra conta no mesmo aparelho), o card só abre a ficha
              aoEscolher: estado.podeMudarStatus(animal, email)
                  ? (acao) => _agir(acao, animal)
                  : null,
            ),
        ],
      ),
    ];
  }

  // Executa a ação escolhida no menu do card
  Future<void> _agir(_AcaoDoRegistro acao, Animal animal) => switch (acao) {
    _AcaoDoRegistro.editar => editarRegistro(context, animal, api: widget.api),
    _AcaoDoRegistro.mudarStatus => mudarStatus(
      context,
      animal,
      api: widget.api,
    ),
    _AcaoDoRegistro.enviarParaOng => _transferir(animal),
    _AcaoDoRegistro.publicar => publicarParaAdocao(
      context,
      animal,
      api: widget.api,
    ),
  };

  // Busca a ONG no momento da ação, porque a pessoa pode ter saído dela
  // enquanto o menu estava aberto
  Future<void> _transferir(Animal animal) async {
    final email = context.read<UsuarioProvider>().usuario.email;
    final ong = PataAmigaScope.of(context).ongDe(email);
    if (ong == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Você não faz mais parte de uma ONG.')),
        );
      return;
    }
    await enviarParaOng(context, animal, ong, api: widget.api);
  }

  // Item do menu com ícone e texto; a cor opcional destaca "Sair da conta"
  PopupMenuItem<_OpcaoDoMenu> _itemDoMenu(
    _OpcaoDoMenu opcao,
    IconData icone,
    String texto, {
    Color? cor,
  }) => PopupMenuItem(
    value: opcao,
    child: Row(
      children: [
        Icon(icone, size: 20, color: cor ?? context.cores.principal),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            texto,
            style: TextStyle(color: cor ?? context.cores.texto),
          ),
        ),
      ],
    ),
  );

  // Encerra a sessão e volta para as boas-vindas, limpando a pilha de telas
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
    final cadastros = estado.cadastrosDe(usuario.email);

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
          'MEU PERFIL',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
          ),
        ),
        actions: [
          // Notificações da conta, como os pedidos de entrada na ONG que a
          // pessoa administra
          SinoDeNotificacoes(email: usuario.email),
          // Denúncias, aparência, acessibilidade e sair ficam num menu só,
          // para não ocupar o corpo do perfil
          PopupMenuButton<_OpcaoDoMenu>(
            tooltip: 'Mais opções',
            icon: Icon(Icons.more_vert, color: context.cores.principal),
            color: context.cores.cartao,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (opcao) => switch (opcao) {
              _OpcaoDoMenu.denuncias => Navigator.pushNamed(
                context,
                AppRoutes.minhasDenuncias,
              ),
              _OpcaoDoMenu.aparencia => Navigator.pushNamed(
                context,
                AppRoutes.configuracoesAparencia,
              ),
              _OpcaoDoMenu.acessibilidade => Navigator.pushNamed(
                context,
                AppRoutes.configuracoesAcessibilidade,
              ),
              _OpcaoDoMenu.sair => _sair(),
            },
            itemBuilder: (_) => [
              _itemDoMenu(
                _OpcaoDoMenu.denuncias,
                Icons.shield_outlined,
                'Minhas denúncias',
              ),
              const PopupMenuDivider(),
              _itemDoMenu(
                _OpcaoDoMenu.aparencia,
                Icons.palette_outlined,
                'Aparência',
              ),
              _itemDoMenu(
                _OpcaoDoMenu.acessibilidade,
                Icons.accessibility_new,
                'Acessibilidade',
              ),
              const PopupMenuDivider(),
              _itemDoMenu(
                _OpcaoDoMenu.sair,
                Icons.logout,
                'Sair da conta',
                cor: context.cores.destaque,
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Cabecalho(
            usuario: usuario,
            aoEditar: () =>
                Navigator.pushNamed(context, AppRoutes.editarPerfil),
            vinculo: VinculoComOng(
              ong: estado.ongDe(usuario.email),
              pedida: estado.ongPedidaPor(usuario.email),
            ),
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
                    titulo: 'Nenhum animal registrado ainda',
                    texto:
                        'Os animais que você cadastrar pelo botão + do feed '
                        'aparecem aqui.',
                    aoVerAnimais: _voltarAoFeed,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Para quem faz parte de uma ONG, uma dica de que os
                      // registros podem ser transferidos para ela
                      if (estado.ongDe(usuario.email) case final ong?
                          when cadastros.isNotEmpty)
                        _DicaDaOng(ong: ong.nome),
                      for (final grupo in _gruposDeRegistro)
                        ..._grupo(
                          grupo.titulo,
                          [
                            for (final animal in cadastros)
                              if (animal.status == grupo.status) animal,
                          ],
                          estado,
                          usuario.email,
                        ),
                    ],
                  ),
        ],
      ),
      bottomNavigationBar: BarraInferior(atual: 4),
    );
  }
}

// Topo do perfil: foto, nome, contato, vínculo com ONG e o botão de editar
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.usuario,
    required this.aoEditar,
    this.vinculo,
  });

  final Usuario usuario;
  final VoidCallback aoEditar;
  // Vínculo com ONG exibido abaixo do contato, quando houver
  final Widget? vinculo;

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
                    style: TextStyle(
                      color: context.cores.texto,
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
                      texto: formatarTelefone(usuario.telefone),
                    ),
                  ],
                  if (vinculo case final vinculo?) ...[
                    const SizedBox(height: 8),
                    vinculo,
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
            foregroundColor: context.cores.principal,
            side: BorderSide(color: context.cores.principal),
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

// Foto de perfil salva no aparelho (ou URL, na web); sem foto, um ícone
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
    // O anel claro separa a foto do fundo da tela
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.cores.principalClara,
      ),
      child: CircleAvatar(
        radius: 36,
        backgroundColor: context.cores.principalClara,
        backgroundImage: imagem,
        child: imagem == null
            ? Icon(Icons.person_outline, size: 36, color: context.cores.principal)
            : null,
      ),
    );
  }
}

// Linha de contato com ícone, cortada em uma linha
class _Contato extends StatelessWidget {
  const _Contato({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 15, color: context.cores.textoFraco),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.cores.textoFraco, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// Alternância entre as abas, com o mesmo estilo das abas do feed
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
            label: Text('Meus registros'),
          ),
        ],
        selected: {secao},
        showSelectedIcon: false,
        onSelectionChanged: (escolha) => aoEscolher(escolha.first),
        style: estiloDasAbas(context, context.cores.cartao),
      ),
    );
  }
}

// Curtidos em grade com foto em destaque, já que é pela foto que a pessoa
// reconhece o animal que guardou
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

// Card de um curtido: foto com o botão de remover, nome, tipo, status e local
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
          // A foto ocupa a altura que sobra no card, para o texto abaixo
          // nunca estourar
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
                      color: context.cores.cartao,
                      shape: const CircleBorder(),
                      elevation: 1,
                      child: IconButton(
                        tooltip: 'Remover dos curtidos',
                        visualDensity: VisualDensity.compact,
                        onPressed: aoRemover,
                        icon: Icon(
                          Icons.favorite,
                          color: context.cores.principal,
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
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  comMaiuscula(animal.rotuloDoStatus),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.cores.textoFraco, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Lugar(animal: animal),
        ],
      ),
    );
  }
}

// Ações disponíveis no menu do card de um registro
enum _AcaoDoRegistro { editar, mudarStatus, publicar, enviarParaOng }

// Nome do grupo e a quantidade de registros, acima da grade
class _TituloDoGrupo extends StatelessWidget {
  const _TituloDoGrupo({required this.titulo, required this.quantidade});

  final String titulo;
  final int quantidade;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
      child: Row(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.cores.principal,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$quantidade',
            style: TextStyle(fontSize: 14, color: context.cores.textoFraco),
          ),
        ],
      ),
    );
  }
}

// Card de um registro próprio: foto com o menu de ações, nome, tipo, status,
// local e há quanto tempo foi publicado
class _CartaoDeRegistro extends StatelessWidget {
  const _CartaoDeRegistro({
    required this.animal,
    required this.aoAbrir,
    this.aoEscolher,
    this.ong,
  });

  final Animal animal;
  final VoidCallback aoAbrir;
  // Nome da ONG da pessoa; quando presente, o menu oferece a transferência
  final String? ong;
  // Sem callback, o card não mostra o menu e só abre a ficha
  final ValueChanged<_AcaoDoRegistro>? aoEscolher;

  @override
  Widget build(BuildContext context) {
    return _CartaoDoFeed(
      aoTocar: aoAbrir,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A foto ocupa a altura que sobra, como nos curtidos; o menu de
          // ações fica no botão redondo do canto
          Expanded(
            child: LayoutBuilder(
              builder: (context, restricoes) => Stack(
                children: [
                  FotoAnimal(
                    caminho: animal.foto,
                    altura: restricoes.maxHeight,
                  ),
                  if (aoEscolher != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: context.cores.cartao,
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: PopupMenuButton<_AcaoDoRegistro>(
                            tooltip: 'Opções de ${animal.nome}',
                            icon: Icon(
                              Icons.more_vert,
                              color: context.cores.principal,
                              size: 20,
                            ),
                            onSelected: aoEscolher,
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: _AcaoDoRegistro.editar,
                                child: Text('Editar registro'),
                              ),
                              PopupMenuItem(
                                value: _AcaoDoRegistro.mudarStatus,
                                child: Text(
                                  animal.finalizado
                                      ? 'Voltar para ${animal.comStatus(StatusAnimal.disponivel).rotuloDoStatus}'
                                      : 'Marcar como ${animal.comStatus(animal.desfecho).rotuloDoStatus}',
                                ),
                              ),
                              if (animal.status == StatusAnimal.resgatado)
                                const PopupMenuItem(
                                  value: _AcaoDoRegistro.publicar,
                                  child: Text('Publicar para adoção'),
                                ),
                              if (ong != null)
                                PopupMenuItem(
                                  value: _AcaoDoRegistro.enviarParaOng,
                                  child: Text('Transferir para $ong'),
                                ),
                            ],
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
              const SizedBox(width: 6),
              Flexible(
                child: animal.finalizado
                    ? Etiqueta(animal.rotuloDoStatus, cheia: true)
                    : Text(
                        comMaiuscula(animal.rotuloDoStatus),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.cores.textoFraco,
                          fontSize: 12,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Lugar(animal: animal),
          const SizedBox(height: 2),
          Text(
            'Publicado ${animal.publicadoHa(DateTime.now())}',
            style: TextStyle(color: context.cores.textoFraco, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Moldura tocável igual à do card do feed: cor de cartão do tema, borda
// clara e canto arredondado de 16
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
      color: context.cores.cartao,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// Bairro e cidade na cor principal, com o ícone de local, como no feed
class _Lugar extends StatelessWidget {
  const _Lugar({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 15,
          color: context.cores.principal,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${animal.bairro}, ${animal.cidade}',
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
    );
  }
}

// Estado vazio de uma aba, com o atalho para o feed, onde se curte e de
// onde se cadastra
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
            backgroundColor: context.cores.principalClara,
            child: Icon(icone, size: 30, color: context.cores.principal),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.cores.texto,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.cores.textoFraco,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: aoVerAnimais,
            style: TextButton.styleFrom(foregroundColor: context.cores.principal),
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

// Aviso de que os registros podem ser transferidos para a ONG da pessoa
class _DicaDaOng extends StatelessWidget {
  const _DicaDaOng({required this.ong});

  final String ong;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cores.principalClara,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            color: context.cores.principal,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Você faz parte de $ong. Pelo menu de cada animal, dá para '
              'transferir o cadastro para a ONG.',
              style: TextStyle(
                fontSize: 13,
                color: context.cores.principal,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
