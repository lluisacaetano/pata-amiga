import 'package:flutter/material.dart';

import '../tema/cores.dart';

// Protege um formulário: com algo mudado e não salvo, voltar (pela seta ou
// pelo botão do aparelho) pergunta antes de sair. Salvar continua saindo
// direto, porque as telas saem com Navigator.pop, que não passa por aqui.
// A mudança é conferida na hora de voltar, porque digitar num campo não
// redesenha a tela
class ProtegerAlteracoes extends StatelessWidget {
  final bool Function() alterado;
  final Widget child;

  const ProtegerAlteracoes({
    super.key,
    required this.alterado,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) async {
        if (saiu) return;
        final navegador = Navigator.of(context);
        if (!alterado() || await confirmarSaida(context)) navegador.pop();
      },
      child: child,
    );
  }
}

// O mesmo painel de baixo das outras confirmações do app. A ação segura é a
// principal: o botão cheio continua editando, e sair fica em coral
Future<bool> confirmarSaida(BuildContext context) async =>
    await showModalBottomSheet<bool>(
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
              const Text(
                'Sair sem salvar?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'O que você preencheu nesta tela será perdido.',
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
                child: const Text('Continuar editando'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(painel, true),
                style: TextButton.styleFrom(
                  foregroundColor: Cores.destaque,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Sair sem salvar'),
              ),
            ],
          ),
        ),
      ),
    ) ??
    false;
