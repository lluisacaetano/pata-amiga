import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../modelos/avistamento.dart';
import '../modelos/camadas_do_mapa.dart';
import '../modelos/dono.dart';
import '../routes/route_names.dart';
import '../tema/cores.dart';
import '../widgets/barra_inferior.dart';
import '../widgets/cuidado.dart';
import '../widgets/escolha_de_tipo.dart';
import '../widgets/galeria_animal.dart';
import '../widgets/etiqueta.dart';
import '../widgets/foto_animal.dart';
import '../widgets/mapa_de_local.dart';
import 'tela_mapa.dart';
import '../widgets/mascaras.dart';

class DetalhesAnimal extends StatelessWidget {
  final Animal animal;

  const DetalhesAnimal({super.key, required this.animal});

  // monta o link do whatsApp e tenta abrir; se não conseguir, avisa na tela
  Future<void> _chamarNoWhatsApp(
    BuildContext context, {
    String? mensagem,
  }) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final texto = Uri.encodeComponent(
      mensagem ?? 'Olá! Vi ${animal.nome} no Pata Amiga e queria saber mais.',
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

  // Abre o registro e, se a pessoa registrar, oferece avisar o tutor: sem um
  // servidor de notificações, o aviso vai pelo WhatsApp, como todo contato
  // do app
  Future<void> _registrarAvistamento(BuildContext context) async {
    final estado = PataAmigaScope.of(context);
    final novo = await Navigator.pushNamed(
      context,
      AppRoutes.registrarAvistamento,
      arguments: animal,
    );
    if (novo is! Avistamento || !context.mounted) return;
    estado.adicionarAvistamento(novo);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.cartao,
      showDragHandle: true,
      builder: (painel) => _AvisarOTutor(
        animal: animal,
        aoAvisar: () {
          Navigator.pop(painel);
          _chamarNoWhatsApp(
            context,
            mensagem: mensagemParaOTutor(animal, novo, DateTime.now()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = PataAmigaScope.of(context);
    final estaCurtido = estado.estaCurtido(animal.nome);
    final perdido = animal.tipo == TipoRegistro.perdido;

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
            if (perdido) ...[
              const SizedBox(height: 12),
              _Avistamentos(
                avistamentos: avistamentosDe(animal, estado.avistamentos),
              ),
            ],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (perdido) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () => _registrarAvistamento(context),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Registrar avistamento'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Cores.principal,
                          side: const BorderSide(color: Cores.principal),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
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
                ],
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
    // O mesmo ponto que o mapa usa: o último avistamento, ou o do cadastro
    final pinos = pinosDoMapa(
      [animal],
      PataAmigaScope.of(context).avistamentos,
      camadasDoMapa.toSet(),
    );
    final pino = pinos.isEmpty ? null : pinos.single;
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
          const SizedBox(height: 4),
          _QuadroDoLugar(animal: animal),
          // Perdido e resgate vão para o mapa; a prévia leva até ele
          if (pino != null) ...[
            const SizedBox(height: 8),
            PreviaDoMapa(
              ponto: LatLng(pino.latitude, pino.longitude),
              cor: corDaCamada(animal.tipo),
              aoTocar: () => Navigator.pushNamed(
                context,
                AppRoutes.mapa,
                arguments: animal,
              ),
            ),
          ],
          if (animal.observacoes.isNotEmpty) ...[
            const SizedBox(height: 14),
            const _Rotulo('Observações'),
            _Recado(animal.observacoes),
          ],

          const _Divisoria(),
          _Rotulo(animal.tipo.tituloDoContato),
          const SizedBox(height: 4),
          // O mesmo quadro das medidas, com o telefone sempre formatado
          _PainelDeMedidas(
            medidas: [
              ('Nome', animal.dono.nome),
              ('Telefone', formatarTelefone(animal.dono.telefone)),
            ],
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

// Os avistamentos do animal perdido, do mais recente para o mais antigo
class _Avistamentos extends StatelessWidget {
  const _Avistamentos({required this.avistamentos});

  final List<Avistamento> avistamentos;

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
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
          const Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: Cores.principal),
              SizedBox(width: 8),
              Text(
                'Avistamentos',
                style: TextStyle(
                  color: Cores.principal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (avistamentos.isEmpty)
            const Text(
              'Ninguém registrou um avistamento ainda. Se você viu este '
              'animal, registre onde e quando.',
              style: TextStyle(fontSize: 14, color: Cores.textoFraco),
            )
          else
            for (var i = 0; i < avistamentos.length && i < 5; i++)
              _LinhaDeAvistamento(
                avistamento: avistamentos[i],
                ultimo: i == 0,
                agora: agora,
              ),
        ],
      ),
    );
  }
}

// Um avistamento no mesmo quadro do endereço da ficha. O mais recente leva
// a etiqueta, porque é ele que põe o pino no mapa
class _LinhaDeAvistamento extends StatelessWidget {
  const _LinhaDeAvistamento({
    required this.avistamento,
    required this.ultimo,
    required this.agora,
  });

  final Avistamento avistamento;
  final bool ultimo;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final quem = avistamento.registradoPor.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Cores.fundo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Cores.principalClara,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.visibility_outlined,
              size: 20,
              color: Cores.principal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Visto ${avistamento.vistoHa(agora)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (ultimo) ...[
                      const SizedBox(width: 8),
                      const Etiqueta('Último'),
                    ],
                  ],
                ),
                if (avistamento.lugar.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    avistamento.lugar,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Cores.principal,
                    ),
                  ),
                ],
                if (quem.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Registrado por $quem',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Cores.textoFraco,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (avistamento.foto.isNotEmpty) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              child: FotoAnimal(
                caminho: avistamento.foto,
                altura: 52,
                raio: BorderRadius.circular(8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Depois de registrar: o convite para avisar quem está procurando
class _AvisarOTutor extends StatelessWidget {
  const _AvisarOTutor({required this.animal, required this.aoAvisar});

  final Animal animal;
  final VoidCallback aoAvisar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, size: 40, color: Cores.principal),
            const SizedBox(height: 10),
            const Text(
              'Avistamento registrado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'O ponto já aparece no mapa. Avise ${animal.dono.nome}, que '
              'está procurando ${animal.nome}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Cores.textoFraco,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: aoAvisar,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Avisar o tutor pelo WhatsApp'),
              style: FilledButton.styleFrom(
                backgroundColor: Cores.principal,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Cores.textoFraco),
              child: const Text('Agora não'),
            ),
          ],
        ),
      ),
    );
  }
}

// Onde o animal está, no mesmo quadro das medidas e do contato. A rua só
// aparece em perdido e resgate, onde é um lugar público: na adoção ela seria
// a casa do responsável
class _QuadroDoLugar extends StatelessWidget {
  const _QuadroDoLugar({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final mostraRua =
        animal.tipo != TipoRegistro.adocao && animal.rua.trim().isNotEmpty;
    final principal = mostraRua ? animal.rua : animal.bairro;
    final secundario = mostraRua
        ? '${animal.bairro}, ${animal.cidade}'
        : animal.cidade;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Cores.fundo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Cores.principalClara,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 20,
              color: Cores.principal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  principal,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Cores.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secundario,
                  style: const TextStyle(fontSize: 13, color: Cores.principal),
                ),
                const SizedBox(height: 4),
                Text(
                  'Publicado ${animal.publicadoHa(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Cores.textoFraco,
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

// As observações como um recado de quem cadastrou: a barra verde à esquerda
// separa o que a pessoa escreveu dos dados da ficha
class _Recado extends StatelessWidget {
  const _Recado(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Cores.principal, width: 3)),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 14, height: 1.5, color: Cores.texto),
      ),
    );
  }
}
