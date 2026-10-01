import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes/route_names.dart';

/// Modelo de cada página do carrossel.
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon; // usado se não houver imagem
  final String? imageAsset;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    this.imageAsset,
  });
}

/// Controle de "primeira vez": salva no aparelho que o onboarding já foi visto.
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

/// Chame depois de um login/cadastro bem-sucedido.
/// 1ª vez -> onboarding; depois -> feed.
Future<void> navegarAposAutenticacao(BuildContext context) async {
  final jaViu = await OnboardingStorage.jaViu();
  if (!context.mounted) return;

  final destino = jaViu ? AppRoutes.feed : AppRoutes.onboarding;
  Navigator.of(context).pushNamedAndRemoveUntil(destino, (_) => false);
}

class OnboardingScreen extends StatefulWidget {
  /// Chamado ao terminar ou pular (ex: ir para o feed).
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _verde = Color(0xFF2E7D5B);

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
      description: 'Converse com os responsáveis e encontre seu novo amigo.',
      icon: Icons.favorite_border,
      imageAsset: 'assets/desenhos/carrosel_boas.png',
    ),
  ];

  final _controller = PageController();
  int _paginaAtual = 0;

  bool get _ehUltima => _paginaAtual == _paginas.length - 1;

  Future<void> _finalizar() async {
    await OnboardingStorage.marcarComoVisto();
    if (mounted) widget.onFinish();
  }

  void _proxima() {
    if (_ehUltima) {
      _finalizar();
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFBFDCC8),
              Color(0xFFDCEBDD),
              Color(0xFFF2F5EE),
              Color(0xFFFFF1E5),
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
                  child: const Text(
                    'Pular',
                    style: TextStyle(
                      color: _verde,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_paginas.length, (i) {
                  final ativa = i == _paginaAtual;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: ativa ? 24 : 8,
                    decoration: BoxDecoration(
                      color: ativa ? _verde : Colors.grey.shade300,
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
                      backgroundColor: _verde,
                      foregroundColor: Colors.white,
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
                // Se o arquivo não existir, mostra o ícone em vez de quebrar.
                errorBuilder: (_, __, ___) => Icon(
                  pagina.icon,
                  size: 140,
                  color: const Color(0xFF2E7D5B),
                ),
              )
            else
              Icon(pagina.icon, size: 140, color: const Color(0xFF2E7D5B)),
            const SizedBox(height: 40),
            Text(
              pagina.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 50,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              pagina.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
