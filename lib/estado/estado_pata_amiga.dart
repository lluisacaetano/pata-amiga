import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EstadoPataAmiga extends ChangeNotifier {
  static const _chaveCurtidos = 'curtidos';

  final Set<String> _curtidos = {};
  bool _descartado = false;

  bool estaCurtido(String nome) => _curtidos.contains(nome);

  Future<void> carregarCurtidos() async {
    final armazenamento = await SharedPreferences.getInstance();
    if (_descartado) return;
    _curtidos
      ..clear()
      ..addAll(armazenamento.getStringList(_chaveCurtidos) ?? const []);
    notifyListeners();
  }

  Future<void> alternarCurtida(String nome) async {
    if (!_curtidos.add(nome)) _curtidos.remove(nome);
    notifyListeners();

    final armazenamento = await SharedPreferences.getInstance();
    await armazenamento.setStringList(_chaveCurtidos, _curtidos.toList());
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}

class PataAmigaScope extends InheritedNotifier<EstadoPataAmiga> {
  const PataAmigaScope({
    super.key,
    required EstadoPataAmiga notifier,
    required super.child,
  }) : super(notifier: notifier);

  static EstadoPataAmiga of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PataAmigaScope>();
    assert(scope != null, 'PataAmigaScope não encontrado na árvore.');
    return scope!.notifier!;
  }
}
