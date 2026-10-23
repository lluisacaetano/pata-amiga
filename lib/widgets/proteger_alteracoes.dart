// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Envolve um formulário e pede confirmação ao voltar (seta ou botão do
// aparelho) quando há alterações não salvas. [alterado] é consultado no
// momento da volta, pois digitar não reconstrói a tela. Salvar não passa por
// aqui, porque a tela fecha com Navigator.pop
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

// Painel inferior "Sair sem salvar?". Devolve true se a pessoa confirmar a
// saída. A ação segura (continuar editando) é o botão principal; sair fica
// como botão de texto na cor de destaque
Future<bool> confirmarSaida(BuildContext context) async =>
    await showModalBottomSheet<bool>(
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
              const Text(
                'Sair sem salvar?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'O que você preencheu nesta tela será perdido.',
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
                child: const Text('Continuar editando'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(painel, true),
                style: TextButton.styleFrom(
                  foregroundColor: context.cores.destaque,
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
