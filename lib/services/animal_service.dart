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

  // Muda só o status na API. Animal que ainda não está na API (sem id) não
  // tem o que atualizar lá
  Future<void> atualizarStatus(Animal animal, StatusAnimal novo) async {
    final id = animal.id;
    if (id == null) return;
    final resp = await http
        .patch(
          Uri.parse('$_baseUrl/animais/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': novo.name}),
        )
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) {
      throw Exception('Erro ${resp.statusCode}');
    }
  }

  // Grava o registro editado inteiro. Como no status, animal sem id ainda não
  // está na API e fica só no aparelho
  Future<void> atualizarAnimal(Animal animal) async {
    final id = animal.id;
    if (id == null) return;
    final resp = await http
        .put(
          Uri.parse('$_baseUrl/animais/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(animal.toJson()),
        )
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) {
      throw Exception('Erro ${resp.statusCode}');
    }
  }
}
