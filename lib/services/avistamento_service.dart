import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/avistamento.dart';
import 'endereco_da_api.dart';

class AvistamentoService {
  Future<List<Avistamento>> buscarTodos() async {
    final resposta = await http
        .get(Uri.parse('$enderecoDaApi/avistamentos'))
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ${resposta.statusCode}');
    }
    final lista = jsonDecode(utf8.decode(resposta.bodyBytes)) as List;
    return lista
        .map((item) => Avistamento.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Devolve o avistamento como a API gravou, já com o id
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
