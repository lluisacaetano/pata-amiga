// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter/services: área de transferência (Clipboard).
import 'package:flutter/services.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';
// Pacote url_launcher: abre WhatsApp, telefone e links no navegador.
import 'package:url_launcher/url_launcher.dart';

// Arquivo canais_de_denuncia.dart: nome do canal de denúncia.
import '../dados/canais_de_denuncia.dart';
// Arquivo denuncia.dart: modelo da denúncia e data relativa.
import '../modelos/denuncia.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo etiqueta.dart: etiqueta arredondada usada para a situação.
import '../widgets/etiqueta.dart';
// Arquivo galeria_animal.dart: galeria de fotos deslizável.
import '../widgets/galeria_animal.dart';
// Arquivo mapa_de_local.dart: prévia do mapa com o ponto da denúncia.
import '../widgets/mapa_de_local.dart';
// Arquivo mascaras.dart: formatação do telefone para exibição.
import '../widgets/mascaras.dart';
// Arquivo reportar.dart: envio da denúncia pelo compartilhamento.
import 'reportar.dart';

// Detalhes de uma denúncia, no mesmo layout da ficha do animal: galeria de
// fotos, tipo e situação, protocolo, datas, local, relato e denunciante. O
// botão inferior reenvia a denúncia ao canal de denúncia
class DetalhesDenuncia extends StatelessWidget {
  const DetalhesDenuncia({super.key, required this.denuncia});

  final Denuncia denuncia;

  // Abre o ponto da denúncia no app de mapas do aparelho (URI geo:), já que
  // denúncias não aparecem no mapa do app
  Future<void> _abrirNoMapa(BuildContext context) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final ponto = '${denuncia.latitude},${denuncia.longitude}';
    final abriu = await launchUrl(
      Uri.parse('geo:$ponto?q=$ponto'),
      mode: LaunchMode.externalApplication,
    );
    if (!abriu) {
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Nenhum app de mapas encontrado neste aparelho.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              GaleriaAnimal(fotos: denuncia.fotos, altura: 280),
              const SizedBox(height: 12),
            ],
            _Ficha(
              denuncia: denuncia,
              aoAbrirMapa: () => _abrirNoMapa(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => encaminharDenuncia(denuncia),
              icon: const Icon(Icons.share_outlined),
              label: Text('Enviar à $nomeDoCanalDeDenuncia com as fotos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.cores.principal,
                foregroundColor: context.sobrePrincipal,
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
  const _Ficha({required this.denuncia, required this.aoAbrirMapa});

  final Denuncia denuncia;
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
