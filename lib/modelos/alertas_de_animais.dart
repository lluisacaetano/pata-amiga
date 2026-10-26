// Arquivo animal.dart: modelo do animal, o tipo e o responsável pelo registro.
import 'animal.dart';
// Arquivo avistamento.dart: avistamentos e o último avistamento de um animal.
import 'avistamento.dart';
// Arquivo ponto_de_alimentacao.dart: distância em metros entre dois pontos.
import 'ponto_de_alimentacao.dart';

// Distância máxima, em metros, entre a pessoa e o animal perdido para que
// ela seja notificada
const raioDaRegiao = 3000.0;

// Por quanto tempo depois de publicado um animal perdido gera notificação
const prazoDoAlerta = Duration(days: 7);

// O motivo da notificação: um animal perdido perto da pessoa ou um
// avistamento de um animal publicado por ela
enum TipoDeAlerta { perdidoPerto, avistado }

// Notificação sobre um animal, calculada no aparelho a partir dos animais,
// dos avistamentos e da posição da pessoa
class AlertaDeAnimal {
  final TipoDeAlerta tipo;
  final Animal animal;
  // Avistamento que gerou a notificação; nulo no animal perdido perto
  final Avistamento? avistamento;
  // Quando o fato aconteceu, usado para ordenar as notificações
  final DateTime em;

  const AlertaDeAnimal({
    required this.tipo,
    required this.animal,
    this.avistamento,
    required this.em,
  });

  // Identificador da notificação, guardado quando ela é dispensada
  String get chave => switch (tipo) {
    TipoDeAlerta.perdidoPerto => 'perdido:${animal.chave}',
    TipoDeAlerta.avistado =>
      'avistado:${avistamento?.id ?? avistamento?.registradoEm}',
  };

  // Bairro citado na notificação: o do avistamento ou o do cadastro
  String get bairro {
    final doAvistamento = avistamento?.bairro.trim() ?? '';
    return doAvistamento.isNotEmpty ? doAvistamento : animal.bairro;
  }
}

// Notificações de animais para o e-mail, da mais recente para a mais antiga:
// - animal perdido, ainda sem desfecho, publicado por outra pessoa dentro do
//   [prazoDoAlerta] e a até [raioDaRegiao] da [posicao]; sem posição, este
//   tipo não é calculado;
// - avistamento, registrado por outra pessoa dentro do [prazoDoAlerta], de
//   um animal publicado pelo e-mail e ainda sem desfecho.
// As notificações cujas chaves estão em [dispensadas] ficam de fora
List<AlertaDeAnimal> alertasDeAnimais({
  required Iterable<Animal> animais,
  required Iterable<Avistamento> avistamentos,
  required String email,
  required ({double latitude, double longitude})? posicao,
  required Set<String> dispensadas,
  required DateTime agora,
}) {
  if (email.trim().isEmpty) return const [];
  bool recente(DateTime quando) => agora.difference(quando) <= prazoDoAlerta;
  final porChave = {for (final animal in animais) animal.chave: animal};
  final alertas = <AlertaDeAnimal>[
    if (posicao != null)
      for (final animal in porChave.values)
        if (animal.tipo == TipoRegistro.perdido &&
            !animal.finalizado &&
            !animal.eDoResponsavel(email) &&
            recente(animal.publicadoEm) &&
            animal.latitude != null &&
            animal.longitude != null &&
            distanciaEmMetros(
                  posicao.latitude,
                  posicao.longitude,
                  animal.latitude!,
                  animal.longitude!,
                ) <=
                raioDaRegiao)
          AlertaDeAnimal(
            tipo: TipoDeAlerta.perdidoPerto,
            animal: animal,
            em: animal.publicadoEm,
          ),
    for (final avistamento in avistamentos)
      if (porChave[avistamento.animal] case final animal?
          when animal.eDoResponsavel(email) &&
              !animal.finalizado &&
              avistamento.email.trim().toLowerCase() !=
                  email.trim().toLowerCase() &&
              recente(avistamento.registradoEm))
        AlertaDeAnimal(
          tipo: TipoDeAlerta.avistado,
          animal: animal,
          avistamento: avistamento,
          em: avistamento.registradoEm,
        ),
  ];
  return alertas.where((alerta) => !dispensadas.contains(alerta.chave)).toList()
    ..sort((a, b) => b.em.compareTo(a.em));
}
