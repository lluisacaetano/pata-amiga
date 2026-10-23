// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo preferencias_aplicativo_provider.dart: tamanho do texto.
import '../provider/preferencias_aplicativo_provider.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo escolha_de_tipo.dart: estilo das abas de escolha usado no seletor.
import '../widgets/escolha_de_tipo.dart';

// Tela de acessibilidade: escolha do tamanho do texto do app inteiro, com
// um exemplo que já aparece no tamanho escolhido
class ConfiguracoesAcessibilidade extends StatelessWidget {
  const ConfiguracoesAcessibilidade({super.key});

  @override
  Widget build(BuildContext context) {
    final preferencias = context.watch<PreferenciasAplicativoProvider>();
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
          'ACESSIBILIDADE',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
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
                    Icon(
                      Icons.text_fields,
                      size: 18,
                      color: context.cores.principal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tamanho do texto',
                      style: TextStyle(
                        color: context.cores.principal,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Vale para o aplicativo inteiro.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cores.textoFraco,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TamanhoTexto>(
                    segments: [
                      for (final opcao in TamanhoTexto.values)
                        ButtonSegment(
                          value: opcao,
                          label: Text(
                            switch (opcao) {
                              TamanhoTexto.normal => 'Normal',
                              TamanhoTexto.grande => 'Grande',
                              TamanhoTexto.extragrande => 'Extragrande',
                            },
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    selected: {preferencias.tamanhoTexto},
                    showSelectedIcon: false,
                    onSelectionChanged: (escolha) => salvarPreferencia(
                      context,
                      () => context
                          .read<PreferenciasAplicativoProvider>()
                          .definirTamanhoTexto(escolha.first),
                      mensagemDeErro: 'Não foi possível salvar a configuração.',
                    ),
                    style: estiloDasAbas(context, context.cores.fundo),
                  ),
                ),
                const SizedBox(height: 16),
                // A escala vale para o app inteiro, então o exemplo já
                // aparece no tamanho escolhido
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cores.fundo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXEMPLO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: context.cores.textoFraco,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Thor tem 2 anos e adora brincar no quintal.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: context.cores.texto,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
