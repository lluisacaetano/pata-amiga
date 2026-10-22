import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../modelos/ong.dart';
import '../tema/cores.dart';

// O rosto da ONG em todo lugar em que ela aparece: a foto em círculo, como a
// do "Meu perfil", ou, sem foto, as iniciais do nome. Assim a ONG é
// reconhecível na lista, no perfil e no cartão "Minha ONG" mesmo sem foto
class AvatarDaOng extends StatelessWidget {
  final Ong ong;
  final double raio;

  const AvatarDaOng({super.key, required this.ong, this.raio = 28});

  @override
  Widget build(BuildContext context) {
    final foto = ong.foto;
    final ImageProvider<Object>? imagem = foto.isEmpty
        ? null
        : foto.startsWith('http')
        ? NetworkImage(foto)
        : !kIsWeb && foto.startsWith('/')
        ? FileImage(File(foto))
        : AssetImage(foto);
    // O anel claro destaca a foto do fundo, como no perfil da pessoa
    return Container(
      padding: EdgeInsets.all(raio > 30 ? 3 : 2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Cores.principalClara,
      ),
      child: CircleAvatar(
        radius: raio,
        backgroundColor: Cores.principalClara,
        backgroundImage: imagem,
        child: imagem == null && iniciaisDa(ong.nome).isEmpty
            ? Icon(
                Icons.volunteer_activism_outlined,
                size: raio,
                color: Cores.principal,
              )
            : imagem == null
            ? Text(
                iniciaisDa(ong.nome),
                style: TextStyle(
                  color: Cores.principal,
                  fontSize: raio * 0.72,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              )
            : null,
      ),
    );
  }
}

// As iniciais das duas primeiras palavras que contam: "Abrigo Focinhos
// (exemplo)" vira "AF", sem os "de", "da" e o que estiver entre parênteses.
// Sem nome ainda, volta vazio, e o avatar mostra o ícone
String iniciaisDa(String nome) {
  const ligacoes = {'de', 'da', 'do', 'das', 'dos', 'e'};
  final palavras = nome
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .split(RegExp(r'\s+'))
      .where((palavra) => palavra.isNotEmpty)
      .where((palavra) => !ligacoes.contains(palavra.toLowerCase()))
      .take(2);
  final iniciais = palavras.map((palavra) => palavra[0].toUpperCase()).join();
  return iniciais;
}
