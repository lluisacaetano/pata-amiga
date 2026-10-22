import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/dono.dart';
import '../modelos/ong.dart';
import '../services/ong_service.dart';
import '../routes/route_names.dart';
import '../tema/cores.dart';
import 'avatar_da_ong.dart';
import 'foto_animal.dart';
import 'mascaras.dart';

// As notificações que a pessoa ainda não resolveu: os pedidos das ONGs que
// ela administra e os avisos de que foi removida de uma ONG. Serve para
// saber quando chegou uma nova
Set<String> notificacoesPara(Iterable<Ong> ongs, String email) => {
  for (final ong in ongs) ...[
    if (ong.eDoResponsavel(email))
      for (final pessoa in ong.pedidos) 'pedido:${ong.id}:${pessoa.email}',
    if (ong.avisoPara(email) case final aviso?)
      'aviso:${ong.id}:${aviso.tipo.name}:${aviso.em}',
  ],
};

// Avisa que chegou notificação com o app aberto: uma vibração curta, além
// do contador do sino. As notificações ficam só dentro do app
Future<void> avisarNovaNotificacao() => HapticFeedback.vibrate();

// O sino do "Meu perfil", ao lado do sair: as notificações das ONGs. Quem
// criou uma ONG vê os pedidos para entrar, com aprovar e recusar, e o aviso
// quando a pessoa já faz parte de outra ONG. Quem pediu para entrar vê que o
// pedido aguarda resposta. Os avisos ficam aqui, e não em mensagens que somem
class SinoDeNotificacoes extends StatefulWidget {
  final String email;
  final OngService? servico;

  const SinoDeNotificacoes({super.key, required this.email, this.servico});

  @override
  State<SinoDeNotificacoes> createState() => _SinoDeNotificacoesState();
}

class _SinoDeNotificacoesState extends State<SinoDeNotificacoes> {
  late final _servico = widget.servico ?? OngService();

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  // Os pedidos chegam de outros aparelhos: ao abrir o perfil, busca de novo
  Future<void> _atualizar() async {
    try {
      final ongs = await _servico.buscarOngs();
      if (!mounted) return;
      PataAmigaScope.of(context).atualizarOngs(ongs);
    } on Exception {
      // fica com o que o app já tinha
    }
  }

  Ong? _minhaOng(EstadoPataAmiga estado) {
    final ong = estado.ongDe(widget.email);
    return ong != null && ong.eDoResponsavel(widget.email) ? ong : null;
  }

  // Desce do topo, logo abaixo do sino, como as notificações de qualquer
  // app; tocar fora fecha
  Future<void> _abrir() => showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar notificações',
    barrierColor: const Color(0x33000000),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (painel, _, _) => _ListaDePedidos(
      email: widget.email,
      servico: _servico,
      minhaOng: _minhaOng,
    ),
    transitionBuilder: (_, animacao, _, filho) => SlideTransition(
      position: Tween(
        begin: const Offset(0, -0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animacao, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: animacao, child: filho),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final ong = _minhaOng(estado);
    final pedida = estado.ongPedidaPor(widget.email);
    final avisos = estado.avisosPara(widget.email);
    if (ong == null && pedida == null && avisos.isEmpty) {
      return const SizedBox.shrink();
    }
    final quantos =
        (ong?.pedidos.length ?? 0) + (pedida != null ? 1 : 0) + avisos.length;
    return IconButton(
      tooltip: quantos == 0
          ? 'Notificações'
          : quantos == 1
          ? '1 notificação'
          : '$quantos notificações',
      onPressed: _abrir,
      icon: Badge(
        isLabelVisible: quantos > 0,
        label: Text('$quantos'),
        backgroundColor: context.cores.destaque,
        child: Icon(
          quantos > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_none,
          color: context.cores.principal,
        ),
      ),
    );
  }
}

class _ListaDePedidos extends StatefulWidget {
  const _ListaDePedidos({
    required this.email,
    required this.servico,
    required this.minhaOng,
  });

  final String email;
  final OngService servico;
  final Ong? Function(EstadoPataAmiga) minhaOng;

