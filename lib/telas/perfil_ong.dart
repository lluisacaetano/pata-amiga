// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter/services: área de transferência (Clipboard).
import 'package:flutter/services.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';
// Pacote url_launcher: abre WhatsApp, telefone e links no navegador.
import 'package:url_launcher/url_launcher.dart';

// Arquivo estado_pata_amiga.dart: estado global com ONGs e animais.
import '../estado/estado_pata_amiga.dart';
// Arquivo animal.dart: modelo do animal e tipo do registro.
import '../modelos/animal.dart';
// Arquivo dono.dart: número do WhatsApp a partir do telefone.
import '../modelos/dono.dart';
// Arquivo ong.dart: modelo da ONG e dos seus membros.
import '../modelos/ong.dart';
// Arquivo usuario_provider.dart: dados do usuário logado.
import '../provider/usuario_provider.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo ong_service.dart: serviço da API das ONGs (remoção de membros).
import '../services/ong_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo avatar_da_ong.dart: foto da ONG e iniciais de um nome.
import '../widgets/avatar_da_ong.dart';
// Arquivo escolha_de_tipo.dart: nome do tipo de registro no singular.
import '../widgets/escolha_de_tipo.dart';
// Arquivo etiqueta.dart: etiqueta arredondada do tipo do animal.
import '../widgets/etiqueta.dart';
// Arquivo foto_animal.dart: exibição da foto do animal.
import '../widgets/foto_animal.dart';
// Arquivo mapa_de_local.dart: prévia do mapa com a localização da ONG.
import '../widgets/mapa_de_local.dart';
// Arquivo mascaras.dart: formatação do telefone para exibição.
import '../widgets/mascaras.dart';

// Perfil público de uma ONG: identificação, descrição, contato pelo
// WhatsApp, chave Pix, animais cadastrados por tipo, política de adoção e
// localização. O responsável pela ONG vê também o botão de edição e a lista
// de membros.
class PerfilOng extends StatelessWidget {
  final Ong ong;
  // Serviço de ONGs; os testes injetam uma versão falsa
  final OngService? servico;

  const PerfilOng({super.key, required this.ong, this.servico});

