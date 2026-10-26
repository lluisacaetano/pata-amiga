// Arquivo alertas_de_animais.dart: prazo das notificações (prazoDoAlerta).
import 'alertas_de_animais.dart';
// Arquivo denuncia.dart: modelo da denúncia e as situações.
import 'denuncia.dart';

// O motivo da notificação de denúncia: uma denúncia nova para a organização
// ou uma mudança de situação para quem denunciou
enum TipoDeAvisoDeDenuncia { nova, situacao }

// Notificação sobre uma denúncia, calculada no aparelho
class AvisoDeDenuncia {
  final TipoDeAvisoDeDenuncia tipo;
  final Denuncia denuncia;
  // Quando o fato aconteceu, usado para ordenar as notificações
  final DateTime em;

  const AvisoDeDenuncia({
    required this.tipo,
    required this.denuncia,
    required this.em,
  });

  // Identificador da notificação, guardado quando ela é dispensada. Na
  // mudança de situação, inclui o número de etapas, para cada mudança gerar
  // a sua notificação
  String get chave => switch (tipo) {
    TipoDeAvisoDeDenuncia.nova => 'denuncia:${denuncia.id}',
    TipoDeAvisoDeDenuncia.situacao =>
      'situacao:${denuncia.id}:${denuncia.historico.length}',
  };
}

// Notificações de denúncias, da mais recente para a mais antiga:
// - para a organização, cada denúncia recebida ainda sem nenhuma mudança de
//   situação, registrada dentro do [prazoDoAlerta];
// - para quem denunciou, a última mudança de situação das denúncias feitas
//   no aparelho, dentro do mesmo prazo.
// As notificações cujas chaves estão em [dispensadas] ficam de fora
List<AvisoDeDenuncia> avisosDeDenuncia({
  required Iterable<Denuncia> daOrganizacao,
  required Iterable<Denuncia> minhas,
  required Set<String> dispensadas,
  required DateTime agora,
}) {
  bool recente(DateTime quando) => agora.difference(quando) <= prazoDoAlerta;
  final avisos = <AvisoDeDenuncia>[
    for (final denuncia in daOrganizacao)
      if (denuncia.historico.length <= 1 && recente(denuncia.registradaEm))
        AvisoDeDenuncia(
          tipo: TipoDeAvisoDeDenuncia.nova,
          denuncia: denuncia,
          em: denuncia.registradaEm,
        ),
    for (final denuncia in minhas)
      if (denuncia.historico.length > 1 && recente(denuncia.historico.last.em))
        AvisoDeDenuncia(
          tipo: TipoDeAvisoDeDenuncia.situacao,
          denuncia: denuncia,
          em: denuncia.historico.last.em,
        ),
  ];
  return avisos.where((aviso) => !dispensadas.contains(aviso.chave)).toList()
    ..sort((a, b) => b.em.compareTo(a.em));
}
