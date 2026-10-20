import 'animal.dart';

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
