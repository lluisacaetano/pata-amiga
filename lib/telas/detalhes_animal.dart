import 'package:flutter/material.dart';
import '../modelos/animal.dart';
import '../tema/cores.dart';
import '../widgets/foto_animal.dart';

class DetalhesAnimal extends StatelessWidget {
  final Animal animal;

  const DetalhesAnimal({super.key, required this.animal});

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          FotoAnimal(caminho: animal.foto, altura: 240),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  animal.nome.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Cores.principalClara,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  animal.status.rotulo,
                  style: const TextStyle(
                    color: Cores.principal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _Campo(rotulo: 'ESPÉCIE', valor: animal.especie),
                    _Campo(rotulo: 'RAÇA', valor: animal.raca),
                    _Campo(rotulo: 'IDADE', valor: animal.idade),
                    _Campo(rotulo: 'COR', valor: animal.cor),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _Campo(rotulo: 'PORTE', valor: animal.porte),
                    _Campo(rotulo: 'SEXO', valor: animal.sexo),
                    _Campo(rotulo: 'PESO', valor: animal.peso),
                    _Campo(rotulo: 'CIDADE', valor: animal.cidade),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (animal.castrado) const _Selo('castrado'),
              if (animal.vacinado) const _Selo('vacinado'),
              if (animal.vermifugado) const _Selo('vermifugado'),
            ],
          ),
          const SizedBox(height: 16),
          if (animal.observacoes.isNotEmpty)
            _Campo(rotulo: 'OBS', valor: animal.observacoes),
          _Campo(rotulo: 'RESPONSÁVEL', valor: animal.responsavel),
          _Campo(rotulo: 'TELEFONE', valor: animal.telefone),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Cores.principal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('CONVERSAR NO WHATSAPP'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _Campo({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$rotulo:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(color: Cores.textoFraco)),
          const Divider(height: 12, color: Cores.borda),
        ],
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  final String rotulo;

  const _Selo(this.rotulo);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Text(rotulo, style: const TextStyle(fontSize: 13)),
    );
  }
}
