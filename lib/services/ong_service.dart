import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/ong.dart';
import 'endereco_da_api.dart';

// A pessoa do pedido já faz parte de outra ONG: aprovar a deixaria em duas
class JaFazParteDeOutra implements Exception {
  final String ong;

  const JaFazParteDeOutra(this.ong);
}

// O pedido já não existe na API: a pessoa desistiu ou outra admin respondeu
class PedidoNaoExiste implements Exception {
  const PedidoNaoExiste();
}

// A pessoa escolhida para administrar já não é membro da ONG
class NaoEMembro implements Exception {
  const NaoEMembro();
}

class OngService {
  Future<List<Ong>> buscarOngs() async {
    final resposta = await http
        .get(Uri.parse('$enderecoDaApi/ongs'))
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ${resposta.statusCode}');
    }
    return (jsonDecode(utf8.decode(resposta.bodyBytes)) as List)
        .map((item) => Ong.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Ong> buscarOng(int id) async {
    final resposta = await http
        .get(Uri.parse('$enderecoDaApi/ongs/$id'))
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ${resposta.statusCode}');
    }
    return Ong.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }

  // O pedido e a resposta partem da versão da API, e não da que o app
  // guardou: outra pessoa pode ter pedido para entrar nesse meio-tempo
  // Cada conta tem no máximo uma ONG: quem já faz parte de outra, ou já
  // pediu para entrar em outra, não pede de novo
  Future<Ong> pedirEntrada(Ong ong, PessoaDaOng pessoa) async {
    for (final outra in await buscarOngs()) {
      if (outra.id != ong.id &&
          (outra.fazParte(pessoa.email) || outra.pediuEntrada(pessoa.email))) {
        throw JaFazParteDeOutra(outra.nome);
      }
    }
    return salvarOng((await buscarOng(ong.id!)).comPedidoDe(pessoa));
  }

  Future<Ong> responderPedido(
    Ong ong,
    String email, {
    required bool aprovar,
  }) async {
    if (aprovar) {
      for (final outra in await buscarOngs()) {
        if (outra.id != ong.id && outra.fazParte(email)) {
          throw JaFazParteDeOutra(outra.nome);
        }
      }
    }
    final naApi = await buscarOng(ong.id!);
    if (!naApi.pediuEntrada(email)) throw const PedidoNaoExiste();
    return salvarOng(naApi.respondendo(email, aprovar: aprovar));
  }

  // A admin remove um membro, que recebe o aviso no sino
  Future<Ong> removerMembro(Ong ong, String email) async =>
      salvarOng((await buscarOng(ong.id!)).removendo(email));

  // A pessoa removida dispensa o aviso
  Future<Ong> dispensarAviso(Ong ong, String email) async =>
      salvarOng((await buscarOng(ong.id!)).semAviso(email));

  // Sair da ONG, ou cancelar o pedido para entrar nela
  Future<Ong> sairDaOng(Ong ong, String email) async =>
      salvarOng((await buscarOng(ong.id!)).semAPessoa(email));

  // A admin escolhe um membro para administrar a ONG e sai dela
  Future<Ong> passarAdministracao(Ong ong, String paraEmail) async {
    final naApi = await buscarOng(ong.id!);
    if (!naApi.fazParte(paraEmail) || naApi.eDoResponsavel(paraEmail)) {
      throw const NaoEMembro();
    }
    return salvarOng(naApi.passandoPara(paraEmail));
  }

  // Cria a ONG, ou grava a edição quando ela já tem id. Devolve o que a API
  // gravou, já com o id
  Future<Ong> salvarOng(Ong ong) async {
    final nova = ong.id == null;
    final endereco = Uri.parse(
      nova ? '$enderecoDaApi/ongs' : '$enderecoDaApi/ongs/${ong.id}',
    );
    final corpo = jsonEncode(ong.toJson());
    const cabecalho = {'Content-Type': 'application/json'};
    final resposta =
        await (nova
                ? http.post(endereco, headers: cabecalho, body: corpo)
                : http.put(endereco, headers: cabecalho, body: corpo))
            .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200 && resposta.statusCode != 201) {
      throw Exception('Erro ${resposta.statusCode}');
    }
    return Ong.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }
}
