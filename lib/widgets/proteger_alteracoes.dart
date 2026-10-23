// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo painel_de_confirmacao.dart: painel inferior de confirmação.
import 'painel_de_confirmacao.dart';

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
        if (!alterado()) {
          navegador.pop();
          return;
        }
        final sair = await confirmarSaida(context);
        // A tela pode ter sido fechada enquanto o painel estava aberto
        if (sair && context.mounted) navegador.pop();
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
      builder: (painel) => PainelDeConfirmacao(
        titulo: 'Sair sem salvar?',
        texto: 'O que você preencheu nesta tela será perdido.',
        rotuloPrincipal: 'Continuar editando',
        aoPrincipal: () => Navigator.pop(painel, false),
        rotuloSecundario: 'Sair sem salvar',
        aoSecundario: () => Navigator.pop(painel, true),
        secundarioDeAlerta: true,
      ),
    ) ??
    false;
