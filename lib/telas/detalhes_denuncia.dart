// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter/services: área de transferência (Clipboard).
import 'package:flutter/services.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';
// Pacote url_launcher: abre WhatsApp, telefone e links no navegador.
import 'package:url_launcher/url_launcher.dart';

// Arquivo estado_pata_amiga.dart: ONGs carregadas, para achar a organização.
import '../estado/estado_pata_amiga.dart';
// Arquivo denuncia.dart: modelo da denúncia e data relativa.
import '../modelos/denuncia.dart';
// Arquivo ong.dart: a organização que recebeu a denúncia.
import '../modelos/ong.dart';
// Arquivo texto.dart: comMaiuscula, para o porte e o sexo do animal.
import '../modelos/texto.dart';
// Arquivo usuario_provider.dart: quem está vendo e quem muda a situação.
import '../provider/usuario_provider.dart';
// Arquivo denuncia_service.dart: gravação da nova situação na API.
import '../services/denuncia_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo etiqueta.dart: etiqueta arredondada usada para a situação.
import '../widgets/etiqueta.dart';
// Arquivo galeria_animal.dart: galeria de fotos deslizável.
import '../widgets/galeria_animal.dart';
// Arquivo historico_de_situacoes.dart: linha do tempo das situações.
import '../widgets/historico_de_situacoes.dart';
// Arquivo mapa_de_local.dart: prévia do mapa com o ponto da denúncia.
import '../widgets/mapa_de_local.dart';
// Arquivo mascaras.dart: formatação do telefone para exibição.
import '../widgets/mascaras.dart';
// Arquivo painel_de_observacao.dart: nova situação com observação.
import '../widgets/painel_de_observacao.dart';
// Arquivo reportar.dart: envio da denúncia pelo compartilhamento.
import 'reportar.dart';

// Detalhes de uma denúncia, no mesmo layout da ficha do animal: galeria de
// fotos, tipo e situação, protocolo, datas, organização, local, relato,
// denunciante e o histórico das situações. Para as pessoas da organização
// que recebeu a denúncia, o botão inferior atualiza a situação; para quem
// denunciou, envia a denúncia também pelo WhatsApp da organização
class DetalhesDenuncia extends StatefulWidget {
  const DetalhesDenuncia({super.key, required this.denuncia, this.servico});

  final Denuncia denuncia;
  // Serviço injetável para os testes; sem ele, usa o padrão
  final DenunciaService? servico;

  @override
  State<DetalhesDenuncia> createState() => _DetalhesDenunciaState();
}

class _DetalhesDenunciaState extends State<DetalhesDenuncia> {
  late final _servico = widget.servico ?? DenunciaService();
  // A versão exibida, atualizada depois de cada mudança de situação
  late Denuncia denuncia = widget.denuncia;
  bool _salvando = false;

  // A organização que recebeu a denúncia, se estiver carregada
  Ong? _organizacao(BuildContext context) =>
      PataAmigaScope.ouvindo(context)?.ongs
          .where((ong) => ong.id == denuncia.ongId)
          .firstOrNull;

