import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../tema/cores.dart';

// Área da foto do animal. Enquanto não há imagem cadastrada, mostra um fundo
// neutro com o ícone de patinha.
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

  // A foto pode estar dentro do app (os animais de exemplo), na internet ou
  // no próprio celular (a que a pessoa escolheu da galeria no cadastro)
  Widget _imagem(BuildContext context) {
    Widget erro(BuildContext _, Object _, StackTrace? _) => _patinha(context);
    if (caminho.startsWith('http')) {
      return Image.network(caminho, fit: BoxFit.cover, errorBuilder: erro);
    }
    if (!kIsWeb && caminho.startsWith('/')) {
      return Image.file(File(caminho), fit: BoxFit.cover, errorBuilder: erro);
    }
    // Enquanto a foto nao tiver sido adicionada na pasta assets,
    // a tela mostra a patinha em vez de quebrar.
    return Image.asset(caminho, fit: BoxFit.cover, errorBuilder: erro);
  }

  Widget _patinha(BuildContext context) => Container(
    color: context.cores.principalClara,
    alignment: Alignment.center,
    child: Icon(Icons.pets, size: 48, color: context.cores.principal),
  );
}
