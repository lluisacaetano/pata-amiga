// Pacote geolocator: lê a localização atual do aparelho e pede a permissão.
import 'package:geolocator/geolocator.dart';

// Obtém a posição atual do aparelho, pedindo a permissão quando preciso. Em
// caso de falha, lança ErroDeLocalizacao com a mensagem pronta para a tela
class LocalizacaoService {
  Future<({double latitude, double longitude})> posicaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ErroDeLocalizacao(
        'Ligue a localização do aparelho para confirmar onde você está.',
      );
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      throw const ErroDeLocalizacao(
        'Sem permissão de localização não dá para confirmar onde você está.',
      );
    }
    try {
      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (latitude: posicao.latitude, longitude: posicao.longitude);
    } on Exception {
      throw const ErroDeLocalizacao(
        'Não foi possível encontrar sua localização. Tente de novo.',
      );
    }
  }
}

// Falha ao obter a localização, com o texto a exibir para a pessoa
class ErroDeLocalizacao implements Exception {
  final String texto;
  const ErroDeLocalizacao(this.texto);
}
