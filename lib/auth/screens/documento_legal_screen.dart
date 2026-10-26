// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../../tema/cores.dart';

// Qual documento legal a tela mostra
enum TipoDocumentoLegal { termos, privacidade }

// Mostra os Termos de Uso ou a Política de Privacidade, seção por seção
class DocumentoLegalScreen extends StatelessWidget {
  const DocumentoLegalScreen({super.key, required this.tipo});

  final TipoDocumentoLegal tipo;

  @override
  Widget build(BuildContext context) {
    final titulo = switch (tipo) {
      TipoDocumentoLegal.termos => 'Termos de Uso',
      TipoDocumentoLegal.privacidade => 'Política de Privacidade',
    };
    final icone = switch (tipo) {
      TipoDocumentoLegal.termos => Icons.description_outlined,
      TipoDocumentoLegal.privacidade => Icons.privacy_tip_outlined,
    };
    final secoes = switch (tipo) {
      TipoDocumentoLegal.termos => _termos,
      TipoDocumentoLegal.privacidade => _privacidade,
    };

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
          titulo.toUpperCase(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Abertura(titulo: titulo, icone: icone),
          for (final secao in secoes) _CartaoDaSecao(secao),
        ],
      ),
    );
  }
}

// Cartão verde do topo, com o nome do documento e o aviso de rascunho
class _Abertura extends StatelessWidget {
  const _Abertura({required this.titulo, required this.icone});

  final String titulo;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cores.principalClara,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icone, size: 28, color: context.cores.principal),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.cores.principal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rascunho informativo, sujeito a revisão antes da '
                  'publicação.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: context.cores.textoFraco,
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

// Cartão branco de uma seção, com ícone, título e texto
class _CartaoDaSecao extends StatelessWidget {
  const _CartaoDaSecao(this.secao);

  final _SecaoDocumento secao;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Icon(secao.icone, size: 18, color: context.cores.principal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  secao.titulo,
                  style: TextStyle(
                    color: context.cores.principal,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            secao.conteudo,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: context.cores.texto,
            ),
          ),
        ],
      ),
    );
  }
}

// Uma seção do documento: ícone, título e texto
class _SecaoDocumento {
  const _SecaoDocumento(this.icone, this.titulo, this.conteudo);

  final IconData icone;
  final String titulo;
  final String conteudo;
}

// Seções dos Termos de Uso
const _termos = [
  _SecaoDocumento(
    Icons.info_outline,
    '1. Sobre o aplicativo',
    'O Pata Amiga é uma ferramenta de apoio para divulgar animais para '
        'adoção, perdidos ou resgatados, além de informações comunitárias '
        'sobre avistamentos e pontos de alimentação. O aplicativo não '
        'substitui serviços veterinários, órgãos públicos ou serviços de '
        'emergência.',
  ),
  _SecaoDocumento(
    Icons.person_outline,
    '2. Cadastro e funcionamento',
    'Na versão atual, os dados do perfil e a sessão são mantidos localmente '
        'no dispositivo. A senha é conferida no login e guardada apenas como '
        'um resumo criptográfico, nunca em texto. Como a conta existe só '
        'neste aparelho, não há recuperação de senha por e-mail. Não use uma '
        'senha que você use em outros serviços.',
  ),
  _SecaoDocumento(
    Icons.photo_library_outlined,
    '3. Conteúdo publicado',
    'Você é responsável pela exatidão e atualização das informações que '
        'publicar e por ter autorização para compartilhar dados de contato, '
        'imagens e demais informações de outras pessoas. Publicações podem '
        'ficar visíveis a outros usuários. Evite incluir dados pessoais '
        'desnecessários e confirme diretamente as informações antes de '
        'qualquer adoção ou encontro.',
  ),
  _SecaoDocumento(
    Icons.verified_user_outlined,
    '4. Uso adequado',
    'Não use o aplicativo para publicar informações falsas, violar direitos '
        'de terceiros, assediar pessoas, praticar atividades ilegais ou '
        'comprometer a segurança de animais e usuários. Ao identificar um '
        'risco ou uma informação desatualizada, use os recursos de denúncia '
        'disponíveis no aplicativo.',
  ),
  _SecaoDocumento(
    Icons.warning_amber_outlined,
    '5. Limites do serviço',
    'As informações são fornecidas pelos usuários e podem não ser verificadas '
        'ou estar atualizadas. O aplicativo não garante a disponibilidade do '
        'serviço, a localização de um animal, a veracidade de anúncios ou o '
        'resultado de uma adoção. Tome precauções e não envie dinheiro ou '
        'informações financeiras a pessoas desconhecidas.',
  ),
  _SecaoDocumento(
    Icons.update,
    '6. Alterações e contato',
    'Estes termos podem ser atualizados quando o aplicativo mudar. A versão '
        'vigente deve estar disponível no aplicativo. Para dúvidas, remoção '
        'de conteúdo ou solicitações relacionadas ao uso, procure o canal '
        'oficial de contato do responsável pelo Pata Amiga, que deve ser '
        'informado antes da publicação oficial.',
  ),
];

