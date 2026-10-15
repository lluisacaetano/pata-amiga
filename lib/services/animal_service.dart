import 'dart:convert';
import 'package:http/http.dart' as http;
import '../modelos/animal.dart';

class AnimalService {
  // Chrome: localhost | Emulador Android: 10.0.2.2 | Celular: IP do PC
  
  static const _baseUrl = 'http://10.0.2.2:3000';

  Future<List<Animal>> buscarAnimais() async {
    final resp = await http
        .get(Uri.parse('$_baseUrl/animais'))
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) {
      throw Exception('Erro ${resp.statusCode}');
    }
    final lista = jsonDecode(utf8.decode(resp.bodyBytes)) as List;
    return lista
        .map((e) => Animal.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}