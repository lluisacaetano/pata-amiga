import 'package:geolocator/geolocator.dart';

// Onde a pessoa está agora. Quando não dá para saber, o erro já vem com o
// texto para mostrar na tela
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

class ErroDeLocalizacao implements Exception {
  final String texto;
  const ErroDeLocalizacao(this.texto);
}
