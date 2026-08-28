import 'package:flutter/material.dart';

import '../modelos/animal.dart';
import '../tema/cores.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/foto_animal.dart';

String _rotuloTipo(TipoRegistro tipo) => switch (tipo) {
  TipoRegistro.adocao => 'Adoção',
  TipoRegistro.perdido => 'Perdido',
  TipoRegistro.resgate => 'Resgate',
};

String _comMaiuscula(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

const _especies = ['Cachorro', 'Gato'];
const _portes = ['pequeno', 'médio', 'grande'];
const _sexos = ['macho', 'fêmea'];

class CadastroAnimal extends StatefulWidget {
  const CadastroAnimal({super.key});

  @override
  State<CadastroAnimal> createState() => _CadastroAnimalState();
}

class _CadastroAnimalState extends State<CadastroAnimal> {
  TipoRegistro _tipo = TipoRegistro.adocao;
  String? _especie;
  String? _porte;
  String? _sexo;

  final _nome = TextEditingController();
  final _raca = TextEditingController();
  final _cor = TextEditingController();
  final _idade = TextEditingController();
  final _observacoes = TextEditingController();
  final _localizacao = TextEditingController();

  @override
  void dispose() {
    for (final campo in [
      _nome,
      _raca,
      _cor,
      _idade,
      _observacoes,
      _localizacao,
    ]) {
      campo.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        leadingWidth: 116,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Row(mainAxisSize: MainAxisSize.min, children: [_Marca()]),
        ),
        centerTitle: true,
        title: const Text(
          'Cadastrar animal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Cores.principal,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            color: Cores.texto,
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Cartao(child: _BlocoDeFotos()),
            _Cartao(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TituloDoCartao(icone: Icons.pets, texto: 'O animal'),
                  const SizedBox(height: 16),
                  const _Rotulo('Tipo'),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<TipoRegistro>(
                      segments: [
                        for (final opcao in TipoRegistro.values)
                          ButtonSegment(
                            value: opcao,
                            label: Text(_rotuloTipo(opcao)),
                          ),
                      ],
                      selected: {_tipo},
                      showSelectedIcon: false,
                      onSelectionChanged: (escolha) =>
                          setState(() => _tipo = escolha.single),
                      style: _estiloDoTipo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Campo(rotulo: 'Nome', controlador: _nome),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Selecao(
                          rotulo: 'Espécie',
                          opcoes: _especies,
                          valor: _especie,
                          aoEscolher: (escolha) =>
                              setState(() => _especie = escolha),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Selecao(
                          rotulo: 'Porte',
                          opcoes: _portes,
                          valor: _porte,
                          aoEscolher: (escolha) =>
                              setState(() => _porte = escolha),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Campo(
                          rotulo: 'Raça',
                          controlador: _raca,
                          exemplo: 'Sem raça definida',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Campo(
                          rotulo: 'Cor',
                          controlador: _cor,
                          exemplo: 'Caramelo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Campo(
                          rotulo: 'Idade',
                          controlador: _idade,
                          exemplo: '2 anos',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Selecao(
                          rotulo: 'Sexo',
                          opcoes: _sexos,
                          valor: _sexo,
                          aoEscolher: (escolha) =>
                              setState(() => _sexo = escolha),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Campo(
                    rotulo: 'Observações',
                    controlador: _observacoes,
                    exemplo: 'Temperamento, cuidados, onde foi visto',
                    linhas: 3,
                  ),
                ],
              ),
            ),
            _Cartao(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TituloDoCartao(
                    icone: Icons.location_on_outlined,
                    texto: 'Onde ele está',
                  ),
                  const SizedBox(height: 16),
                  _Campo(
                    rotulo: 'Localização',
                    controlador: _localizacao,
                    exemplo: 'Rua, Bairro e Cidade',
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Usar minha localização'),
                    style: _estiloDeAcao,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.pets, size: 18),
              label: const Text('Cadastrar'),
              style: FilledButton.styleFrom(
                backgroundColor: Cores.principal,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BarraInferior(),
    );
  }
}

final _estiloDeAcao = TextButton.styleFrom(
  foregroundColor: Cores.principal,
  padding: const EdgeInsets.symmetric(horizontal: 4),
  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
);

class _BlocoDeFotos extends StatelessWidget {
  const _BlocoDeFotos();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TituloDoCartao(
          icone: Icons.photo_camera_outlined,
          texto: 'Fotos',
        ),
        const SizedBox(height: 14),
        const FotoAnimal(caminho: '', altura: 140),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
          label: const Text('Adicionar fotos'),
          style: _estiloDeAcao,
        ),
      ],
    );
  }
}

final _estiloDoTipo = ButtonStyle(
  backgroundColor: WidgetStateProperty.resolveWith(
    (estados) =>
        estados.contains(WidgetState.selected) ? Cores.principal : Cores.fundo,
  ),
  foregroundColor: WidgetStateProperty.resolveWith(
    (estados) => estados.contains(WidgetState.selected)
        ? Colors.white
        : Cores.textoFraco,
  ),
  textStyle: const WidgetStatePropertyAll(
    TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  ),
  side: const WidgetStatePropertyAll(BorderSide(color: Cores.borda)),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

class _Cartao extends StatelessWidget {
  final Widget child;

  const _Cartao({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: child,
    );
  }
}

class _TituloDoCartao extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _TituloDoCartao({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 16, color: Cores.principal),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            color: Cores.principal,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

InputDecoration _caixa(String? exemplo) => InputDecoration(
  isDense: true,
  filled: true,
  fillColor: Cores.fundo,
  hintText: exemplo,
  hintStyle: const TextStyle(fontSize: 14, color: Cores.textoFraco),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Cores.borda),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Cores.principal, width: 1.5),
  ),
);

class _Campo extends StatelessWidget {
  final String rotulo;
  final TextEditingController controlador;
  final String? exemplo;
  final int linhas;

  const _Campo({
    required this.rotulo,
    required this.controlador,
    this.exemplo,
    this.linhas = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rotulo(rotulo),
        const SizedBox(height: 6),
        TextField(
          controller: controlador,
          maxLines: linhas,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 15),
          decoration: _caixa(exemplo),
        ),
      ],
    );
  }
}

class _Selecao extends StatelessWidget {
  final String rotulo;
  final List<String> opcoes;
  final String? valor;
  final ValueChanged<String?> aoEscolher;

  const _Selecao({
    required this.rotulo,
    required this.opcoes,
    required this.valor,
    required this.aoEscolher,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rotulo(rotulo),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isDense: true,
          decoration: _caixa(null),
          hint: const Text(
            'Escolher',
            style: TextStyle(fontSize: 14, color: Cores.textoFraco),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Cores.textoFraco),
          style: const TextStyle(fontSize: 15, color: Cores.texto),
          items: [
            for (final opcao in opcoes)
              DropdownMenuItem(value: opcao, child: Text(_comMaiuscula(opcao))),
          ],
          onChanged: aoEscolher,
        ),
      ],
    );
  }
}

class _Rotulo extends StatelessWidget {
  final String texto;

  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Cores.textoFraco,
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/marca/pata.png', width: 26),
        const SizedBox(width: 6),
        const Text(
          'PATA\nAMIGA',
          style: TextStyle(
            fontSize: 12,
            height: 1.1,
            fontWeight: FontWeight.bold,
            color: Cores.principal,
          ),
        ),
      ],
    );
  }
}
