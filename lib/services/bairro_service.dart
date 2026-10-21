import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dados/bairros_formiga.dart';

// O serviço de endereços do Android não conhece os bairros de Formiga e
// costuma devolver o nome da cidade no lugar deles. O ViaCEP, a base pública
// dos Correios, sabe: pelo CEP do ponto, ou pelo nome da rua
class BairroService {
  static const _viaCep = 'https://viacep.com.br/ws';

  // O bairro de um CEP, se ele for de uma rua (os CEPs terminados em 000 são
  // da cidade inteira e não dizem o bairro)
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

  // O bairro de uma rua de Formiga, só quando ela fica em um bairro só
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

// "Rua do Expedicionário, 155" vira "do Expedicionário": o ViaCEP busca pelo
// nome, sem o tipo da via e sem o número
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

// Dos resultados do ViaCEP, o bairro da rua quando ele é um só. Rua que
// atravessa mais de um bairro fica sem: melhor a pessoa escolher do que chutar
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