  @override
  State<_ListaDePedidos> createState() => _ListaDePedidosState();
}

class _ListaDePedidosState extends State<_ListaDePedidos> {
  // O e-mail do pedido que está sendo respondido, para travar os botões
  String? _respondendo;

  // O aviso de remoção some do sino de quem o viu
  Future<void> _dispensar(Ong ong) async {
    final estado = PataAmigaScope.of(context);
    try {
      estado.salvarOng(await widget.servico.dispensarAviso(ong, widget.email));
    } on Exception {
      // fica para a próxima vez
    }
  }

  Future<void> _responder(
    Ong ong,
    PessoaDaOng pessoa, {
    required bool aprovar,
  }) async {
    final estado = PataAmigaScope.of(context);
    final mensageiro = ScaffoldMessenger.of(context);
    setState(() => _respondendo = pessoa.email);
    String aviso;
    try {
      estado.salvarOng(
        await widget.servico.responderPedido(
          ong,
          pessoa.email,
          aprovar: aprovar,
        ),
      );
      aviso = aprovar
          ? '${pessoa.nome} agora faz parte de ${ong.nome}.'
          : 'Pedido de ${pessoa.nome} recusado.';
    } on PedidoNaoExiste {
      aviso = '${pessoa.nome} já não está esperando resposta.';
    } on JaFazParteDeOutra catch (erro) {
      aviso =
          '${pessoa.nome} já faz parte de ${erro.ong}. Cada conta pode ter só '
          'uma ONG.';
    } on Exception {
      aviso = 'Não foi possível responder agora. Tente de novo.';
    }
    if (mounted) setState(() => _respondendo = null);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(aviso)));
  }

  void _verPerfil(Ong ong, PessoaDaOng pessoa, Ong? outra) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: context.cores.cartao,
        showDragHandle: true,
        builder: (painel) => PerfilDeQuemPediu(
          pessoa: pessoa,
          ong: ong,
          outra: outra,
          // Decidir no perfil fecha o perfil e responde
          aoResponder: (aprovar) {
            Navigator.pop(painel);
            _responder(ong, pessoa, aprovar: aprovar);
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final ong = widget.minhaOng(estado);
    final pedida = estado.ongPedidaPor(widget.email);
    // A outra ONG de que a pessoa do pedido já faz parte, se houver
    Ong? outraDe(PessoaDaOng pessoa) => estado.ongs
        .where((outra) => outra.id != ong?.id && outra.fazParte(pessoa.email))
        .firstOrNull;
    // O próprio pedido, para saber quando foi feito
    final meuPedido = pedida?.pedidos
        .where(
          (pessoa) =>
              pessoa.email.trim().toLowerCase() ==
              widget.email.trim().toLowerCase(),
        )
        .firstOrNull;
    final agora = DateTime.now();
    // Tudo numa lista só, da mais nova para a mais antiga
    final notificacoes =
        <(DateTime?, Widget)>[
          if (ong != null)
            for (final pessoa in ong.pedidos)
              (
                pessoa.em,
                _Notificacao(
                  iniciais: iniciaisDa(pessoa.nome),
                  quando: pessoa.em,
                  agora: agora,
                  texto: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: pessoa.nome,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' quer fazer parte de ${ong.nome}.'),
                      ],
                    ),
                  ),
                  aviso: switch (outraDe(pessoa)) {
                    final outra? =>
                      'Já faz parte de ${outra.nome}. Cada conta pode ter só '
                          'uma ONG, então não dá para aprovar.',
                    null => null,
                  },
                  detalhe: 'Toque para ver o perfil.',
                  aoTocar: () => _verPerfil(ong, pessoa, outraDe(pessoa)),
                  acoes: [
                    const Spacer(),
                    TextButton(
                      onPressed: _respondendo != null
                          ? null
                          : () => _responder(ong, pessoa, aprovar: false),
                      style: _estiloDoTexto(context.cores.destaque),
                      child: const Text('Recusar'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: _respondendo != null || outraDe(pessoa) != null
                          ? null
                          : () => _responder(ong, pessoa, aprovar: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.cores.principal,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Aprovar'),
                    ),
                  ],
                ),
              ),
          // Os avisos das ONGs, com a foto da ONG, até a pessoa dispensar
          for (final (deOng, aviso) in estado.avisosPara(widget.email))
            (
              aviso.em,
              _Notificacao(
                avatar: AvatarDaOng(ong: deOng, raio: 18),
                quando: aviso.em,
                agora: agora,
                texto: Text(switch (aviso.tipo) {
                  TipoDeAviso.aprovado =>
                    'Seu pedido foi aprovado: você agora faz parte de '
                        '${deOng.nome}.',
                  TipoDeAviso.recusado =>
                    'Seu pedido para entrar em ${deOng.nome} não foi aprovado.',
                  TipoDeAviso.removido =>
                    'Você não faz mais parte de ${deOng.nome}.',
                }),
                detalhe: switch (aviso.tipo) {
                  TipoDeAviso.aprovado =>
                    'Já dá para publicar animais em nome da ONG.',
                  TipoDeAviso.recusado =>
                    'Você pode pedir para entrar em outra ONG pelo Editar '
                        'perfil.',
                  TipoDeAviso.removido =>
                    'Os animais que você publicou por ela continuam no '
                        'perfil da ONG.',
                },
                // O aprovado leva ao perfil da ONG
                aoTocar: aviso.tipo == TipoDeAviso.aprovado
                    ? () {
                        final navegador = Navigator.of(context);
                        _dispensar(deOng);
                        navegador
                          ..pop()
                          ..pushNamed(AppRoutes.perfilOng, arguments: deOng);
                      }
                    : null,
                acoes: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => _dispensar(deOng),
                    style: _estiloDoTexto(context.cores.principal),
                    child: const Text('Entendi'),
                  ),
                ],
              ),
            ),
          if (pedida != null)
            (
              meuPedido?.em,
              _Notificacao(
                icone: Icons.schedule,
                quando: meuPedido?.em,
                agora: agora,
                texto: Text(
                  'Seu pedido para entrar em ${pedida.nome} aguarda aprovação.',
                ),
                detalhe:
                    'Enquanto isso, não dá para criar outra ONG: cada conta pode '
                    'ter só uma.',
              ),
            ),
        ]..sort((a, b) {
          final ta = a.$1, tb = b.$1;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta);
        });

    final topo = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            topo - MediaQuery.paddingOf(context).top,
            12,
            0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 456,
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: Material(
              color: context.cores.cartao,
              elevation: 8,
              shadowColor: const Color(0x33000000),
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Text(
                      'Notificações',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (notificacoes.isEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(18, 4, 18, 20),
                      child: Text(
                        'Nenhuma notificação. Quando alguém disser que faz '
                        'parte da sua ONG, o pedido aparece aqui.',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.cores.textoFraco,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: notificacoes.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          indent: 70,
                          color: context.cores.borda,
                        ),
                        itemBuilder: (_, indice) => notificacoes[indice].$2,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static ButtonStyle _estiloDoTexto(Color cor) => TextButton.styleFrom(
    foregroundColor: cor,
    visualDensity: VisualDensity.compact,
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );
}

// Há quanto tempo, como nas notificações do celular
String haQuantoTempo(DateTime? quando, DateTime agora) {
  if (quando == null) return '';
  final passou = agora.difference(quando);
  if (passou.inMinutes < 1) return 'agora';
  if (passou.inMinutes < 60) return 'há ${passou.inMinutes} min';
  if (passou.inHours < 24) return 'há ${passou.inHours} h';
  if (passou.inDays == 1) return 'ontem';
  return 'há ${passou.inDays} dias';
}

// Uma notificação: quem (as iniciais, ou um ícone), o que aconteceu, há
// quanto tempo e, embaixo, o aviso e as ações
class _Notificacao extends StatelessWidget {
  const _Notificacao({
    this.avatar,
    this.iniciais,
    this.icone,
    required this.quando,
    required this.agora,
    required this.texto,
    this.detalhe,
    this.aviso,
    this.aoTocar,
    this.acoes = const [],
  });

  // A foto da ONG, quando a notificação é sobre ela
  final Widget? avatar;
  final String? iniciais;
  final IconData? icone;
  final DateTime? quando;
  final DateTime agora;
  final Widget texto;
  final String? detalhe;
  final String? aviso;
  // Tocar na notificação abre o que ela fala, como o perfil de quem pediu
  final VoidCallback? aoTocar;
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar ??
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.cores.principalClara,
                  child: icone != null
                      ? Icon(icone, color: context.cores.principal, size: 20)
                      : Text(
                          iniciais ?? '',
                          style: TextStyle(
                            color: context.cores.principal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(fontSize: 14, height: 1.35),
                          child: texto,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        haQuantoTempo(quando, agora),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.cores.textoFraco,
                        ),
                      ),
                    ],
                  ),
                  if (detalhe != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      detalhe!,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.cores.textoFraco,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (aviso != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.cores.destaque.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: context.cores.destaque,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              aviso!,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.cores.destaque,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (acoes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: acoes),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// O perfil de quem pediu para entrar, que é também onde se decide: quem é
// a pessoa, um jeito de conversar com ela antes e, no fim, recusar ou
// aprovar. A foto não aparece porque as contas ficam no aparelho de cada
// pessoa, e o e-mail fica de fora por não ajudar a decidir
class PerfilDeQuemPediu extends StatelessWidget {
  const PerfilDeQuemPediu({
    super.key,
    required this.pessoa,
    required this.ong,
    required this.aoResponder,
    this.outra,
  });

  final PessoaDaOng pessoa;
  final Ong ong;
  final void Function(bool aprovar) aoResponder;
  // A outra ONG de que a pessoa já faz parte: aí não dá para aprovar
  final Ong? outra;

  Future<void> _conversar(BuildContext context) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final numero = Dono(
      nome: pessoa.nome,
      telefone: pessoa.telefone,
    ).numeroNoWhatsApp;
    final texto = Uri.encodeComponent(
      'Olá, ${pessoa.nome}! Recebi no Pata Amiga o seu pedido para fazer '
      'parte de ${ong.nome}.',
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

  @override
  Widget build(BuildContext context) {
    final animais =
        PataAmigaScope.of(context).animais
            .where((animal) => animal.eDoResponsavel(pessoa.email))
            .toList()
          ..sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));
    final iniciais = iniciaisDa(pessoa.nome);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quem é, centralizado como no "Editar perfil"
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.cores.principalClara,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: context.cores.principalClara,
                  child: iniciais.isEmpty
                      ? Icon(
                          Icons.person_outline,
                          color: context.cores.principal,
                          size: 40,
                        )
                      : Text(
                          iniciais,
                          style: TextStyle(
                            color: context.cores.principal,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              pessoa.nome.isEmpty ? 'Sem nome' : pessoa.nome,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.cores.principalClara,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Pediu para entrar em ${ong.nome}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.cores.principal,
                  ),
                ),
              ),
            ),
            if (pessoa.telefone.isNotEmpty) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _conversar(context),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Conversar no WhatsApp'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.cores.principal,
                  side: BorderSide(color: context.cores.principal),
                  minimumSize: const Size.fromHeight(46),
                  shape: forma,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatarTelefone(pessoa.telefone),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.cores.textoFraco),
              ),
            ],
            // Os animais que a pessoa já publicou, em miniatura; sem nenhum,
            // a seção não aparece
            if (animais.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                animais.length == 1
                    ? '1 animal publicado'
                    : '${animais.length} animais publicados',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: animais.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, indice) => Tooltip(
                    message: animais[indice].nome,
                    child: SizedBox(
                      width: 64,
                      child: FotoAnimal(
                        caminho: animais[indice].foto,
                        altura: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (outra case final outra?) ...[
              const SizedBox(height: 16),
              Text(
                'Já faz parte de ${outra.nome}. Cada conta pode ter só uma '
                'ONG, então não dá para aprovar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.cores.destaque),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => aoResponder(false),
                    style: TextButton.styleFrom(
                      foregroundColor: context.cores.destaque,
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: outra != null ? null : () => aoResponder(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.cores.principal,
                      minimumSize: const Size.fromHeight(48),
                      shape: forma,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Aprovar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
