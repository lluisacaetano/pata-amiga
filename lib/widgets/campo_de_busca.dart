// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Campo de busca arredondado, com lupa à esquerda, usado no topo das listas
// (ONGs e denúncias). Avisa a tela a cada letra digitada
class CampoDeBusca extends StatelessWidget {
  const CampoDeBusca({
    super.key,
    required this.controller,
    required this.dica,
    required this.aoMudar,
  });

  final TextEditingController controller;
  // Texto de exemplo exibido enquanto o campo está vazio
  final String dica;
  final ValueChanged<String> aoMudar;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: aoMudar,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: context.cores.cartao,
        hintText: dica,
        hintStyle: TextStyle(fontSize: 14, color: context.cores.textoFraco),
        prefixIcon: Icon(Icons.search, color: context.cores.textoFraco),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: context.cores.borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: context.cores.principal, width: 1.5),
        ),
      ),
    );
  }
}
