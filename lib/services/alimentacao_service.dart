// Biblioteca dart:convert: converte texto JSON em objetos e vice-versa.
import 'dart:convert';

// Pacote http: faz as requisições à API (GET, POST, PATCH, DELETE).
import 'package:http/http.dart' as http;

// Arquivo json_da_api.dart: leitura da lista sem os itens com defeito.
import '../modelos/json_da_api.dart';
// Arquivo ponto_de_alimentacao.dart: modelos do ponto e do abastecimento.
import '../modelos/ponto_de_alimentacao.dart';
// Arquivo endereco_da_api.dart: endereço base da API.
import 'endereco_da_api.dart';

// Leitura e gravação dos comedouros, bebedouros e abastecimentos na API
class AlimentacaoService {
  // Lê uma coleção inteira da API; lança exceção se a resposta não for 200
  Future<List<dynamic>> _buscar(String colecao) async {
    final resposta = await http
        .get(Uri.parse('$enderecoDaApi/$colecao'))
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ${resposta.statusCode}');
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes)) as List;
  }

  // Cria um item na coleção e devolve o JSON gravado pela API
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

  // Os comedouros e bebedouros; o item com defeito fica de fora
  Future<List<PontoDeAlimentacao>> buscarPontos() async => itensValidos(
    await _buscar('pontosAlimentacao'),
    PontoDeAlimentacao.fromJson,
  );

  // Os abastecimentos registrados; o item com defeito fica de fora
  Future<List<Abastecimento>> buscarAbastecimentos() async =>
      itensValidos(await _buscar('abastecimentos'), Abastecimento.fromJson);

  // Os dois cadastros devolvem o item como a API gravou, já com o id
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
