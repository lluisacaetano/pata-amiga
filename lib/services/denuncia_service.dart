import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/denuncia.dart';
import 'endereco_da_api.dart';

class DenunciaService {
  // Os protocolos das denúncias feitas neste aparelho, inclusive as
  // anônimas: é por eles que "Minhas denúncias" acha cada uma na API
  static const _chaveDosProtocolos = 'minhas_denuncias';

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

  Future<List<String>> protocolosDoAparelho() async {
    final armazenamento = await SharedPreferences.getInstance();
    return armazenamento.getStringList(_chaveDosProtocolos) ?? const [];
  }

  // As denúncias feitas neste aparelho, com a situação atual da API, da mais
  // nova para a mais antiga
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
