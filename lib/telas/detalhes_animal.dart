// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';
// Pacote url_launcher: abre WhatsApp, telefone e links no navegador.
import 'package:url_launcher/url_launcher.dart';

// Arquivo estado_pata_amiga.dart: estado compartilhado do app.
import '../estado/estado_pata_amiga.dart';
// Arquivo animal.dart: modelo do animal, tipo e status do registro.
import '../modelos/animal.dart';
// Arquivo avistamento.dart: avistamentos do animal e a mensagem para o tutor.
import '../modelos/avistamento.dart';
// Arquivo camadas_do_mapa.dart: camadas e pinos do mapa.
import '../modelos/camadas_do_mapa.dart';
// Arquivo dono.dart: número do responsável no formato do WhatsApp.
import '../modelos/dono.dart';
// Arquivo ong.dart: modelo da ONG.
import '../modelos/ong.dart';
// Arquivo usuario_provider.dart: e-mail da pessoa logada.
import '../provider/usuario_provider.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo animal_service.dart: serviço de animais da API.
import '../services/animal_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo acoes_do_registro.dart: ações sobre um registro de animal.
import '../widgets/acoes_do_registro.dart';
// Arquivo barra_inferior.dart: barra de navegação inferior.
import '../widgets/barra_inferior.dart';
// Arquivo cuidado.dart: selo de cuidado (castrado, vacinado, vermifugado).
import '../widgets/cuidado.dart';
// Arquivo escolha_de_tipo.dart: nome do tipo do registro no singular.
import '../widgets/escolha_de_tipo.dart';
// Arquivo galeria_animal.dart: galeria de fotos do animal.
import '../widgets/galeria_animal.dart';
// Arquivo etiqueta.dart: etiqueta de tipo e status.
import '../widgets/etiqueta.dart';
// Arquivo foto_animal.dart: foto do animal ou do avistamento.
import '../widgets/foto_animal.dart';
// Arquivo mapa_de_local.dart: prévia do mapa da ficha.
import '../widgets/mapa_de_local.dart';
// Arquivo tela_mapa.dart: cor de cada camada do mapa.
import 'tela_mapa.dart';
// Arquivo mascaras.dart: formatação do telefone.
import '../widgets/mascaras.dart';

// Ficha completa de um animal: fotos, dados, local, contato e, para quem
// cadastrou, os controles do registro. Em animal perdido, mostra também os
// avistamentos e o botão para registrar um
class DetalhesAnimal extends StatelessWidget {
  final Animal animal;
  // Serviço injetável para os testes; sem ele, usa o AnimalService padrão
  final AnimalService? api;

  const DetalhesAnimal({super.key, required this.animal, this.api});

  // Abre a conversa no WhatsApp com o responsável, com uma mensagem pronta.
  // Se o aparelho não conseguir abrir o link, avisa por SnackBar
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