  // Abre uma conversa no WhatsApp com a ONG, com uma mensagem inicial
  Future<void> _chamarNoWhatsApp(BuildContext context, Ong ong) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final numero = Dono(
      nome: ong.nome,
      telefone: ong.telefone,
    ).numeroNoWhatsApp;
    final texto = Uri.encodeComponent(
      'Olá! Vi a ${ong.nome} no Pata Amiga e queria saber mais.',
    );
    final abriu = await launchUrl(
      Uri.parse('https://wa.me/$numero?text=$texto'),
      mode: LaunchMode.externalApplication,
    );
    if (!abriu) {
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o WhatsApp neste aparelho.'),
          ),
        );
    }
  }

  // Copia a chave Pix para a área de transferência e confirma com um aviso
  Future<void> _copiarPix(BuildContext context, Ong ong) async {
    final mensageiro = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: ong.chavePix));
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Chave Pix copiada. Cole no aplicativo do seu banco para doar.',
          ),
        ),
      );
  }

  // Abre a localização da ONG no app de mapas, para traçar a rota
  Future<void> _abrirNoMapa(Ong ong) => launchUrl(
    Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${ong.latitude},${ong.longitude}',
    ),
    mode: LaunchMode.externalApplication,
  );

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    // Usa a versão do estado global, que reflete edições feitas depois que
    // a tela foi aberta
    final atual = estado.ongs.firstWhere(
      (item) => item.id != null && item.id == ong.id,
      orElse: () => ong,
    );
    final email = context.watch<UsuarioProvider?>()?.usuario.email ?? '';
    final animais = estado.animaisDa(atual);
    final emAberto = [
      for (final animal in animais)
        if (!animal.finalizado) animal,
    ];
    final encerrados = [
      for (final animal in animais)
        if (animal.finalizado) animal,
    ];
    final endereco = [
      atual.rua,
      atual.bairro,
    ].where((parte) => parte.isNotEmpty).join(', ');

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
          'ONG',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
          ),
        ),
        actions: [
          // Edição disponível apenas para o responsável pela ONG
          if (atual.eDoResponsavel(email))
            IconButton(
              tooltip: 'Editar perfil da ONG',
              icon: Icon(Icons.edit_outlined, color: context.cores.principal),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.cadastroOng,
                arguments: atual,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Cabeçalho: foto, nome e endereço da ONG
          Row(
            children: [
              AvatarDaOng(ong: atual, raio: 38),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      atual.nome,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: context.cores.texto,
                        height: 1.2,
                      ),
                    ),
                    if (endereco.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: context.cores.principal,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              endereco,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.cores.principal,
                                fontWeight: FontWeight.w600,
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
          const SizedBox(height: 16),
          Text(
            atual.descricao,
            style: const TextStyle(fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _chamarNoWhatsApp(context, atual),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Conversar no WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.cores.principal,
                foregroundColor: context.sobrePrincipal,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          if (atual.chavePix.isNotEmpty) ...[
            const SizedBox(height: 10),
            _FaixaDoPix(
              chave: atual.chavePix,
              aoCopiar: () => _copiarPix(context, atual),
            ),
          ],
          // Animais da ONG: uma seção por tipo (adoção, resgate e perdidos),
          // só para os tipos com algum animal em aberto, e uma seção final
          // para os já finalizados
          if (animais.isEmpty) ...[
            const SizedBox(height: 26),
            const _TituloDaSecao('Animais da ONG'),
            const SizedBox(height: 10),
            Text(
              'A ONG ainda não cadastrou nenhum animal.',
              style: TextStyle(fontSize: 14, color: context.cores.textoFraco),
            ),
          ],
          for (final (tipo, titulo) in const [
            (TipoRegistro.adocao, 'Para adoção'),
            (TipoRegistro.resgate, 'Resgates'),
            (TipoRegistro.perdido, 'Perdidos'),
          ])
            if (emAberto.where((animal) => animal.tipo == tipo).toList()
                case final doTipo when doTipo.isNotEmpty) ...[
              const SizedBox(height: 22),
              _TituloDaSecao(titulo, quantidade: doTipo.length),
              const SizedBox(height: 10),
              _CarrosselDeAnimais(animais: doTipo),
            ],
          if (encerrados.isNotEmpty) ...[
            const SizedBox(height: 22),
            _TituloDaSecao(
              'Já encontraram um desfecho',
              quantidade: encerrados.length,
            ),
            const SizedBox(height: 10),
            _CarrosselDeAnimais(animais: encerrados),
          ],
          // Membros: visíveis apenas ao responsável, que pode removê-los
          if (atual.eDoResponsavel(email))
            _Cartao(
              icone: Icons.group_outlined,
              titulo: 'Membros',
              child: _PessoasDaOng(ong: atual, servico: servico),
            ),
          if (atual.politicaDeAdocao.isNotEmpty)
            _Cartao(
              icone: Icons.assignment_outlined,
              titulo: 'Como adotar',
              child: Text(
                atual.politicaDeAdocao,
                style: const TextStyle(fontSize: 15, height: 1.45),
              ),
            ),
          if (atual.temLocal)
            _Cartao(
              icone: Icons.map_outlined,
              titulo: 'Onde fica',
              child: PreviaDoMapa(
                ponto: LatLng(atual.latitude!, atual.longitude!),
                cor: context.cores.principal,
                aoTocar: () => _abrirNoMapa(atual),
              ),
            ),
        ],
      ),
    );
  }
}

// Faixa com a chave Pix e o botão de copiar. O app não processa doações:
// a pessoa cola a chave no app do próprio banco
class _FaixaDoPix extends StatelessWidget {
  const _FaixaDoPix({required this.chave, required this.aoCopiar});

