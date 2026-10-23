// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo preferencias_aplicativo_provider.dart: tema escolhido.
import '../provider/preferencias_aplicativo_provider.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Tela de aparência: tema claro, escuro ou o do sistema. Cada opção mostra
// uma miniatura da tela no tema correspondente
class ConfiguracoesAparencia extends StatelessWidget {
  const ConfiguracoesAparencia({super.key});

  // Executa a gravação e avisa com um SnackBar se ela falhar
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
    final escolhido = preferencias.tema;
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
          'APARÊNCIA',
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
                Text(
                  'Escolha como o Pata Amiga aparece no seu celular.',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.cores.textoFraco,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final opcao in PreferenciaTema.values) ...[
                      if (opcao != PreferenciaTema.values.first)
                        const SizedBox(width: 10),
                      Expanded(
                        child: _OpcaoDeTema(
                          opcao: opcao,
                          escolhida: opcao == escolhido,
                          aoTocar: () => _salvar(
                            context,
                            () => context
                                .read<PreferenciasAplicativoProvider>()
                                .definirTema(opcao),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  switch (escolhido) {
                    PreferenciaTema.claro => 'Usa sempre a aparência clara.',
                    PreferenciaTema.escuro => 'Usa sempre a aparência escura.',
                    PreferenciaTema.sistema =>
                      'Acompanha a configuração do celular.',
                  },
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cores.textoFraco,
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

// Uma opção de tema: a miniatura, o nome e a marca de escolhida
class _OpcaoDeTema extends StatelessWidget {
  const _OpcaoDeTema({
    required this.opcao,
    required this.escolhida,
    required this.aoTocar,
  });

  final PreferenciaTema opcao;
  final bool escolhida;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final nome = switch (opcao) {
      PreferenciaTema.claro => 'Modo claro',
      PreferenciaTema.escuro => 'Modo escuro',
      PreferenciaTema.sistema => 'Seguir sistema',
    };
    return Semantics(
      button: true,
      selected: escolhida,
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: escolhida
                          ? context.cores.principal
                          : context.cores.borda,
                      width: escolhida ? 2.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 0.62,
                      child: switch (opcao) {
                        PreferenciaTema.claro => const _Miniatura(
                          escura: false,
                        ),
                        PreferenciaTema.escuro => const _Miniatura(
                          escura: true,
                        ),
                        // Metade clara e metade escura, cortadas na diagonal
                        PreferenciaTema.sistema => const Stack(
                          fit: StackFit.expand,
                          children: [
                            _Miniatura(escura: false),
                            ClipPath(
                              clipper: _Diagonal(),
                              child: _Miniatura(escura: true),
                            ),
                          ],
                        ),
                      },
                    ),
                  ),
                ),
                if (escolhida)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: context.cores.principal,
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: context.sobrePrincipal,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              nome,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: escolhida ? FontWeight.w700 : FontWeight.w500,
                color: escolhida
                    ? context.cores.principal
                    : context.cores.texto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Miniatura de uma tela do app (fundo, barra verde, cartão com foto e duas
// linhas de texto) nas cores do tema claro ou escuro
class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.escura});

  final bool escura;

  @override
  Widget build(BuildContext context) {
    final fundo = escura ? const Color(0xFF101510) : Cores.fundo;
    final cartao = escura ? const Color(0xFF1C241E) : Cores.cartao;
    final principal = escura ? const Color(0xFF8DCEA0) : Cores.principal;
    final linha = escura ? const Color(0xFF59645B) : Cores.borda;
    return Container(
      color: fundo,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            width: 34,
            decoration: BoxDecoration(
              color: principal,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cartao,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: linha, width: 0.6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: principal.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(height: 4, width: 40, color: principal),
                  const SizedBox(height: 4),
                  Container(height: 4, width: 26, color: linha),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Recorte triangular da metade inferior direita, usado na opção "sistema"
class _Diagonal extends CustomClipper<Path> {
  const _Diagonal();

  @override
  Path getClip(Size tamanho) => Path()
    ..moveTo(tamanho.width, 0)
    ..lineTo(tamanho.width, tamanho.height)
    ..lineTo(0, tamanho.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> antigo) => false;
}
