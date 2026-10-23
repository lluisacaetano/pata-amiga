// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';

// Aparência escolhida: clara, escura ou a mesma do sistema
enum PreferenciaTema { claro, escuro, sistema }

// Tamanho do texto do app inteiro
enum TamanhoTexto { normal, grande, extragrande }

// Guarda as preferências de aparência e de tamanho do texto no aparelho e
// avisa o app quando mudam
class PreferenciasAplicativoProvider extends ChangeNotifier {
  static const _chaveTema = 'preferencia_tema';
  static const _chaveTamanhoTexto = 'preferencia_tamanho_texto';

  PreferenciaTema _tema = PreferenciaTema.sistema;
  TamanhoTexto _tamanhoTexto = TamanhoTexto.normal;

  PreferenciaTema get tema => _tema;
  TamanhoTexto get tamanhoTexto => _tamanhoTexto;

  // Fator aplicado ao tamanho de todo o texto do app
  double get escalaTexto => switch (_tamanhoTexto) {
    TamanhoTexto.normal => 1,
    TamanhoTexto.grande => 1.2,
    TamanhoTexto.extragrande => 1.4,
  };

  // Lê as preferências salvas; valores ausentes ou inválidos voltam ao
  // padrão (seguir o sistema e texto normal)
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
  }

  // Salva a escolha antes de aplicar: se a gravação falhar, nada muda
  Future<void> definirTema(PreferenciaTema tema) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_chaveTema, tema.name);
    _tema = tema;
    notifyListeners();
  }

  // Mesmo cuidado de [definirTema]: só aplica depois de salvar
  Future<void> definirTamanhoTexto(TamanhoTexto tamanho) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_chaveTamanhoTexto, tamanho.name);
    _tamanhoTexto = tamanho;
    notifyListeners();
  }
}

// Executa [salvar] (uma das gravações deste provider) e, se a gravação no
// aparelho falhar, avisa a pessoa com [mensagemDeErro]. Usada pelas telas de
// Aparência e Acessibilidade
Future<void> salvarPreferencia(
  BuildContext context,
  Future<void> Function() salvar, {
  required String mensagemDeErro,
}) async {
  try {
    await salvar();
  } on Exception catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagemDeErro)));
  }
}
