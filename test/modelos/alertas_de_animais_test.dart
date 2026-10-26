// Pacote flutter_test: ferramentas de teste de widgets e de unidade do Flutter.
import 'package:flutter_test/flutter_test.dart';
// Arquivo alertas_de_animais.dart: notificações de perdidos e avistamentos.
import 'package:pata_amiga/modelos/alertas_de_animais.dart';
// Arquivo animal.dart: modelo do animal, o tipo e o status.
import 'package:pata_amiga/modelos/animal.dart';
// Arquivo avistamento.dart: modelo do avistamento.
import 'package:pata_amiga/modelos/avistamento.dart';
// Arquivo animais_mock.dart: animais de exemplo usados como base.
import 'package:pata_amiga/dados/animais_mock.dart';

void main() {
  final agora = DateTime(2026, 10, 26, 12);
  // Posição de quem recebe a notificação, na Praça São Vicente Ferrer
  const praca = (latitude: -20.4637, longitude: -45.4263);

  // Animal perdido de exemplo, publicado por outra pessoa perto da praça
  Animal perdido({
    String id = '10',
    String email = 'outra@example.com',
    double latitude = -20.4650,
    StatusAnimal status = StatusAnimal.disponivel,
    TipoRegistro tipo = TipoRegistro.perdido,
    Duration publicadoHa = const Duration(days: 1),
  }) => Animal.fromJson({
    ...animaisMock.first.toJson(),
    'id': id,
    'nome': 'Thor',
    'tipo': tipo.name,
    'status': status.name,
    'responsavelEmail': email,
    'latitude': latitude,
    'longitude': -45.4263,
    'publicadoEm': agora.subtract(publicadoHa).toIso8601String(),
  });

  // Avistamento de exemplo do animal de id [animal]
  Avistamento visto(
    String animal, {
    String email = 'outra@example.com',
    Duration ha = const Duration(hours: 3),
  }) => Avistamento(
    id: 'a$animal',
    animal: animal,
    data: agora.subtract(ha),
    latitude: -20.46,
    longitude: -45.42,
    bairro: 'Centro',
    email: email,
    registradoEm: agora.subtract(ha),
  );

  // Calcula as notificações de eu@example.com com os dados informados
  List<AlertaDeAnimal> alertas(
    List<Animal> animais, {
    List<Avistamento> avistamentos = const [],
    ({double latitude, double longitude})? posicao = praca,
    Set<String> dispensadas = const {},
  }) => alertasDeAnimais(
    animais: animais,
    avistamentos: avistamentos,
    email: 'eu@example.com',
    posicao: posicao,
    dispensadas: dispensadas,
    agora: agora,
  );

  group('notificação de animal perdido na região', () {
    // Perdido recente, de outra pessoa e a menos de 3 km vira notificação
    test('o perdido recente perto de quem está logado notifica', () {
      final lista = alertas([perdido()]);
      expect(lista, hasLength(1));
      expect(lista.single.tipo, TipoDeAlerta.perdidoPerto);
    });

    // A cerca de 5,5 km de distância, o animal está fora da região
    test('o perdido longe, fora do raio, não notifica', () {
      expect(alertas([perdido(latitude: -20.4140)]), isEmpty);
    });

    // Sem a posição do aparelho, não há como saber a região
    test('sem a posição do aparelho, não há notificação de região', () {
      expect(alertas([perdido()], posicao: null), isEmpty);
    });

    // O próprio animal, o já encontrado, o antigo e o de adoção ficam fora
    test('o meu, o encontrado, o antigo e o de adoção não notificam', () {
      expect(
        alertas([
          perdido(id: '1', email: 'eu@example.com'),
          perdido(id: '2', status: StatusAnimal.encontrado),
          perdido(id: '3', publicadoHa: const Duration(days: 8)),
          perdido(id: '4', tipo: TipoRegistro.adocao),
        ]),
        isEmpty,
      );
    });

    // A notificação dispensada não volta a aparecer
    test('a notificação dispensada não aparece de novo', () {
      final chave = alertas([perdido()]).single.chave;
      expect(alertas([perdido()], dispensadas: {chave}), isEmpty);
    });
  });

  group('notificação de avistamento', () {
    // Quem publicou o animal é notificado quando outra pessoa o vê
    test('o avistamento do meu animal por outra pessoa notifica', () {
      final lista = alertas(
        [perdido(email: 'eu@example.com')],
        avistamentos: [visto('10')],
        posicao: null,
      );
      expect(lista, hasLength(1));
      expect(lista.single.tipo, TipoDeAlerta.avistado);
      expect(lista.single.bairro, 'Centro');
    });

    // O avistamento registrado pelo próprio dono e o de animal alheio não
    // notificam
    test('o meu avistamento e o de animal alheio não notificam', () {
      expect(
        alertas(
          [perdido(email: 'eu@example.com'), perdido(id: '11')],
          avistamentos: [
            visto('10', email: 'eu@example.com'),
            visto('11'),
          ],
          posicao: null,
        ),
        isEmpty,
      );
    });

    // As notificações saem da mais recente para a mais antiga
    test('as notificações saem da mais recente para a mais antiga', () {
      final lista = alertas(
        [perdido(id: '10', email: 'eu@example.com'), perdido(id: '12')],
        avistamentos: [visto('10', ha: const Duration(days: 2))],
      );
      expect(lista.map((alerta) => alerta.tipo), [
        TipoDeAlerta.perdidoPerto,
        TipoDeAlerta.avistado,
      ]);
    });
  });
}
