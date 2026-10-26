// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo denuncia.dart: quandoFoi, a data da etapa em texto.
import '../modelos/denuncia.dart';
// Arquivo etapa_do_historico.dart: as etapas exibidas.
import '../modelos/etapa_do_historico.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Linha do tempo das mudanças de situação, da mais recente para a mais
// antiga: um ponto por etapa, ligado ao seguinte por uma linha, com a
// situação, a data, a observação e quem fez a mudança. [rotuloDe] converte o
// nome gravado da situação no texto exibido
class HistoricoDeSituacoes extends StatelessWidget {
  const HistoricoDeSituacoes({
    super.key,
    required this.etapas,
    required this.rotuloDe,
  });

  final List<EtapaDoHistorico> etapas;
  final String Function(String situacao) rotuloDe;

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final ordem = etapas.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < ordem.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ponto da etapa e a linha que desce até a próxima. A mais
                // recente tem o ponto cheio
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0
                              ? context.cores.principal
                              : context.cores.cartao,
                          border: Border.all(
                            color: context.cores.principal,
                            width: 2,
                          ),
                        ),
                      ),
                      if (i < ordem.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: context.cores.principalClara,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < ordem.length - 1 ? 16 : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rotuloDe(ordem[i].situacao),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.cores.texto,
                          ),
                        ),
                        Text(
                          [
                            quandoFoi(ordem[i].em, agora),
                            if (ordem[i].autor.trim().isNotEmpty)
                              'por ${ordem[i].autor.trim()}',
                          ].join(' '),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.cores.textoFraco,
                          ),
                        ),
                        if (ordem[i].observacao.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            ordem[i].observacao.trim(),
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: context.cores.texto,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
