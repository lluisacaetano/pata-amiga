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
        child: caminho.isEmpty
            ? Container(
                color: Cores.principalClara,
                alignment: Alignment.center,
                child: const Icon(Icons.pets, size: 48, color: Cores.principal),
              )
            : Image.asset(
                caminho,
                fit: BoxFit.cover,
                // Enquanto a foto nao tiver sido adicionada na pasta assets,
                // a tela mostra a patinha em vez de quebrar.
                errorBuilder: (_, _, _) => Container(
                  color: Cores.principalClara,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.pets,
                    size: 48,
                    color: Cores.principal,
                  ),
                ),
              ),
      ),
    );
  }
}
