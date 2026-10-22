import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../modelos/dono.dart';
import '../modelos/ong.dart';
import '../provider/usuario_provider.dart';
import '../routes/route_names.dart';
import '../services/ong_service.dart';
import '../tema/cores.dart';
import '../widgets/avatar_da_ong.dart';
import '../widgets/escolha_de_tipo.dart';
import '../widgets/etiqueta.dart';
import '../widgets/foto_animal.dart';
import '../widgets/mapa_de_local.dart';
import '../widgets/mascaras.dart';

// O perfil público da ONG: quem ela é, como adotar, como falar com ela, como
// doar e os animais que ela cadastrou. Quem administra a ONG vê também o "Editar"
class PerfilOng extends StatelessWidget {
  final Ong ong;
  // Os testes passam um serviço de ONGs falso; o app usa o de verdade
  final OngService? servico;

  const PerfilOng({super.key, required this.ong, this.servico});

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

  // O mapa do aparelho, com o ponto da ONG, para traçar o caminho até lá
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
    // A versão mais nova: o perfil pode ter sido editado depois de aberto
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
          'ONG',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Cores.principal,
          ),
        ),
        actions: [
          // Só quem administra a ONG muda os dados dela, como a chave Pix
          if (atual.eDoResponsavel(email))
            IconButton(
              tooltip: 'Editar perfil da ONG',
              icon: const Icon(Icons.edit_outlined, color: Cores.principal),
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
          // Quem é: o rosto, o nome e onde fica, abertos no fundo da tela,
          // como o cabeçalho do "Meu perfil"
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
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Cores.texto,
                        height: 1.2,
                      ),
                    ),
                    if (endereco.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Cores.principal,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              endereco,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Cores.principal,
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
                backgroundColor: Cores.principal,
                foregroundColor: Colors.white,
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
          // Os animais logo depois de quem é a ONG: é por eles que a maioria
          // das pessoas abre o perfil
          // Uma seção por tipo, na ordem adoção, resgate e perdidos; tipo
          // sem animal não aparece
          if (animais.isEmpty) ...[
            const SizedBox(height: 26),
            const _TituloDaSecao('Animais da ONG'),
            const SizedBox(height: 10),
            const Text(
              'A ONG ainda não cadastrou nenhum animal.',
              style: TextStyle(fontSize: 14, color: Cores.textoFraco),
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
          // Só quem administra a ONG vê os membros e pode remover
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
                cor: Cores.principal,
                aoTocar: () => _abrirNoMapa(atual),
              ),
            ),
        ],
      ),
    );
  }
}

// A chave Pix numa faixa só, com o botão de copiar ao lado: o app só mostra
// a chave, a doação é feita no banco de quem doa
class _FaixaDoPix extends StatelessWidget {
  const _FaixaDoPix({required this.chave, required this.aoCopiar});

  final String chave;
  final VoidCallback aoCopiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Cores.principalClara,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.volunteer_activism_outlined,
            color: Cores.principal,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doe pelo Pix, no app do seu banco',
                  style: TextStyle(fontSize: 12, color: Cores.principal),
                ),
                const SizedBox(height: 2),
                Text(
                  chave,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Cores.texto,
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
              foregroundColor: Cores.principal,
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
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Cores.texto,
          ),
        ),
        if (quantidade != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Cores.principalClara,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$quantidade',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Cores.principal,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Os animais num carrossel de cards, que rola para o lado
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

// O card: a foto, o nome, o tipo com a situação e o bairro. O toque abre a
// ficha do animal
class _CartaoDoAnimal extends StatelessWidget {
  const _CartaoDoAnimal({required this.animal});

  final Animal animal;

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
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.details, arguments: animal),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A foto fica com o que sobrar da altura do card, para o texto
              // embaixo nunca estourar
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
                      style: const TextStyle(
                        color: Cores.textoFraco,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: Cores.principal),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  color: Cores.principal,
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

// Quem faz parte da ONG, para quem a administra: o nome, o telefone e o
// remover. A admin aparece primeiro e não pode ser removida
class _PessoasDaOng extends StatelessWidget {
  const _PessoasDaOng({required this.ong, this.servico});

  final Ong ong;
  final OngService? servico;

  Future<void> _remover(BuildContext context, PessoaDaOng pessoa) async {
    final confirmou = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Cores.cartao,
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
              const Text(
                'A pessoa deixa de publicar em nome da ONG e recebe um aviso. '
                'Os animais que ela já publicou continuam no perfil da ONG.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Cores.textoFraco,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(painel, false),
                style: FilledButton.styleFrom(
                  backgroundColor: Cores.principal,
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
                  foregroundColor: Cores.destaque,
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

  Widget _linha(String nome, String detalhe, {Widget? acao}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Cores.principalClara,
          child: Text(
            iniciaisDa(nome),
            style: const TextStyle(
              color: Cores.principal,
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
                  style: const TextStyle(fontSize: 13, color: Cores.textoFraco),
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
          (usuario?.nome.trim().isNotEmpty ?? false) ? usuario!.nome : 'Você',
          'Administra a ONG',
        ),
        for (final pessoa in ong.membros)
          _linha(
            pessoa.nome,
            formatarTelefone(pessoa.telefone),
            acao: TextButton(
              onPressed: () => _remover(context, pessoa),
              style: TextButton.styleFrom(
                foregroundColor: Cores.destaque,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('Remover'),
            ),
          ),
        if (ong.membros.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Ainda só você. Quem disser que faz parte da ONG aparece no '
              'sino de notificações para você aprovar.',
              style: TextStyle(fontSize: 13, color: Cores.textoFraco),
            ),
          ),
      ],
    );
  }
}
