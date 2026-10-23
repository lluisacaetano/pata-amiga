// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Aviso de lista vazia ou de erro: ícone num círculo, título, explicação e,
// se houver, uma ação. Fica centralizado no espaço em que é colocado
class AvisoNoCentro extends StatelessWidget {
  const AvisoNoCentro({
    super.key,
    required this.icone,
    required this.titulo,
    this.texto,
    this.acao,
    this.aoAgir,
    this.acaoEmDestaque = false,
  });

  final IconData icone;
  final String titulo;
  final String? texto;
  // Rótulo do botão; o botão só aparece com rótulo e ação
  final String? acao;
  final VoidCallback? aoAgir;
  // Botão cheio para a ação principal (como tentar de novo); senão, botão
  // de texto
  final bool acaoEmDestaque;

  @override
  Widget build(BuildContext context) {
    final acao = this.acao;
    final aoAgir = this.aoAgir;
    final texto = this.texto;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            if (texto != null) ...[
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
            ],
            if (acao != null && aoAgir != null) ...[
              const SizedBox(height: 18),
              if (acaoEmDestaque)
                FilledButton(
                  onPressed: aoAgir,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.cores.principal,
                    foregroundColor: context.sobrePrincipal,
                  ),
                  child: Text(acao),
                )
              else
                TextButton(
                  onPressed: aoAgir,
                  style: TextButton.styleFrom(
                    foregroundColor: context.cores.principal,
                  ),
                  child: Text(
                    acao,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// Lista rolável com um topo fixo (busca, abas) e, abaixo dele, os itens ou
// um aviso. O aviso ocupa o espaço que sobra da tela e fica no centro dele.
// A rolagem é sempre ativa, para o puxar para atualizar funcionar vazia
class ListaComAviso extends StatelessWidget {
  const ListaComAviso({
    super.key,
    this.topo = const [],
    this.itens = const [],
    this.aviso,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  final List<Widget> topo;
  final List<Widget> itens;
  // Quando não é nulo, aparece no lugar dos itens
  final Widget? aviso;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final aviso = this.aviso;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: padding.copyWith(bottom: 0),
          sliver: SliverList(delegate: SliverChildListDelegate(topo)),
        ),
        if (aviso != null)
          SliverFillRemaining(hasScrollBody: false, child: aviso)
        else
          SliverPadding(
            padding: padding.copyWith(top: 0),
            sliver: SliverList(delegate: SliverChildListDelegate(itens)),
          ),
      ],
    );
  }
}
