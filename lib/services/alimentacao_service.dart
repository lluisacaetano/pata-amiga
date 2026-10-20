import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/ponto_de_alimentacao.dart';
import 'endereco_da_api.dart';

class AlimentacaoService {
  Future<List<dynamic>> _buscar(String colecao) async {
    final resposta = await http
        .get(Uri.parse('$enderecoDaApi/$colecao'))
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ${resposta.statusCode}');
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes)) as List;
  }

  Future<Map<String, dynamic>> _gravar(
    String colecao,
    Map<String, dynamic> dados,
  ) async {
    final resposta = await http
        .post(
          Uri.parse('$enderecoDaApi/$colecao'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(dados),
        )
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200 && resposta.statusCode != 201) {
      throw Exception('Erro ${resposta.statusCode}');
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<PontoDeAlimentacao>> buscarPontos() async =>
      (await _buscar('pontosAlimentacao'))
          .map(
            (item) => PontoDeAlimentacao.fromJson(item as Map<String, dynamic>),
          )
          .toList();

  Future<List<Abastecimento>> buscarAbastecimentos() async =>
      (await _buscar('abastecimentos'))
          .map((item) => Abastecimento.fromJson(item as Map<String, dynamic>))
          .toList();

  // Devolvem o que a API gravou, já com o id
  Future<PontoDeAlimentacao> cadastrarPonto(PontoDeAlimentacao ponto) async =>
      PontoDeAlimentacao.fromJson(
        await _gravar('pontosAlimentacao', ponto.toJson()),
      );

  Future<Abastecimento> registrarAbastecimento(
    Abastecimento abastecimento,
  ) async => Abastecimento.fromJson(
    await _gravar('abastecimentos', abastecimento.toJson()),
  );
}
