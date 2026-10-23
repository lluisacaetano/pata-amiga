// Biblioteca dart:async: TimeoutException, quando a posição demora demais.
import 'dart:async';

// Pacote flutter/foundation: plataforma em execução (defaultTargetPlatform).
import 'package:flutter/foundation.dart';
// Pacote geolocator: lê a localização atual do aparelho e pede a permissão.
import 'package:geolocator/geolocator.dart';

// Obtém a posição atual do aparelho, pedindo a permissão quando preciso. Em
// caso de falha, lança ErroDeLocalizacao com a mensagem pronta para a tela.
// [alternativa] completa a mensagem com o que a pessoa pode fazer no lugar,
// por exemplo "Insira o endereço manualmente."
class LocalizacaoService {
  final String alternativa;

  const LocalizacaoService({this.alternativa = 'Tente de novo.'});

  Future<({double latitude, double longitude})> posicaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw ErroDeLocalizacao(
        'Ligue a localização do aparelho para usar sua posição.',
      );
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      throw ErroDeLocalizacao('Sem permissão de localização. $alternativa');
    }
    try {
      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: _ajustes(),
      );
      return (latitude: posicao.latitude, longitude: posicao.longitude);
    } on TimeoutException {
      throw ErroDeLocalizacao('A localização demorou demais. $alternativa');
    } on Exception {
      throw ErroDeLocalizacao(
        'Não foi possível encontrar sua localização. $alternativa',
      );
    }
  }

  // Prazo de 15 segundos para a posição. No Android, usa o LocationManager do
  // sistema em vez do provedor do Google, que exigiria a precisão do Google
  // ligada e um diálogo extra
  static LocationSettings _ajustes() {
    const prazo = Duration(seconds: 15);
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(forceLocationManager: true, timeLimit: prazo);
    }
    return const LocationSettings(timeLimit: prazo);
  }
}

// Falha ao obter a localização, com o texto a exibir para a pessoa
class ErroDeLocalizacao implements Exception {
  final String texto;
  const ErroDeLocalizacao(this.texto);
}
