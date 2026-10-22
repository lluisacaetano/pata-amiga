import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/preferencias_aplicativo_provider.dart';
import '../tema/cores.dart';

class ConfiguracoesAparencia extends StatelessWidget {
  const ConfiguracoesAparencia({super.key});

  Future<void> _salvar(
    BuildContext context,
    Future<void> Function() salvar,
  ) async {
    try {
      await salvar();
    } on Exception catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a aparência.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencias = context.watch<PreferenciasAplicativoProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Aparência')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Escolha como o Pata Amiga deve aparecer no seu dispositivo.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: RadioGroup<PreferenciaTema>(
              groupValue: preferencias.tema,
              onChanged: (valor) {
                if (valor != null) {
                  _salvar(
                    context,
                    () => context
                        .read<PreferenciasAplicativoProvider>()
                        .definirTema(valor),
                  );
                }
              },
              child: Column(
                children: [
                  for (final opcao in PreferenciaTema.values)
                    RadioListTile<PreferenciaTema>(
                      value: opcao,
                      title: Text(switch (opcao) {
                        PreferenciaTema.claro => 'Modo claro',
                        PreferenciaTema.escuro => 'Modo escuro',
                        PreferenciaTema.sistema => 'Seguir sistema',
                      }),
                      subtitle: Text(switch (opcao) {
                        PreferenciaTema.claro =>
                          'Usa sempre a aparência clara.',
                        PreferenciaTema.escuro =>
                          'Usa sempre a aparência escura.',
                        PreferenciaTema.sistema =>
                          'Acompanha a configuração do dispositivo.',
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
