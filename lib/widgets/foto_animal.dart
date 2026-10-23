// Biblioteca dart:io: arquivos do aparelho, como as fotos salvas.
import 'dart:io';

// Pacote flutter/foundation: utilitários base, como kIsWeb.
import 'package:flutter/foundation.dart';
// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Exibe a foto do animal com altura e cantos configuráveis. Sem caminho, ou
// se a imagem não puder ser carregada, mostra um fundo claro com uma patinha
class FotoAnimal extends StatelessWidget {
  final String caminho;
  final double altura;
  final BorderRadius raio;

  const FotoAnimal({
    super.key,
    required this.caminho,
    this.altura = 200,
    this.raio = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: raio,
      child: SizedBox(
        height: altura,
        width: double.infinity,
        child: caminho.isEmpty ? _patinha(context) : _imagem(context),
      ),
    );
  }

  // Escolhe a origem da imagem pelo formato do caminho: endereço "http" vem
  // da internet, caminho absoluto é um arquivo do aparelho (foto escolhida na
  // galeria) e o restante é tratado como asset do app
  Widget _imagem(BuildContext context) {
    Widget erro(BuildContext _, Object _, StackTrace? _) => _patinha(context);
    if (caminho.startsWith('http')) {
      return Image.network(caminho, fit: BoxFit.cover, errorBuilder: erro);
    }
    if (!kIsWeb && caminho.startsWith('/')) {
      return Image.file(File(caminho), fit: BoxFit.cover, errorBuilder: erro);
    }
    // Asset ausente cai no errorBuilder e mostra a patinha
    return Image.asset(caminho, fit: BoxFit.cover, errorBuilder: erro);
  }

  // Marcador usado quando não há foto
  Widget _patinha(BuildContext context) => Container(
    color: context.cores.principalClara,
    alignment: Alignment.center,
    child: Icon(Icons.pets, size: 48, color: context.cores.principal),
  );
}
