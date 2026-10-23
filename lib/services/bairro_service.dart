// Biblioteca dart:convert: converte texto JSON em objetos e vice-versa.
import 'dart:convert';

// Pacote http: faz as requisições à API (GET, POST, PATCH, DELETE).
import 'package:http/http.dart' as http;

// Arquivo bairros_formiga.dart: bairros de Formiga e a comparação de nomes.
import '../dados/bairros_formiga.dart';

// Descobre o bairro de um endereço pelo ViaCEP, a base pública de CEPs dos
// Correios. Complementa o geocoding do aparelho, que muitas vezes devolve o
// nome da cidade no lugar do bairro. Toda falha resulta em null
class BairroService {
  static const _viaCep = 'https://viacep.com.br/ws';

  // O bairro de um CEP de Formiga, desde que esteja na lista de bairros. CEPs
  // terminados em 000 são gerais da cidade e não indicam o bairro
  Future<String?> pelaCep(String? cep) async {
    final digitos = (cep ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8 || digitos.endsWith('000')) return null;
    try {
      final resposta = await http
          .get(Uri.parse('$_viaCep/$digitos/json/'))
          .timeout(const Duration(seconds: 6));
      if (resposta.statusCode != 200) return null;
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is! Map || dados['erro'] != null) return null;
      if (!mesmoBairro(dados['localidade']?.toString() ?? '', 'Formiga')) {
        return null;
      }
      return bairroDaLista(dados['bairro']?.toString() ?? '');
    } on Exception {
      return null;
    }
  }

  // O bairro de uma rua de Formiga, apenas quando a rua inteira fica em um
  // único bairro
  Future<String?> pelaRua(String rua) async {
    final nome = nomeDaRuaParaBusca(rua);
    if (nome.length < 3) return null;
    try {
      final resposta = await http
          .get(
            Uri.parse('$_viaCep/MG/Formiga/${Uri.encodeComponent(nome)}/json/'),
          )
          .timeout(const Duration(seconds: 6));
      if (resposta.statusCode != 200) return null;
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is! List) return null;
      return bairroUnicoDaRua(dados, nome);
    } on Exception {
      return null;
    }
  }
}

// Prepara o nome da rua para a busca no ViaCEP, que não aceita o tipo da via
// nem o número: "Rua do Expedicionário, 155" vira "do Expedicionário"
String nomeDaRuaParaBusca(String rua) {
  var nome = rua.split(',').first.trim();
  nome = nome.replaceFirst(
    RegExp(
      r'^(rua|avenida|av\.?|praça|praca|travessa|alameda|rodovia)\s+',
      caseSensitive: false,
    ),
    '',
  );
  return nome.trim();
}

// Entre os resultados do ViaCEP, devolve o bairro da rua quando há um só.
// Rua que atravessa mais de um bairro devolve null, e a pessoa escolhe
String? bairroUnicoDaRua(List<dynamic> resultados, String nome) {
  final bairros = <String>{};
  for (final item in resultados) {
    if (item is! Map) continue;
    final logradouro = item['logradouro']?.toString() ?? '';
    if (!mesmoBairro(nomeDaRuaParaBusca(logradouro), nome)) continue;
    final bairro = bairroDaLista(item['bairro']?.toString() ?? '');
    if (bairro != null) bairros.add(bairro);
  }
  return bairros.length == 1 ? bairros.single : null;
}
