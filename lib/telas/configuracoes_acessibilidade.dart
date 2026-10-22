import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/preferencias_aplicativo_provider.dart';
import '../tema/cores.dart';

class ConfiguracoesAcessibilidade extends StatelessWidget {
  const ConfiguracoesAcessibilidade({super.key});

  Future<void> _salvar(
    BuildContext context,
    Future<void> Function() salvar,
  ) async {
    try {
      await salvar();
    } on Exception catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a configuração.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencias = context.watch<PreferenciasAplicativoProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Acessibilidade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tamanho do texto',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Ajuste a leitura em todo o aplicativo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: RadioGroup<TamanhoTexto>(
              groupValue: preferencias.tamanhoTexto,
              onChanged: (valor) {
                if (valor != null) {
                  _salvar(
                    context,
                    () => context
                        .read<PreferenciasAplicativoProvider>()
                        .definirTamanhoTexto(valor),
                  );
                }
              },
              child: Column(
                children: [
                  for (final opcao in TamanhoTexto.values)
                    RadioListTile<TamanhoTexto>(
                      value: opcao,
                      title: Text(switch (opcao) {
                        TamanhoTexto.normal => 'Normal',
                        TamanhoTexto.grande => 'Grande',
                        TamanhoTexto.extragrande => 'Extragrande',
                      }),
                      activeColor: context.cores.principal,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
