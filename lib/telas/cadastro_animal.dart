import 'package:flutter/material.dart';
import '../modelos/animal.dart';
import '../tema/cores.dart';
import '../widgets/chip_filtro.dart';

class CadastroAnimal extends StatefulWidget {
  const CadastroAnimal({super.key});

  @override
  State<CadastroAnimal> createState() => _CadastroAnimalState();
}

class _CadastroAnimalState extends State<CadastroAnimal> {
  final _formulario = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _raca = TextEditingController();
  final _idade = TextEditingController();
  final _porte = TextEditingController();
  final _cor = TextEditingController();
  final _sexo = TextEditingController();
  final _observacoes = TextEditingController();
  final _localizacao = TextEditingController();

  TipoRegistro _tipo = TipoRegistro.adocao;

  @override
  void dispose() {
    _nome.dispose();
    _raca.dispose();
    _idade.dispose();
    _porte.dispose();
    _cor.dispose();
    _sexo.dispose();
    _observacoes.dispose();
    _localizacao.dispose();
    super.dispose();
  }

  void _cadastrar() {
    if (!_formulario.currentState!.validate()) return;
    Navigator.pop(
      context,
      Animal(
        nome: _nome.text.trim(),
        especie: '',
        raca: _raca.text.trim(),
        sexo: _sexo.text.trim(),
        porte: _porte.text.trim(),
        idade: _idade.text.trim(),
        peso: '',
        cor: _cor.text.trim(),
        cidade: _localizacao.text.trim(),
        tipo: _tipo,
        observacoes: _observacoes.text.trim(),
        responsavel: '',
        telefone: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        title: const Text(
          'PATA AMIGA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Cores.principal,
          ),
        ),
      ),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Center(
              child: Text(
                'CADASTRAR ANIMAL',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final tipo in TipoRegistro.values) ...[
                  ChipFiltro(
                    rotulo: tipo == TipoRegistro.perdido
                        ? 'perdido'
                        : tipo.rotulo,
                    selecionado: _tipo == tipo,
                    aoTocar: () => setState(() => _tipo = tipo),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _AreaFotos(
              aoTocar: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        'O envio de fotos entra em uma próxima sprint.',
                      ),
                    ),
                  );
              },
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CampoTexto(
                    rotulo: 'NOME',
                    controlador: _nome,
                    obrigatorio: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CampoTexto(
                    rotulo: 'PORTE',
                    controlador: _porte,
                    obrigatorio: true,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CampoTexto(rotulo: 'RAÇA', controlador: _raca),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CampoTexto(rotulo: 'COR', controlador: _cor),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CampoTexto(rotulo: 'IDADE', controlador: _idade),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CampoTexto(rotulo: 'SEXO', controlador: _sexo),
                ),
              ],
            ),
            _CampoTexto(
              rotulo: 'OBS',
              controlador: _observacoes,
              linhas: 3,
            ),
            _CampoTexto(
              rotulo: 'LOCALIZAÇÃO',
              controlador: _localizacao,
              obrigatorio: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _cadastrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Cores.principal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('CADASTRAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaFotos extends StatelessWidget {
  final VoidCallback aoTocar;

  const _AreaFotos({required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTocar,
      child: Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Cores.cartao,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Cores.borda),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Cores.textoFraco),
            SizedBox(height: 8),
            Text('ADICIONAR FOTOS', style: TextStyle(color: Cores.textoFraco)),
          ],
        ),
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final String rotulo;
  final TextEditingController controlador;
  final bool obrigatorio;
  final int linhas;

  const _CampoTexto({
    required this.rotulo,
    required this.controlador,
    this.obrigatorio = false,
    this.linhas = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$rotulo:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          TextFormField(
            controller: controlador,
            maxLines: linhas,
            validator: (valor) {
              if (!obrigatorio) return null;
              return (valor == null || valor.trim().isEmpty)
                  ? 'Preencha este campo'
                  : null;
            },
            decoration: const InputDecoration(isDense: true),
          ),
        ],
      ),
    );
  }
}
