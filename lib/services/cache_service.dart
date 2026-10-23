// Biblioteca dart:convert: converte texto JSON em objetos e vice-versa.
import 'dart:convert';

// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';

// Arquivo animal.dart: modelo do animal guardado no cache.
import '../modelos/animal.dart';
// Arquivo json_da_api.dart: leitura da lista sem os itens com defeito.
import '../modelos/json_da_api.dart';

// Cópia local da lista de animais, usada para mostrar o feed sem internet
class CacheService {
  static const _chaveAnimais = 'cache_animais';
  static const _chaveData = 'cache_animais_data';

  // Grava a lista e o momento da gravação
  Future<void> salvarAnimais(List<Animal> animais) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chaveAnimais,
      jsonEncode(animais.map((a) => a.toJson()).toList()),
    );
    await prefs.setString(_chaveData, DateTime.now().toIso8601String());
  }

  // A lista gravada, ou null quando não há cópia ou ela não pode ser lida
  Future<List<Animal>?> lerAnimais() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chaveAnimais);
    if (texto == null) return null;
    try {
      final lista = jsonDecode(texto) as List;
      return itensValidos(lista, Animal.fromJson);
    } catch (_) {
      // Cópia corrompida é tratada como inexistente
      return null;
    }
  }

  // Quando a cópia foi gravada, para a tela informar a idade dos dados
  Future<DateTime?> dataDoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chaveData);
    return texto == null ? null : DateTime.tryParse(texto);
  }
}
