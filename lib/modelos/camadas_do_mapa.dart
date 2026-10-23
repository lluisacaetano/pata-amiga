// Arquivo animal.dart: modelo do animal e o tipo do registro.
import 'animal.dart';
// Arquivo avistamento.dart: avistamentos, que definem onde o perdido aparece.
import 'avistamento.dart';
// Arquivo ponto_de_alimentacao.dart: pontos de alimentação e distâncias.
import 'ponto_de_alimentacao.dart';

// As camadas do mapa: só perdido e resgate. Adoção fica fora, porque o
// ponto de um animal para adoção seria a casa de quem o oferece
const camadasDoMapa = [TipoRegistro.perdido, TipoRegistro.resgate];

// Os animais que aparecem no mapa com as camadas ligadas: precisam ter
// coordenada, que só existe quando o cadastro usou a localização
List<Animal> animaisNoMapa(
  Iterable<Animal> animais,
  Set<TipoRegistro> ligadas,
) => animais
    .where(
      (animal) =>
          animal.temPonto &&
          camadasDoMapa.contains(animal.tipo) &&
          ligadas.contains(animal.tipo),
    )
    .toList();

// Um pino no mapa: o animal, onde ele aparece e o avistamento que o pôs ali
typedef PinoDoMapa = ({
  Animal animal,
  double latitude,
  double longitude,
  Avistamento? ultimo,
});

// Os pinos do mapa. O perdido aparece no último lugar em que foi visto, e não
// mais onde foi cadastrado; por isso entra mesmo sem coordenada no cadastro,
// desde que alguém o tenha avistado
List<PinoDoMapa> pinosDoMapa(
  Iterable<Animal> animais,
  Iterable<Avistamento> avistamentos,
  Set<TipoRegistro> ligadas,
) {
  final pinos = <PinoDoMapa>[];
  for (final animal in animais) {
    if (!camadasDoMapa.contains(animal.tipo)) continue;
    // Encontrado ou resgatado não está mais lá para alguém ajudar
    if (animal.finalizado) continue;
    if (!ligadas.contains(animal.tipo)) continue;
    final ultimo = animal.tipo == TipoRegistro.perdido
        ? ultimoAvistamento(animal, avistamentos)
        : null;
    if (ultimo != null) {
      pinos.add((
        animal: animal,
        latitude: ultimo.latitude,
        longitude: ultimo.longitude,
        ultimo: ultimo,
      ));
    } else if (animal.temPonto) {
      pinos.add((
        animal: animal,
        latitude: animal.latitude!,
        longitude: animal.longitude!,
        ultimo: null,
      ));
    }
  }
  return pinos;
}

// O que está perto de quem tocou na mira: um animal ou um ponto de
// alimentação, com a distância até ele
typedef ItemPerto = ({
  PinoDoMapa? animal,
  PontoDeAlimentacao? ponto,
  double metros,
});

// O raio do "Perto de você"
const raioDePerto = 1000.0;

// Os animais e pontos das camadas ligadas a até 1 km, do mais perto para o
// mais longe
List<ItemPerto> pertoDe(
  double latitude,
  double longitude, {
  required Iterable<PinoDoMapa> animais,
  required Iterable<PontoDeAlimentacao> pontos,
}) {
  final itens = <ItemPerto>[
    for (final pino in animais)
      (
        animal: pino,
        ponto: null,
        metros: distanciaEmMetros(
          latitude,
          longitude,
          pino.latitude,
          pino.longitude,
        ),
      ),
    for (final ponto in pontos)
      (
        animal: null,
        ponto: ponto,
        metros: distanciaEmMetros(
          latitude,
          longitude,
          ponto.latitude,
          ponto.longitude,
        ),
      ),
  ];
  return itens.where((item) => item.metros <= raioDePerto).toList()
    ..sort((a, b) => a.metros.compareTo(b.metros));
}

// "350 m" até 1 km, arredondado de 10 em 10; depois, "1,2 km"
String textoDaDistancia(double metros) {
  if (metros < 1000) return '${(metros / 10).round() * 10} m';
  final km = (metros / 100).round() / 10;
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}
