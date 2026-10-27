// Biblioteca dart:convert: converte texto JSON em objetos e vice-versa.
import 'dart:convert';

// Pacote http: faz as requisições à API (GET, POST, PATCH, DELETE).
import 'package:http/http.dart' as http;

// Arquivo animal.dart: modelo do animal.
import '../modelos/animal.dart';
// Arquivo json_da_api.dart: leitura da lista sem os itens com defeito.
import '../modelos/json_da_api.dart';
// Arquivo endereco_da_api.dart: endereço base da API.
import 'endereco_da_api.dart';

// Leitura e gravação dos animais na API
class AnimalService {
  // Todos os animais da API; lança exceção se a resposta não for 200. Um
  // animal com defeito no JSON fica de fora, sem derrubar a lista
  Future<List<Animal>> buscarAnimais() async {
    final resp = await http
        .get(Uri.parse('$enderecoDaApi/animais'))
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) {
      throw Exception('Erro ${resp.statusCode}');
    }
    final lista = jsonDecode(utf8.decode(resp.bodyBytes)) as List;
    return itensValidos(lista, Animal.fromJson);
  }

  // Publica um animal novo na API
  Future<void> criarAnimal(Animal animal) async {
    final resp = await http
        .post(
          Uri.parse('$enderecoDaApi/animais'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(animal.toJson()),
        )
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Erro ${resp.statusCode}');
    }
  }

  // Altera o status do animal na API e grava o histórico de [animal], que já
  // deve trazer a etapa da mudança. Animal sem id existe só no aparelho e não
  // é enviado
  Future<void> atualizarStatus(Animal animal, StatusAnimal novo) async {
    final id = animal.id;
    if (id == null) return;
    final resp = await http
        .patch(
          Uri.parse('$enderecoDaApi/animais/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'status': novo.name,
            'historico': [for (final etapa in animal.historico) etapa.toJson()],
          }),
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
          Uri.parse('$enderecoDaApi/animais/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(animal.toJson()),
        )
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) {
      throw Exception('Erro ${resp.statusCode}');
    }
  }
}