  // Abre o registro de avistamento e, se ele for salvo, oferece avisar o
  // tutor. Como o app não tem servidor de notificações, o aviso vai pelo
  // WhatsApp, como os demais contatos
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
      backgroundColor: context.cores.cartao,
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
    // A rota pode ter recebido uma cópia antiga; vale a versão do estado
    final animal = estado.atual(this.animal);
    final email = context.read<UsuarioProvider?>()?.usuario.email ?? '';
    final ehResponsavel = estado.podeMudarStatus(animal, email);
    final minhaOng = estado.ongDe(email);
    final estaCurtido = estado.estaCurtido(animal.nome);
    final perdido = animal.tipo == TipoRegistro.perdido;

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
            onPressed: () => Navigator.maybePop(context, animal),
          ),
        ),
        centerTitle: true,
        title: Text(
          'DETALHES',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
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
            if (ehResponsavel) ...[
              const SizedBox(height: 12),
              _ControleDoStatus(
                animal: animal,
                aoMudar: () => mudarStatus(context, animal, api: api),
                aoEditar: () => editarRegistro(context, animal, api: api),
                aoPublicar: () => publicarParaAdocao(context, animal, api: api),
                // Quem faz parte de uma ONG pode transferir para ela um
                // cadastro que ainda não é de nenhuma ONG
                ongParaTransferir: animal.ongId == null ? minhaOng : null,
                aoTransferir: minhaOng == null
                    ? null
                    : () => enviarParaOng(context, animal, minhaOng, api: api),
              ),
            ],
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
                          foregroundColor: context.cores.principal,
                          side: BorderSide(color: context.cores.principal),
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
                        backgroundColor: context.cores.principal,
                        foregroundColor: context.sobrePrincipal,
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

// Cartão principal da ficha: identificação, medidas, cuidados, local,
// observações e contato do responsável
class _Ficha extends StatelessWidget {
  final Animal animal;

  const _Ficha({required this.animal});

  @override
  Widget build(BuildContext context) {
    // Mesmo ponto usado no mapa: o último avistamento ou, sem ele, o do
    // cadastro. Adoção não tem pino, então a lista pode vir vazia
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
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome, tipo do registro e, se encerrado, o status final
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
              if (animal.finalizado) ...[
                const SizedBox(width: 6),
                Etiqueta(animal.rotuloDoStatus, cheia: true),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            animal.identidade,
            style: TextStyle(color: context.cores.textoFraco, fontSize: 14),
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
          // Perdido e resgate aparecem no mapa; a prévia abre o mapa nele
          if (pino != null) ...[
            const SizedBox(height: 8),
            PreviaDoMapa(
              ponto: LatLng(pino.latitude, pino.longitude),
              cor: corDaCamada(context, animal.tipo),
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
          // Mesmo quadro das medidas, com o telefone formatado
          _PainelDeMedidas(
            medidas: [
              ('Nome', animal.dono.nome),
              ('Telefone', formatarTelefone(animal.dono.telefone)),
            ],
          ),
          // Animal publicado por uma ONG: botão para o perfil dela
          if (PataAmigaScope.of(context).ongs
                  .where((ong) => ong.id != null && ong.id == animal.ongId)
                  .firstOrNull
              case final ong?) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.perfilOng,
                arguments: ong,
              ),
              icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
              label: const Text('Ver perfil da ONG'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.cores.principal,
                side: BorderSide(color: context.cores.principal),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Pares de rótulo e valor em duas colunas, usado nas medidas e no contato
class _PainelDeMedidas extends StatelessWidget {
  final List<(String, String)> medidas;

  const _PainelDeMedidas({required this.medidas});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cores.fundo,
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

// Um par do painel: rótulo pequeno em caixa alta e o valor abaixo
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: context.cores.textoFraco,
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

// Título discreto de um bloco da ficha; o texto varia com o tipo do registro
class _Rotulo extends StatelessWidget {
  final String texto;

  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      texto,
      style: TextStyle(color: context.cores.textoFraco, fontSize: 12),
    ),
  );
}

// Linha fina que separa os blocos da ficha, igual à do card do feed
class _Divisoria extends StatelessWidget {
  const _Divisoria();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 14),
    child: Divider(height: 1, thickness: 1, color: context.cores.borda),
  );
}

// Necessidades especiais do animal, com ícone, logo abaixo dos selos de
// cuidado. Não leva rótulo para não parecer o início de um bloco novo
class _NecessidadesEspeciais extends StatelessWidget {
  final String texto;

  const _NecessidadesEspeciais(this.texto);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Alinha o ícone com a primeira linha do texto
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.medical_services_outlined,
            size: 16,
            color: context.cores.principal,
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

// Avistamentos do animal perdido, do mais recente para o mais antigo,
// limitados aos cinco últimos
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
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: context.cores.principal),
              SizedBox(width: 8),
              Text(
                'Avistamentos',
                style: TextStyle(
                  color: context.cores.principal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (avistamentos.isEmpty)
            Text(
              'Ninguém registrou um avistamento ainda. Se você viu este '
              'animal, registre onde e quando.',
              style: TextStyle(fontSize: 14, color: context.cores.textoFraco),
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

// Um avistamento, no mesmo formato do quadro de endereço. O mais recente
// recebe a etiqueta "Último", porque é ele que define o pino no mapa
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
        color: context.cores.fundo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.cores.principalClara,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.visibility_outlined,
              size: 20,
              color: context.cores.principal,
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
                    style: TextStyle(
                      fontSize: 13,
                      color: context.cores.principal,
                    ),
                  ),
                ],
                if (quem.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Registrado por $quem',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.cores.textoFraco,
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

// Painel exibido após registrar um avistamento, com o convite para avisar o
// tutor pelo WhatsApp
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
            Icon(Icons.check_circle, size: 40, color: context.cores.principal),
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
              style: TextStyle(
                fontSize: 14,
                color: context.cores.textoFraco,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: aoAvisar,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Avisar o tutor pelo WhatsApp'),
              style: FilledButton.styleFrom(
                backgroundColor: context.cores.principal,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: context.cores.textoFraco),
              child: const Text('Agora não'),
            ),
          ],
        ),
      ),
    );
  }
}

