// Biblioteca dart:convert: converte texto JSON em objetos e vice-versa.
import 'dart:convert';

// Pacote http: faz as requisições à API (GET, POST, PATCH, DELETE).
import 'package:http/http.dart' as http;

// Arquivo ong.dart: modelo da ONG e das pessoas ligadas a ela.
import '../modelos/ong.dart';
// Arquivo endereco_da_api.dart: endereço base da API.
import 'endereco_da_api.dart';

// Lançada quando a pessoa já faz parte de outra ONG (ou pediu para entrar
// nela); cada conta pode estar em uma ONG só
class JaFazParteDeOutra implements Exception {
  final String ong;

  const JaFazParteDeOutra(this.ong);
}

// Lançada quando o pedido de entrada já não existe na API: a pessoa
// desistiu ou ele já foi respondido
class PedidoNaoExiste implements Exception {
  const PedidoNaoExiste();
}

// Lançada quando a pessoa escolhida para administrar não é membro da ONG
class NaoEMembro implements Exception {
  const NaoEMembro();
}

// Leitura e gravação das ONGs e dos vínculos das pessoas com elas. Cada
// operação lê a versão atual da ONG na API antes de gravar, para não
// sobrescrever mudanças feitas por outra pessoa
class OngService {
  // Todas as ONGs cadastradas
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

  // Uma ONG pelo id
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

  // Registra o pedido de entrada da pessoa na ONG. Recusa com
  // JaFazParteDeOutra se ela já faz parte de outra ONG ou já pediu para
  // entrar em outra
  Future<Ong> pedirEntrada(Ong ong, PessoaDaOng pessoa) async {
    for (final outra in await buscarOngs()) {
      if (outra.id != ong.id &&
          (outra.fazParte(pessoa.email) || outra.pediuEntrada(pessoa.email))) {
        throw JaFazParteDeOutra(outra.nome);
      }
    }
    return salvarOng((await buscarOng(ong.id!)).comPedidoDe(pessoa));
  }

  // Aprova ou recusa o pedido de entrada. Na aprovação, confere de novo se
  // a pessoa não entrou em outra ONG nesse meio-tempo
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

  // Remove um membro da ONG e deixa um aviso para ele no sino
  Future<Ong> removerMembro(Ong ong, String email) async =>
      salvarOng((await buscarOng(ong.id!)).removendo(email));

  // Apaga o aviso deixado para a pessoa, depois que ela o dispensa
  Future<Ong> dispensarAviso(Ong ong, String email) async =>
      salvarOng((await buscarOng(ong.id!)).semAviso(email));

  // Tira a pessoa da ONG ou cancela o pedido de entrada dela
  Future<Ong> sairDaOng(Ong ong, String email) async =>
      salvarOng((await buscarOng(ong.id!)).semAPessoa(email));

  // Transfere a administração para um membro; quem administrava sai da ONG
  Future<Ong> passarAdministracao(Ong ong, String paraEmail) async {
    final naApi = await buscarOng(ong.id!);
    if (!naApi.fazParte(paraEmail) || naApi.eDoResponsavel(paraEmail)) {
      throw const NaoEMembro();
    }
    return salvarOng(naApi.passandoPara(paraEmail));
  }

  // Cria a ONG (POST) quando ela ainda não tem id, ou substitui o registro
  // (PUT) quando já tem. Devolve a ONG como a API gravou
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
