import 'package:flutter/material.dart';

import '../modelos/animal.dart';
import '../modelos/dono.dart';
import '../tema/cores.dart';

class CadastroAnimal extends StatefulWidget {
  const CadastroAnimal({super.key});

  @override
  State<CadastroAnimal> createState() => _CadastroAnimalState();
}

class _CadastroAnimalState extends State<CadastroAnimal> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _especieController = TextEditingController();
  final _racaController = TextEditingController();
  final _idadeController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController(text: 'Formiga');
  final _responsavelController = TextEditingController();
  final _telefoneController = TextEditingController();

  TipoRegistro _tipo = TipoRegistro.adocao;

  void _cadastrar() {
    if (!_formKey.currentState!.validate()) return;

    final animal = Animal(
      nome: _nomeController.text.trim(),
      especie: _especieController.text.trim(),
      raca: _racaController.text.trim(),
      sexo: 'não informado',
      porte: 'não informado',
      idade: _idadeController.text.trim().isEmpty
          ? 'não informada'
          : _idadeController.text.trim(),
      peso: '',
      cor: '',
      bairro: _bairroController.text.trim(),
      cidade: _cidadeController.text.trim(),
      tipo: _tipo,
      dono: Dono(
        nome: _responsavelController.text.trim(),
        telefone: _telefoneController.text.trim(),
      ),
      publicadoEm: DateTime.now(),
    );

    Navigator.pop(context, animal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar animal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Informações do animal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _campo('Nome', _nomeController),
            _campo('Espécie', _especieController),
            _campo('Raça', _racaController),
            _campo('Idade (opcional)', _idadeController, obrigatorio: false),
            _campo('Bairro', _bairroController),
            _campo('Cidade', _cidadeController),
            const SizedBox(height: 8),
            const Text(
              'Tipo de registro',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TipoRegistro>(
              segments: const [
                ButtonSegment(
                  value: TipoRegistro.adocao,
                  label: Text('Adoção'),
                ),
                ButtonSegment(
                  value: TipoRegistro.perdido,
                  label: Text('Perdido'),
                ),
                ButtonSegment(
                  value: TipoRegistro.resgate,
                  label: Text('Resgate'),
                ),
              ],
              selected: {_tipo},
              showSelectedIcon: false,
              onSelectionChanged: (selecionados) {
                setState(() => _tipo = selecionados.first);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Contato responsável',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _campo('Nome do responsável', _responsavelController),
            _campo(
              'Telefone/WhatsApp',
              _telefoneController,
              teclado: TextInputType.phone,
              validarTelefone: true,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _cadastrar,
              icon: const Icon(Icons.check),
              label: const Text('Publicar no feed'),
              style: FilledButton.styleFrom(
                backgroundColor: context.cores.principal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(
    String rotulo,
    TextEditingController controller, {
    bool obrigatorio = true,
    TextInputType teclado = TextInputType.text,
    bool validarTelefone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: ValueKey('cadastro-animal-$rotulo'),
        controller: controller,
        keyboardType: teclado,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: rotulo,
          border: const OutlineInputBorder(),
        ),
        validator: (valor) {
          final texto = valor?.trim() ?? '';
          if (obrigatorio && texto.isEmpty) return 'Preencha este campo.';
          if (validarTelefone) {
            final digitos = texto.replaceAll(RegExp(r'\D'), '');
            if (digitos.length < 10 || digitos.length > 11) {
              return 'Digite um telefone com DDD válido.';
            }
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _especieController.dispose();
    _racaController.dispose();
    _idadeController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _responsavelController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }
}

// ============================================
// CUSTOM PAINTERS
// ============================================

class PawPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Centro
    canvas.drawCircle(Offset(centerX, centerY), 6, paint);

    // Dedos
    final fingerRadius = 3.5;
    final fingerDistance = 10.0;

    canvas.drawCircle(
      Offset(centerX, centerY - fingerDistance),
      fingerRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX, centerY + fingerDistance),
      fingerRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX - fingerDistance, centerY),
      fingerRadius,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX + fingerDistance, centerY),
      fingerRadius,
      paint,
    );
  }

  @override
  bool shouldRepaint(PawPainter oldDelegate) => false;
}
