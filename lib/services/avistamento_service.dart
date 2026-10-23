// Biblioteca dart:convert: converte texto JSON em objetos e vice-versa.
import 'dart:convert';

// Pacote http: faz as requisições à API (GET, POST, PATCH, DELETE).
import 'package:http/http.dart' as http;

// Arquivo avistamento.dart: modelo do avistamento.
import '../modelos/avistamento.dart';
// Arquivo json_da_api.dart: leitura da lista sem os itens com defeito.
import '../modelos/json_da_api.dart';
// Arquivo endereco_da_api.dart: endereço base da API.
import 'endereco_da_api.dart';

// Leitura e gravação dos avistamentos de animais perdidos na API
class AvistamentoService {
  // Todos os avistamentos registrados; o item com defeito fica de fora
  Future<List<Avistamento>> buscarTodos() async {
    final resposta = await http
        .get(Uri.parse('$enderecoDaApi/avistamentos'))
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ${resposta.statusCode}');
    }
    final lista = jsonDecode(utf8.decode(resposta.bodyBytes)) as List;
    return itensValidos(lista, Avistamento.fromJson);
  }

  // Grava um avistamento e o devolve como a API gravou, já com o id
  Future<Avistamento> registrar(Avistamento avistamento) async {
    final resposta = await http
        .post(
          Uri.parse('$enderecoDaApi/avistamentos'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(avistamento.toJson()),
        )
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200 && resposta.statusCode != 201) {
      throw Exception('Erro ${resposta.statusCode}');
    }
    return Avistamento.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }
}
