// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';

// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

/// Conteúdo de uma página do carrossel de apresentação.
class OnboardingPage {
  final String title;
  final String description;
  // Ícone exibido quando não há imagem ou ela falha ao carregar
  final IconData icon;
  final String? imageAsset;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    this.imageAsset,
  });
}

/// Guarda no aparelho se a apresentação já foi vista, para exibi-la só na
/// primeira entrada.
class OnboardingStorage {
  static const _key = 'onboarding_visto';

  static Future<bool> jaViu() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> marcarComoVisto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

/// Destino depois do login ou do cadastro: a apresentação na primeira vez e o
/// feed nas seguintes. Limpa a pilha para que o voltar não retorne ao login.
Future<void> navegarAposAutenticacao(BuildContext context) async {
  final jaViu = await OnboardingStorage.jaViu();
  if (!context.mounted) return;

  final destino = jaViu ? AppRoutes.feed : AppRoutes.onboarding;
  Navigator.of(context).pushNamedAndRemoveUntil(destino, (_) => false);
}

/// Carrossel de apresentação do app, com indicador de página e opção de pular.
class OnboardingScreen extends StatefulWidget {
  /// Chamado ao concluir ou pular a apresentação.
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _paginas = [
    OnboardingPage(
      title: 'Bem-vindo ao Pata Amiga',
      description: 'Encontre e ajude animais que precisam de um lar.',
      icon: Icons.pets,
      imageAsset: 'assets/desenhos/carrosel_boas_vindas.png',
    ),
    OnboardingPage(
      title: 'Cadastre animais',
      description: 'Registre animais resgatados com fotos e informações.',
      icon: Icons.add_a_photo_outlined,
      imageAsset: 'assets/desenhos/carrosel_gat_cac.png',
    ),
    OnboardingPage(
      title: 'Adote com carinho',
      description:
          'Fale com os responsáveis pelo WhatsApp e encontre seu novo amigo.',
      icon: Icons.favorite_border,
      imageAsset: 'assets/desenhos/carrosel_boas.png',
    ),
  ];

  final _controller = PageController();
  int _paginaAtual = 0;

  bool get _ehUltima => _paginaAtual == _paginas.length - 1;

  // Registra que a apresentação foi vista antes de seguir adiante
  Future<void> _finalizar() async {
    await OnboardingStorage.marcarComoVisto();
    if (mounted) widget.onFinish();
  }

  // Avança uma página ou conclui na última; sem animação quando o sistema
  // pede movimento reduzido
  void _proxima() {
    if (_ehUltima) {
      _finalizar();
    } else if (MediaQuery.disableAnimationsOf(context)) {
      _controller.nextPage(duration: Duration.zero, curve: Curves.linear);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    context.cores.fundo,
                    context.cores.principalClara,
                    const Color(0xFF253329),
                  ]
                : [
                    const Color(0xFFBFDCC8),
                    const Color(0xFFDCEBDD),
                    const Color(0xFFF2F5EE),
                    const Color(0xFFFFF1E5),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finalizar,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(96, 56),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: Text(
                    'Pular',
                    style: TextStyle(
                      color: context.cores.principal,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _paginas.length,
                  onPageChanged: (i) => setState(() => _paginaAtual = i),
                  itemBuilder: (_, i) => _PaginaView(pagina: _paginas[i]),
                ),
              ),
              // Indicador de página: a atual aparece alongada
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_paginas.length, (i) {
                  final ativa = i == _paginaAtual;
                  return AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: ativa ? 24 : 8,
                    decoration: BoxDecoration(
                      color: ativa
                          ? context.cores.principal
                          : context.cores.borda,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _proxima,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.cores.principal,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_ehUltima ? 'Começar' : 'Próximo'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Uma página do carrossel: ilustração, título e descrição
class _PaginaView extends StatelessWidget {
  final OnboardingPage pagina;
  const _PaginaView({required this.pagina});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (pagina.imageAsset != null)
              Image.asset(
                pagina.imageAsset!,
                height: 240,
                fit: BoxFit.contain,
                // Sem o arquivo da imagem, mostra o ícone da página
                errorBuilder: (_, _, _) => Icon(
                  pagina.icon,
                  size: 140,
                  color: context.cores.principal,
                ),
              )
            else
              Icon(pagina.icon, size: 140, color: context.cores.principal),
            const SizedBox(height: 40),
            Text(
              pagina.title,
              textAlign: TextAlign.center,
              // Tamanho que mantém o título em até duas linhas num celular
              // estreito
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 34,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              pagina.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: context.cores.textoFraco),
            ),
          ],
        ),
      ),
    );
  }
}
