// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Conteúdo padrão dos painéis inferiores de confirmação: ícone opcional,
// título, explicação, um botão principal preenchido e um botão de texto.
// [secundarioDeAlerta] pinta o botão de texto na cor de destaque, para
// quando ele é a ação que descarta algo (como sair sem salvar)
class PainelDeConfirmacao extends StatelessWidget {
  const PainelDeConfirmacao({
    super.key,
    required this.titulo,
    required this.texto,
    required this.rotuloPrincipal,
    required this.aoPrincipal,
    required this.rotuloSecundario,
    required this.aoSecundario,
    this.icone,
    this.iconeDoPrincipal,
    this.secundarioDeAlerta = false,
  });

  final String titulo;
  final String texto;
  final String rotuloPrincipal;
  final VoidCallback aoPrincipal;
  final String rotuloSecundario;
  final VoidCallback aoSecundario;
  final IconData? icone;
  final IconData? iconeDoPrincipal;
  final bool secundarioDeAlerta;

  @override
  Widget build(BuildContext context) {
    final estiloDoPrincipal = FilledButton.styleFrom(
      backgroundColor: context.cores.principal,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    final iconeDoPrincipal = this.iconeDoPrincipal;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icone != null) ...[
              Icon(icone, size: 40, color: context.cores.principal),
              const SizedBox(height: 10),
            ],
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.cores.textoFraco,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (iconeDoPrincipal == null)
              FilledButton(
                onPressed: aoPrincipal,
                style: estiloDoPrincipal,
                child: Text(rotuloPrincipal),
              )
            else
              FilledButton.icon(
                onPressed: aoPrincipal,
                icon: Icon(iconeDoPrincipal, size: 18),
                label: Text(rotuloPrincipal),
                style: estiloDoPrincipal,
              ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: aoSecundario,
              style: TextButton.styleFrom(
                foregroundColor: secundarioDeAlerta
                    ? context.cores.destaque
                    : context.cores.textoFraco,
                textStyle: secundarioDeAlerta
                    ? const TextStyle(fontWeight: FontWeight.w600)
                    : null,
              ),
              child: Text(rotuloSecundario),
            ),
          ],
        ),
      ),
    );
  }
}
