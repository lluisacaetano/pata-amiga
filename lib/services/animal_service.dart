// Biblioteca dart:convert: converte texto JSON em objetos e vice-versa.
import 'dart:convert';

// Pacote http: faz as requisições à API (GET, POST, PATCH, DELETE).
import 'package:http/http.dart' as http;

// Arquivo animal.dart: modelo do animal.
import '../modelos/animal.dart';
// Arquivo endereco_da_api.dart: endereço base da API.
import 'endereco_da_api.dart';

// Leitura e gravação dos animais na API
class AnimalService {
  static final _baseUrl = enderecoDaApi;

  // Todos os animais da API; lança exceção se a resposta não for 200
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

  // Publica um animal novo na API
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

  // Altera apenas o status do animal na API. Animal sem id existe só no
  // aparelho e não é enviado
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

  // Substitui o registro inteiro do animal na API depois de uma edição.
  // Animal sem id existe só no aparelho e não é enviado
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
