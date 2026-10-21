import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PreferenciaTema { claro, escuro, sistema }

enum TamanhoTexto { normal, grande, extragrande }

class PreferenciasAplicativoProvider extends ChangeNotifier {
  static const _chaveTema = 'preferencia_tema';
  static const _chaveTamanhoTexto = 'preferencia_tamanho_texto';
  static const _chaveAltoContraste = 'preferencia_alto_contraste';
  static const _chaveReducaoAnimacoes = 'preferencia_reducao_animacoes';

  PreferenciaTema _tema = PreferenciaTema.sistema;
  TamanhoTexto _tamanhoTexto = TamanhoTexto.normal;
  bool _altoContraste = false;
  bool _reduzirAnimacoes = false;

  PreferenciaTema get tema => _tema;
  TamanhoTexto get tamanhoTexto => _tamanhoTexto;
  bool get altoContraste => _altoContraste;
  bool get reduzirAnimacoes => _reduzirAnimacoes;

  double get escalaTexto => switch (_tamanhoTexto) {
    TamanhoTexto.normal => 1,
    TamanhoTexto.grande => 1.2,
    TamanhoTexto.extragrande => 1.4,
  };

  Future<void> carregar() async {
    final preferencias = await SharedPreferences.getInstance();
    _tema = PreferenciaTema.values.firstWhere(
      (opcao) => opcao.name == preferencias.getString(_chaveTema),
      orElse: () => PreferenciaTema.sistema,
    );
    _tamanhoTexto = TamanhoTexto.values.firstWhere(
      (opcao) => opcao.name == preferencias.getString(_chaveTamanhoTexto),
      orElse: () => TamanhoTexto.normal,
    );
    _altoContraste = preferencias.getBool(_chaveAltoContraste) ?? false;
    _reduzirAnimacoes =
        preferencias.getBool(_chaveReducaoAnimacoes) ?? false;
  }

  Future<void> definirTema(PreferenciaTema tema) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_chaveTema, tema.name);
    _tema = tema;
    notifyListeners();
  }

  Future<void> definirTamanhoTexto(TamanhoTexto tamanho) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_chaveTamanhoTexto, tamanho.name);
    _tamanhoTexto = tamanho;
    notifyListeners();
  }

  Future<void> definirAltoContraste(bool ativado) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setBool(_chaveAltoContraste, ativado);
    _altoContraste = ativado;
    notifyListeners();
  }

  Future<void> definirReducaoAnimacoes(bool ativada) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setBool(_chaveReducaoAnimacoes, ativada);
    _reduzirAnimacoes = ativada;
    notifyListeners();
  }
}
