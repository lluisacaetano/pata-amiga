import 'dart:convert';
import 'package:http/http.dart' as http;
import '../modelos/animal.dart';
import 'endereco_da_api.dart';

class AnimalService {
  static const _baseUrl = enderecoDaApi;

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
    Future<void> criarAnimal(Animal animal) async {
    final resp = await http
        .post(
          Uri.parse('$_baseUrl/animais'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(animal.toJson()),
        )
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Erro ${resp.statusCode}');
    }
  }

}