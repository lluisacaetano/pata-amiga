import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/animal.dart';

class CacheService {
  static const _chaveAnimais = 'cache_animais';
  static const _chaveData = 'cache_animais_data';

  Future<void> salvarAnimais(List<Animal> animais) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chaveAnimais,
      jsonEncode(animais.map((a) => a.toJson()).toList()),
    );
    await prefs.setString(_chaveData, DateTime.now().toIso8601String());
  }

  Future<List<Animal>?> lerAnimais() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chaveAnimais);
    if (texto == null) return null;
    try {
      final lista = jsonDecode(texto) as List;
      return lista
          .map((e) => Animal.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null; // cache corrompido: trata como se não existisse
    }
  }

  Future<DateTime?> dataDoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chaveData);
    return texto == null ? null : DateTime.tryParse(texto);
  }
}