import 'package:flutter/material.dart';

import '../../tema/cores.dart';

enum TipoDocumentoLegal { termos, privacidade }

class DocumentoLegalScreen extends StatelessWidget {
  const DocumentoLegalScreen({super.key, required this.tipo});

  final TipoDocumentoLegal tipo;

  @override
  Widget build(BuildContext context) {
    final titulo = switch (tipo) {
      TipoDocumentoLegal.termos => 'Termos de Uso',
      TipoDocumentoLegal.privacidade => 'Política de Privacidade',
    };
    final secoes = switch (tipo) {
      TipoDocumentoLegal.termos => _termos,
      TipoDocumentoLegal.privacidade => _privacidade,
    };

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Rascunho informativo — atualizado em 22 de outubro de 2026.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final secao in secoes) ...[
            Text(
              secao.titulo,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(secao.conteudo, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
          Card(
            color: context.cores.destaque.withValues(alpha: 0.15),
            child: const Padding(padding: EdgeInsets.all(12)),
          ),
        ],
      ),
    );
  }
}

class _SecaoDocumento {
  const _SecaoDocumento(this.titulo, this.conteudo);

  final String titulo;
  final String conteudo;
}

const _termos = [
  _SecaoDocumento(
    '1. Sobre o aplicativo',
    'O Pata Amiga é uma ferramenta de apoio para divulgar animais para '
        'adoção, perdidos ou resgatados, além de informações comunitárias '
        'sobre avistamentos e pontos de alimentação. O aplicativo não '
        'substitui serviços veterinários, órgãos públicos ou serviços de '
        'emergência.',
  ),
  _SecaoDocumento(
    '2. Cadastro e funcionamento',
    'Na versão atual, os dados do perfil e a sessão são mantidos localmente '
        'no dispositivo. O campo de senha do formulário não é usado para '
        'autenticação nem armazenado pelo aplicativo. Não compartilhe uma '
        'senha que você use em outros serviços.',
  ),
  _SecaoDocumento(
    '3. Conteúdo publicado',
    'Você é responsável pela exatidão e atualização das informações que '
        'publicar e por ter autorização para compartilhar dados de contato, '
        'imagens e demais informações de outras pessoas. Publicações podem '
        'ficar visíveis a outros usuários. Evite incluir dados pessoais '
        'desnecessários e confirme diretamente as informações antes de '
        'qualquer adoção ou encontro.',
  ),
  _SecaoDocumento(
    '4. Uso adequado',
    'Não use o aplicativo para publicar informações falsas, violar direitos '
        'de terceiros, assediar pessoas, praticar atividades ilegais ou '
        'comprometer a segurança de animais e usuários. Ao identificar um '
        'risco ou uma informação desatualizada, use os recursos de denúncia '
        'disponíveis no aplicativo.',
  ),
  _SecaoDocumento(
    '5. Limites do serviço',
    'As informações são fornecidas pelos usuários e podem não ser verificadas '
        'ou estar atualizadas. O aplicativo não garante a disponibilidade do '
        'serviço, a localização de um animal, a veracidade de anúncios ou o '
        'resultado de uma adoção. Tome precauções e não envie dinheiro ou '
        'informações financeiras a pessoas desconhecidas.',
  ),
  _SecaoDocumento(
    '6. Alterações e contato',
    'Estes termos podem ser atualizados quando o aplicativo mudar. A versão '
        'vigente deve estar disponível no aplicativo. Para dúvidas, remoção '
        'de conteúdo ou solicitações relacionadas ao uso, procure o canal '
        'oficial de contato do responsável pelo Pata Amiga, que deve ser '
        'informado antes da publicação oficial.',
  ),
];

const _privacidade = [
  _SecaoDocumento(
    '1. Quem trata os dados',
    'O responsável legal pelo tratamento dos dados e seu canal de contato '
        'ainda precisam ser identificados pelo responsável pelo aplicativo '
        'antes da disponibilização pública desta política.',
  ),
  _SecaoDocumento(
    '2. Dados tratados',
    'O cadastro solicita nome, e-mail e telefone. Na versão atual, essas '
        'informações de perfil e a identificação da sessão são salvas no '
        'armazenamento local do dispositivo. O formulário também solicita '
        'uma senha, mas o aplicativo não a utiliza para autenticação nem a '
        'armazena. Registros de animais, contatos informados, avistamentos, '
        'pontos de alimentação, fotos e informações de localização podem ser '
        'incluídos nas publicações conforme os campos preenchidos.',
  ),
  _SecaoDocumento(
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
    '5. Seus cuidados e solicitações',
    'Não publique dados de terceiros sem autorização. Você pode gerenciar as '
        'permissões do dispositivo e encerrar a sessão no aplicativo; isso '
        'não necessariamente apaga os dados já salvos no aparelho ou enviados '
        'à API. Para solicitar acesso, correção ou exclusão de dados, entre '
        'em contato com o responsável pelo aplicativo pelo canal oficial, que '
        'deve ser divulgado antes da publicação pública.',
  ),
  _SecaoDocumento(
    '6. Segurança e atualização',
    'São adotadas medidas técnicas disponíveis na versão atual, mas nenhum '
        'meio de armazenamento ou transmissão é isento de riscos. Esta política '
        'deve ser atualizada se mudarem os dados coletados, os serviços '
        'integrados ou as finalidades de uso. A versão atual não define um '
        'prazo de retenção para dados enviados à API.',
  ),
];