  final String chave;
  final VoidCallback aoCopiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: context.cores.principalClara,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            color: context.cores.principal,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doe pelo Pix, no app do seu banco',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.cores.principal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  chave,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.cores.texto,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: aoCopiar,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar'),
            style: TextButton.styleFrom(
              foregroundColor: context.cores.principal,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Título de seção, com a quantidade de itens opcional ao lado
class _TituloDaSecao extends StatelessWidget {
  const _TituloDaSecao(this.texto, {this.quantidade});

  final String texto;
  final int? quantidade;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          texto,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.cores.texto,
          ),
        ),
        if (quantidade != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: context.cores.principalClara,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$quantidade',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.cores.principal,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Carrossel horizontal de cartões de animais
class _CarrosselDeAnimais extends StatelessWidget {
  const _CarrosselDeAnimais({required this.animais});

  final List<Animal> animais;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: animais.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, indice) => SizedBox(
          width: 170,
          child: _CartaoDoAnimal(animal: animais[indice]),
        ),
      ),
    );
  }
}

// Cartão de um animal no carrossel: foto, nome, tipo, situação e bairro.
// Ao tocar, abre a ficha do animal
class _CartaoDoAnimal extends StatelessWidget {
  const _CartaoDoAnimal({required this.animal});

  final Animal animal;

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
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.details, arguments: animal),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A foto ocupa a altura restante do cartão, garantindo espaço
              // para o texto abaixo
              Expanded(
                child: LayoutBuilder(
                  builder: (context, restricoes) => FotoAnimal(
                    caminho: animal.foto,
                    altura: restricoes.maxHeight,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
              Row(
                children: [
                  Etiqueta(rotuloSingular(animal.tipo)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Seção em cartão, com ícone e título acima do conteúdo
class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.icone,
    required this.titulo,
    required this.child,
  });

  final IconData icone;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: context.cores.principal),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  color: context.cores.principal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// Lista de membros da ONG, exibida ao responsável. O responsável aparece
// primeiro e não pode ser removido; os demais têm o botão "Remover"
class _PessoasDaOng extends StatelessWidget {
  const _PessoasDaOng({required this.ong, this.servico});

  final Ong ong;
  final OngService? servico;

  // Pede confirmação, remove o membro na API e atualiza o estado global
  Future<void> _remover(BuildContext context, PessoaDaOng pessoa) async {
    final confirmou = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: context.cores.cartao,
      showDragHandle: true,
      builder: (painel) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Remover ${pessoa.nome} da ONG?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A pessoa deixa de publicar em nome da ONG e recebe um aviso. '
                'Os animais que ela já publicou continuam no perfil da ONG.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.cores.textoFraco,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(painel, false),
                style: FilledButton.styleFrom(
                  backgroundColor: context.cores.principal,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Manter na ONG'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(painel, true),
                style: TextButton.styleFrom(
                  foregroundColor: context.cores.destaque,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Remover'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmou != true || !context.mounted) return;
    final estado = PataAmigaScope.of(context);
    final mensageiro = ScaffoldMessenger.of(context);
    String aviso;
    try {
      estado.salvarOng(
        await (servico ?? OngService()).removerMembro(ong, pessoa.email),
      );
      aviso = '${pessoa.nome} não faz mais parte de ${ong.nome}.';
    } on Exception {
      aviso = 'Não foi possível remover agora. Tente de novo.';
    }
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(aviso)));
  }

  // Linha de uma pessoa: iniciais, nome, detalhe e uma ação opcional
  Widget _linha(
    BuildContext context,
    String nome,
    String detalhe, {
    Widget? acao,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: context.cores.principalClara,
          child: Text(
            iniciaisDa(nome),
            style: TextStyle(
              color: context.cores.principal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (detalhe.isNotEmpty)
                Text(
                  detalhe,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cores.textoFraco,
                  ),
                ),
            ],
          ),
        ),
        ?acao,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<UsuarioProvider?>()?.usuario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _linha(
          context,
          (usuario?.nome.trim().isNotEmpty ?? false) ? usuario!.nome : 'Você',
          'Administra a ONG',
        ),
        for (final pessoa in ong.membros)
          _linha(
            context,
            pessoa.nome,
            formatarTelefone(pessoa.telefone),
            acao: TextButton(
              onPressed: () => _remover(context, pessoa),
              style: TextButton.styleFrom(
                foregroundColor: context.cores.destaque,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('Remover'),
            ),
          ),
        if (ong.membros.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Ainda só você. Quem disser que faz parte da ONG aparece no '
              'sino de notificações para você aprovar.',
              style: TextStyle(fontSize: 13, color: context.cores.textoFraco),
            ),
          ),
      ],
    );
  }
}
