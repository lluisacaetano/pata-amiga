import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../modelos/dono.dart';
import '../tema/cores.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/cuidado.dart';
import '../widgets/escolha_de_tipo.dart';
import '../widgets/galeria_animal.dart';
import '../widgets/etiqueta.dart';

class DetalhesAnimal extends StatelessWidget {
  final Animal animal;

  const DetalhesAnimal({super.key, required this.animal});

  // monta o link do whatsApp e tenta abrir; se não conseguir, avisa na tela
  Future<void> _chamarNoWhatsApp(BuildContext context) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final texto = Uri.encodeComponent(
      'Olá! Vi ${animal.nome} no Pata Amiga e queria saber mais.',
    );
    final endereco = Uri.parse(
      'https://wa.me/${animal.dono.numeroNoWhatsApp}?text=$texto',
    );

    final abriu = await launchUrl(
      endereco,
      mode: LaunchMode.externalApplication,
    );
    if (!abriu) {
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o WhatsApp neste aparelho.'),
            duration: Duration(seconds: 3),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final estaCurtido = estado.estaCurtido(animal.nome);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Cores.fundo,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            color: Cores.principal,
            onPressed: () => Navigator.maybePop(context, animal),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'DETALHES',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Cores.principal,
          ),
        ),
        actions: [
          IconButton(
            tooltip: estaCurtido
                ? 'Remover dos curtidos'
                : 'Adicionar aos curtidos',
            onPressed: () => estado.alternarCurtida(animal.nome),
            icon: Icon(estaCurtido ? Icons.favorite : Icons.favorite_border),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GaleriaAnimal(fotos: animal.fotos, altura: 280),
            const SizedBox(height: 12),
            _Ficha(animal: animal),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _chamarNoWhatsApp(context),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Conversar no WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Cores.principal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ),
          BarraInferior(
            aoIrParaInicio: () => Navigator.maybePop(context, animal),
          ),
        ],
      ),
    );
  }
}

// A ficha do animal: quem ele é, as medidas, onde está e quem responde por ele
class _Ficha extends StatelessWidget {
  final Animal animal;

  const _Ficha({required this.animal});

  @override
  Widget build(BuildContext context) {
    final medidas = <(String, String)>[
      ('porte', animal.porte),
      ('idade', animal.idade),
      ('peso', animal.peso),
      ('cor', animal.cor),
    ].where((medida) => medida.$2.trim().isNotEmpty).toList();

    final cuidados = [
      if (animal.castrado) 'castrado',
      if (animal.vacinado) 'vacinado',
      if (animal.vermifugado) 'vermifugado',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // o nome e o tipo do registro, que é o que muda a leitura da ficha
          Row(
            children: [
              Expanded(
                child: Text(
                  animal.nome.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Etiqueta(rotuloSingular(animal.tipo)),
              if (animal.status == StatusAnimal.adotado) ...[
                const SizedBox(width: 6),
                Etiqueta(animal.status.rotulo, cheia: true),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            animal.identidade,
            style: const TextStyle(color: Cores.textoFraco, fontSize: 14),
          ),

          if (medidas.isNotEmpty) ...[
            const SizedBox(height: 16),
            _PainelDeMedidas(medidas: medidas),
          ],

          if (cuidados.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var indice = 0; indice < cuidados.length; indice++) ...[
                  if (indice > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Cuidado(
                      rotulo: comMaiuscula(cuidados[indice]),
                      marcado: true,
                    ),
                  ),
                ],
              ],
            ),
          ],

          if (animal.necessidadesEspeciais.isNotEmpty) ...[
            const SizedBox(height: 12),
            _NecessidadesEspeciais(animal.necessidadesEspeciais),
          ],

          const _Divisoria(),
          _Rotulo(animal.tipo.tituloDoLugar),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Cores.principal,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${animal.bairro}, ${animal.cidade}',
                  style: const TextStyle(
                    color: Cores.principal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                animal.publicadoHa(DateTime.now()),
                style: const TextStyle(color: Cores.textoFraco, fontSize: 13),
              ),
            ],
          ),
          if (animal.observacoes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              animal.observacoes,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],

          const _Divisoria(),
          _Rotulo(animal.tipo.tituloDoContato),
          Text(
            animal.dono.nome,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            animal.dono.telefone,
            style: const TextStyle(
              fontSize: 15,
              color: Cores.principal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// As medidas do animal em duas colunas
class _PainelDeMedidas extends StatelessWidget {
  final List<(String, String)> medidas;

  const _PainelDeMedidas({required this.medidas});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Cores.fundo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var linha = 0; linha < medidas.length; linha += 2) ...[
            if (linha > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Medida(medidas[linha])),
                const SizedBox(width: 12),
                Expanded(
                  child: linha + 1 < medidas.length
                      ? _Medida(medidas[linha + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Medida extends StatelessWidget {
  final (String, String) medida;

  const _Medida(this.medida);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          medida.$1.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Cores.textoFraco,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          comMaiuscula(medida.$2),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// O título de um bloco: diz o que vem embaixo, e muda com o tipo do registro
class _Rotulo extends StatelessWidget {
  final String texto;

  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      texto,
      style: const TextStyle(color: Cores.textoFraco, fontSize: 12),
    ),
  );
}

// Separa os blocos da ficha, na mesma linha fina do card do feed
class _Divisoria extends StatelessWidget {
  const _Divisoria();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 14),
    child: Divider(height: 1, thickness: 1, color: Cores.borda),
  );
}

// O que este animal precisa e os outros não, logo abaixo dos selos de cuidado.
// Sem rótulo em caixa alta, que na ficha é o que abre bloco novo
class _NecessidadesEspeciais extends StatelessWidget {
  final String texto;

  const _NecessidadesEspeciais(this.texto);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          // desce o ícone para ele sentar na primeira linha do texto
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.medical_services_outlined,
            size: 16,
            color: Cores.principal,
            semanticLabel: 'Necessidades especiais',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            comMaiuscula(texto),
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }
}