  // Pede a nova situação e a observação e grava a mudança na API
  Future<void> _atualizarSituacao() async {
    final mensageiro = ScaffoldMessenger.of(context);
    final autor = context.read<UsuarioProvider?>()?.usuario.nome ?? '';
    final escolhida = await pedirObservacao<SituacaoDaDenuncia>(
      context,
      titulo: 'Atualizar situação',
      texto:
          'Quem denunciou vê a nova situação e a observação em Minhas '
          'denúncias.',
      rotuloPrincipal: 'Salvar',
      opcoes: [
        for (final situacao in SituacaoDaDenuncia.values)
          if (situacao != denuncia.situacao) (situacao, situacao.rotulo),
      ],
    );
    final nova = escolhida?.escolha;
    if (escolhida == null || nova == null || !mounted) return;
    setState(() => _salvando = true);
    String aviso;
    try {
      final gravada = await _servico.atualizarSituacao(
        denuncia.comSituacao(
          nova,
          observacao: escolhida.observacao,
          autor: autor,
        ),
      );
      if (!mounted) return;
      setState(() => denuncia = gravada);
      aviso = 'Situação atualizada para ${nova.rotulo}.';
    } on Exception {
      aviso = 'Não foi possível atualizar agora. Tente de novo.';
    }
    if (mounted) setState(() => _salvando = false);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(aviso)));
  }

  // Abre o ponto da denúncia no app de mapas, já que denúncias não aparecem
  // no mapa do app. Usa o link do Google Maps, que abre no app de mapas ou no
  // navegador em qualquer plataforma
  Future<void> _abrirNoMapa(BuildContext context) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final ponto = '${denuncia.latitude},${denuncia.longitude}';
    bool abriu;
    try {
      abriu = await launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$ponto'),
        mode: LaunchMode.externalApplication,
      );
    } on Exception {
      // Sem aplicativo que trate o link, a plataforma lança exceção
      abriu = false;
    }
    if (!abriu) {
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o mapa neste aparelho.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizacao = _organizacao(context);
    final email = context.watch<UsuarioProvider?>()?.usuario.email ?? '';
    final daOrganizacao = organizacao?.fazParte(email) ?? false;
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
          'DETALHES',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (denuncia.fotos.isNotEmpty) ...[
              // A foto da denúncia aparece inteira: um detalhe cortado
              // pode ser justamente a prova do que aconteceu
              GaleriaAnimal(fotos: denuncia.fotos, altura: 280, inteira: true),
              const SizedBox(height: 12),
            ],
            _Ficha(
              denuncia: denuncia,
              organizacao: organizacao,
              aoAbrirMapa: () => _abrirNoMapa(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !daOrganizacao && organizacao == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: daOrganizacao
                      ? FilledButton.icon(
                          onPressed: _salvando ? null : _atualizarSituacao,
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Atualizar situação'),
                          style: FilledButton.styleFrom(
                            backgroundColor: context.cores.principal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => encaminharDenuncia(denuncia),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text(
                            'Enviar pelo WhatsApp com as fotos',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.cores.principal,
                            side: BorderSide(color: context.cores.principal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                ),
              ),
            ),
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({
    required this.denuncia,
    required this.organizacao,
    required this.aoAbrirMapa,
  });

  final Denuncia denuncia;
  final Ong? organizacao;
  final VoidCallback aoAbrirMapa;

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final ocorrida = denuncia.ocorridaEm;
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
          // Cabeçalho: tipo da denúncia e situação atual
          Row(
            children: [
              Expanded(
                child: Text(
                  denuncia.tipo.rotulo.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Etiqueta(
                denuncia.situacao.rotulo,
                cheia: denuncia.situacao == SituacaoDaDenuncia.encerrada,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Protocolo ${denuncia.protocolo}',
                  style: TextStyle(
                    color: context.cores.textoFraco,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copiar o protocolo',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.copy,
                  size: 18,
                  color: context.cores.principal,
                ),
                onPressed: () async {
                  final mensageiro = ScaffoldMessenger.of(context);
                  await Clipboard.setData(
                    ClipboardData(text: denuncia.protocolo),
                  );
                  mensageiro
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Protocolo copiado.')),
                    );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Painel(
            dados: [
              ('Registrada', quandoFoi(denuncia.registradaEm, agora)),
              (
                'Aconteceu',
                ocorrida == null
                    ? 'Não informado'
                    : '${_dois(ocorrida.day)}/${_dois(ocorrida.month)}/'
                          '${ocorrida.year}',
              ),
            ],
          ),

          if (organizacao != null) ...[
            const SizedBox(height: 8),
            _Painel(dados: [('Enviada para', organizacao!.nome)]),
          ],

          // O animal, nas denúncias registradas com esses campos
          if (denuncia.especie.isNotEmpty) ...[
            const _Divisoria(),
            const _Rotulo('O animal'),
            const SizedBox(height: 4),
            _Painel(
              dados: [
                ('Espécie', denuncia.especie),
                ('Porte', comMaiuscula(denuncia.porte)),
              ],
            ),
            const SizedBox(height: 8),
            _Painel(
              dados: [
                ('Sexo', comMaiuscula(denuncia.sexo)),
                (
                  'Raça',
                  denuncia.raca.isEmpty ? 'Não informada' : denuncia.raca,
                ),
              ],
            ),
          ],

          const _Divisoria(),
          const _Rotulo('Onde aconteceu'),
          const SizedBox(height: 4),
          _QuadroDoLugar(denuncia: denuncia),
          if ((denuncia.latitude, denuncia.longitude) case (
            final double latitude,
            final double longitude,
          )) ...[
            const SizedBox(height: 8),
            PreviaDoMapa(
              ponto: LatLng(latitude, longitude),
              cor: context.cores.destaque,
              aoTocar: aoAbrirMapa,
            ),
          ],

          const _Divisoria(),
          const _Rotulo('O que aconteceu'),
          _Relato(denuncia.descricao),

          const _Divisoria(),
          const _Rotulo('Quem denunciou'),
          const SizedBox(height: 4),
          // Na identificada, a organização vê o nome e o telefone para entrar
          // em contato
          if (denuncia.anonima)
            Text(
              'Denúncia anônima: o registro não inclui o nome nem o telefone de quem denunciou.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: context.cores.texto,
              ),
            )
          else
            _Painel(
              dados: [
                ('Nome', denuncia.denuncianteNome),
                ('Telefone', formatarTelefone(denuncia.denuncianteTelefone)),
              ],
            ),

          if (denuncia.historico.isNotEmpty) ...[
            const _Divisoria(),
            const _Rotulo('Histórico'),
            const SizedBox(height: 4),
            HistoricoDeSituacoes(
              etapas: denuncia.historico,
              rotuloDe: (nome) =>
                  SituacaoDaDenuncia.values
                      .where((situacao) => situacao.name == nome)
                      .firstOrNull
                      ?.rotulo ??
                  nome,
            ),
          ],
        ],
      ),
    );
  }
}

// Número com dois dígitos, para datas no formato dd/mm/aaaa
String _dois(int n) => n.toString().padLeft(2, '0');

// Pares rótulo e valor lado a lado, em colunas de mesma largura
class _Painel extends StatelessWidget {
  const _Painel({required this.dados});

  final List<(String, String)> dados;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cores.fundo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < dados.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dados[i].$1.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: context.cores.textoFraco,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dados[i].$2,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Título de uma seção da ficha
class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      texto,
      style: TextStyle(color: context.cores.textoFraco, fontSize: 12),
    ),
  );
}

// Linha que separa as seções da ficha
class _Divisoria extends StatelessWidget {
  const _Divisoria();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Divider(height: 1, thickness: 1, color: context.cores.borda),
  );
}

// Endereço da denúncia: rua em destaque e bairro abaixo
class _QuadroDoLugar extends StatelessWidget {
  const _QuadroDoLugar({required this.denuncia});

  final Denuncia denuncia;

  @override
  Widget build(BuildContext context) {
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
                  denuncia.rua,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.cores.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${denuncia.bairro}, Formiga',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cores.principal,
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

// Relato de quem denunciou, com a barra lateral usada em citações
class _Relato extends StatelessWidget {
  const _Relato(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: context.cores.principal, width: 3),
        ),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 14, height: 1.5, color: context.cores.texto),
      ),
    );
  }
}