// Onde o animal está e há quanto tempo foi publicado. A rua só aparece em
// perdido e resgate, onde é um lugar público; na adoção ela seria o endereço
// do responsável, por isso fica oculta
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
        color: context.cores.fundo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.cores.principalClara,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              size: 20,
              color: context.cores.principal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  principal,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.cores.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secundario,
                  style: TextStyle(fontSize: 13, color: context.cores.principal),
                ),
                const SizedBox(height: 4),
                Text(
                  'Publicado ${animal.publicadoHa(DateTime.now())}',
                  style: TextStyle(fontSize: 12, color: context.cores.textoFraco),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Observações livres de quem cadastrou. A barra à esquerda separa o texto
// escrito pela pessoa dos dados estruturados da ficha
class _Recado extends StatelessWidget {
  const _Recado(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: context.cores.principal, width: 3)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 14, height: 1.5, color: context.cores.texto),
      ),
    );
  }
}

// Painel visível só para quem pode alterar o registro: muda o status (ou
// desfaz), edita, transfere para a ONG e publica um resgatado para adoção
class _ControleDoStatus extends StatelessWidget {
  const _ControleDoStatus({
    required this.animal,
    required this.aoMudar,
    required this.aoEditar,
    required this.aoPublicar,
    this.ongParaTransferir,
    this.aoTransferir,
  });

  final Animal animal;
  final VoidCallback aoMudar;
  final VoidCallback aoEditar;
  final VoidCallback aoPublicar;
  final Ong? ongParaTransferir;
  final VoidCallback? aoTransferir;

  @override
  Widget build(BuildContext context) {
    final finalizado = animal.finalizado;
    final textoDoBotao = finalizado
        ? 'Voltar para ${animal.comStatus(StatusAnimal.disponivel).rotuloDoStatus}'
        : 'Marcar como ${animal.comStatus(animal.desfecho).rotuloDoStatus}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: context.cores.principal,
              ),
              const SizedBox(width: 8),
              Text(
                // Em animal de ONG, quem cuida pode não ser quem cadastrou
                animal.ongId != null
                    ? 'Animal da sua ONG'
                    : 'Você cadastrou este animal',
                style: TextStyle(
                  color: context.cores.principal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Situação: ${comMaiuscula(animal.rotuloDoStatus)}',
            style: TextStyle(fontSize: 14, color: context.cores.textoFraco),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: aoMudar,
            icon: Icon(
              finalizado ? Icons.undo : Icons.check_circle_outline,
              size: 18,
            ),
            label: Text(textoDoBotao),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.cores.principal,
              side: BorderSide(color: context.cores.principal),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: aoEditar,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar registro'),
            style: TextButton.styleFrom(
              foregroundColor: context.cores.principal,
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          if (ongParaTransferir case final ong?) ...[
            TextButton.icon(
              onPressed: aoTransferir,
              icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
              label: Text(
                'Transferir para ${ong.nome}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                foregroundColor: context.cores.principal,
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
          if (animal.status == StatusAnimal.resgatado) ...[
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: aoPublicar,
              icon: const Icon(Icons.favorite_border, size: 18),
              label: const Text('Publicar para adoção'),
              style: FilledButton.styleFrom(
                backgroundColor: context.cores.principal,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
