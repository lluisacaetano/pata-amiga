// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo estado_pata_amiga.dart: estado global com as curtidas.
import '../estado/estado_pata_amiga.dart';
// Arquivo animal.dart: modelo do animal e o tipo do registro.
import '../modelos/animal.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo foto_animal.dart: foto do animal com a patinha de reserva.
import 'foto_animal.dart';

// Cartão de um animal no feed: foto, nome, resumo, local e tempo desde a
// publicação, seguidos das ações curtir, WhatsApp e compartilhar. O toque
// no cartão executa [aoTocar] (abrir os detalhes)
class CardAnimal extends StatelessWidget {
  final Animal animal;
  final VoidCallback aoCompartilhar;
  final VoidCallback aoChamarNoWhatsApp;
  final VoidCallback aoTocar;

  const CardAnimal({
    super.key,
    required this.animal,
    required this.aoCompartilhar,
    required this.aoChamarNoWhatsApp,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final curtido = estado.estaCurtido(animal.chave);

    // Material com InkWell: o toque no cartão mostra a ondulação e é lido
    // como botão pelo leitor de tela
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
          onTap: aoTocar,
          child: Padding(
            // Sem margem embaixo: as ações já têm 48 de altura
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, restricoes) => FotoAnimal(
                    caminho: animal.foto,
                    altura: restricoes.maxWidth,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  animal.nome.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  animal.resumo,
                  style: TextStyle(color: context.cores.textoFraco),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: context.cores.principal,
                    ),
                    const SizedBox(width: 4),
                    // O local encolhe com reticências para o tempo sempre caber
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
                    // Tempo desde a publicação, na mesma linha do local
                    Text(
                      ' · ${animal.publicadoHa(DateTime.now())}',
                      style: TextStyle(
                        color: context.cores.textoFraco,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                // Em perdidos e resgates, mostra as observações (até duas
                // linhas), que costumam dizer onde e quando o animal foi visto
                if (animal.tipo != TipoRegistro.adocao &&
                    animal.observacoes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    animal.observacoes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.cores.texto, fontSize: 13),
                  ),
                ],
                // Divisória entre as informações e as ações
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: context.cores.borda,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Acao(
                      icone: curtido ? Icons.favorite : Icons.favorite_border,
                      rotulo: 'curtir',
                      descricao: curtido
                          ? 'Descurtir ${animal.nome}'
                          : 'Curtir ${animal.nome}',
                      selecionada: curtido,
                      destacado: curtido,
                      aoTocar: () => estado.alternarCurtida(animal.chave),
                    ),
                    _Acao(
                      icone: Icons.chat_bubble_outline,
                      rotulo: 'WhatsApp',
                      descricao: 'Conversar no WhatsApp sobre ${animal.nome}',
                      aoTocar: aoChamarNoWhatsApp,
                    ),
                    _Acao(
                      icone: Icons.share_outlined,
                      rotulo: 'compartilhar',
                      descricao: 'Compartilhar ${animal.nome}',
                      aoTocar: aoCompartilhar,
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

// Ação do rodapé do cartão: ícone com rótulo, na cor principal quando ativa.
// A área de toque tem no mínimo 48 de altura e o leitor de tela anuncia
// [descricao] como botão; [selecionada] indica se a curtida está marcada
class _Acao extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String descricao;
  final bool selecionada;
  final bool destacado;
  final VoidCallback? aoTocar;

  const _Acao({
    required this.icone,
    required this.rotulo,
    required this.descricao,
    this.selecionada = false,
    this.destacado = false,
    this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = destacado ? context.cores.principal : context.cores.textoFraco;
    return Semantics(
      button: true,
      selected: selecionada,
      label: descricao,
      excludeSemantics: true,
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 18, color: cor),
                const SizedBox(width: 6),
                Text(rotulo, style: TextStyle(color: cor, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
