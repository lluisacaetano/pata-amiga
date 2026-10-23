// Biblioteca dart:convert: converte texto JSON em objetos e vice-versa.
import 'dart:convert';

// Pacote http: faz as requisições à API (GET, POST, PATCH, DELETE).
import 'package:http/http.dart' as http;
// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';

// Arquivo denuncia.dart: modelo da denúncia.
import '../modelos/denuncia.dart';
// Arquivo endereco_da_api.dart: endereço base da API.
import 'endereco_da_api.dart';

// Registro das denúncias na API e controle das que foram feitas neste
// aparelho
class DenunciaService {
  // Chave da lista de protocolos das denúncias feitas neste aparelho,
  // inclusive as anônimas. "Minhas denúncias" localiza cada uma na API por eles
  static const _chaveDosProtocolos = 'minhas_denuncias';

  // Envia a denúncia à API, guarda o protocolo no aparelho e devolve a
  // denúncia como a API gravou
  Future<Denuncia> registrar(Denuncia denuncia) async {
    final resposta = await http
        .post(
          Uri.parse('$enderecoDaApi/denuncias'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(denuncia.toJson()),
        )
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200 && resposta.statusCode != 201) {
      throw Exception('Erro ${resposta.statusCode}');
    }
    final gravada = Denuncia.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
    await guardarProtocolo(gravada.protocolo);
    return gravada;
  }

  // Acrescenta o protocolo no início da lista do aparelho, sem repetir
  Future<void> guardarProtocolo(String protocolo) async {
    final armazenamento = await SharedPreferences.getInstance();
    final protocolos = armazenamento.getStringList(_chaveDosProtocolos) ?? [];
    if (!protocolos.contains(protocolo)) {
      await armazenamento.setStringList(_chaveDosProtocolos, [
        protocolo,
        ...protocolos,
      ]);
    }
  }

  // Os protocolos guardados, do mais recente para o mais antigo
  Future<List<String>> protocolosDoAparelho() async {
    final armazenamento = await SharedPreferences.getInstance();
    return armazenamento.getStringList(_chaveDosProtocolos) ?? const [];
  }

  // As denúncias feitas neste aparelho, com a situação atual da API, da mais
  // nova para a mais antiga. Sem protocolos guardados, nem consulta a API
  Future<List<Denuncia>> minhasDenuncias() async {
    final protocolos = (await protocolosDoAparelho()).toSet();
    if (protocolos.isEmpty) return const [];
    final resposta = await http
        .get(Uri.parse('$enderecoDaApi/denuncias'))
        .timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ${resposta.statusCode}');
    }
    return (jsonDecode(utf8.decode(resposta.bodyBytes)) as List)
        .map((item) => Denuncia.fromJson(item as Map<String, dynamic>))
        .where((denuncia) => protocolos.contains(denuncia.protocolo))
        .toList()
      ..sort((a, b) => b.registradaEm.compareTo(a.registradaEm));
  }
}