// Seções da Política de Privacidade
const _privacidade = [
  _SecaoDocumento(
    Icons.badge_outlined,
    '1. Quem trata os dados',
    'O responsável legal pelo tratamento dos dados e seu canal de contato '
        'ainda precisam ser identificados pelo responsável pelo aplicativo '
        'antes da disponibilização pública desta política.',
  ),
  _SecaoDocumento(
    Icons.folder_outlined,
    '2. Dados tratados',
    'O cadastro solicita nome, e-mail e telefone. Na versão atual, essas '
        'informações de perfil e a identificação da sessão são salvas no '
        'armazenamento local do dispositivo. A senha é guardada no aparelho '
        'apenas como um resumo criptográfico, usado para conferir o login. '
        'Registros de animais, contatos informados, avistamentos, '
        'pontos de alimentação, fotos e informações de localização podem ser '
        'incluídos nas publicações conforme os campos preenchidos.',
  ),
  _SecaoDocumento(
    Icons.location_on_outlined,
    '3. Localização e fotos',
    'A localização do dispositivo só é solicitada quando você aciona um '
        'recurso que precisa dela. Se você optar por usar a localização em '
        'uma publicação, coordenadas podem ser associadas ao registro. Também '
        'é possível informar um endereço manualmente quando essa opção estiver '
        'disponível. Fotos escolhidas podem ser associadas aos registros. '
        'Permissões de localização e fotos podem ser gerenciadas nas '
        'configurações do dispositivo.',
  ),
  _SecaoDocumento(
    Icons.share_outlined,
    '4. Compartilhamento e armazenamento',
    'O aplicativo mantém preferências, curtidas, cache e dados do perfil no '
        'dispositivo. Registros enviados pelos recursos de publicação podem '
        'ser transmitidos à API configurada no aplicativo e ficar disponíveis '
        'a outros usuários. O responsável deve confirmar a infraestrutura, os '
        'prestadores envolvidos e os prazos de retenção antes do lançamento. '
        'Serviços do sistema operacional, mapas ou geocodificação também podem '
        'tratar dados conforme as permissões concedidas e as políticas desses '
        'serviços.',
  ),
  _SecaoDocumento(
    Icons.front_hand_outlined,
    '5. Seus cuidados e solicitações',
    'Não publique dados de terceiros sem autorização. Você pode gerenciar as '
        'permissões do dispositivo e encerrar a sessão no aplicativo; isso '
        'não necessariamente apaga os dados já salvos no aparelho ou enviados '
        'à API. Para solicitar acesso, correção ou exclusão de dados, entre '
        'em contato com o responsável pelo aplicativo pelo canal oficial, que '
        'deve ser divulgado antes da publicação pública.',
  ),
  _SecaoDocumento(
    Icons.lock_outline,
    '6. Segurança e atualização',
    'São adotadas medidas técnicas disponíveis na versão atual, mas nenhum '
        'meio de armazenamento ou transmissão é isento de riscos. Esta política '
        'deve ser atualizada se mudarem os dados coletados, os serviços '
        'integrados ou as finalidades de uso. A versão atual não define um '
        'prazo de retenção para dados enviados à API.',
  ),
];
