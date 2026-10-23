// Biblioteca dart:io: arquivos do aparelho, como a foto da ONG.
import 'dart:io';

// Pacote flutter/foundation: utilitários base, como kIsWeb.
import 'package:flutter/foundation.dart';
// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo ong.dart: modelo da ONG.
import '../modelos/ong.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Avatar circular da ONG, usado na lista de ONGs, no perfil da ONG e no
// vínculo do perfil do usuário. Mostra a foto (internet, arquivo do aparelho
// ou asset); sem foto, as iniciais do nome; sem nome, um ícone
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
    // Anel claro em volta do avatar, para destacá-lo do fundo
    return Container(
      padding: EdgeInsets.all(raio > 30 ? 3 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.cores.principalClara,
      ),
      child: CircleAvatar(
        radius: raio,
        backgroundColor: context.cores.principalClara,
        backgroundImage: imagem,
        child: imagem == null && iniciaisDa(ong.nome).isEmpty
            ? Icon(
                Icons.volunteer_activism_outlined,
                size: raio,
                color: context.cores.principal,
              )
            : imagem == null
            ? Text(
                iniciaisDa(ong.nome),
                style: TextStyle(
                  color: context.cores.principal,
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

// Iniciais das duas primeiras palavras significativas do nome, ignorando
// preposições ("de", "da", "do"...) e trechos entre parênteses:
// "Abrigo Focinhos (exemplo)" vira "AF". Nome vazio devolve texto vazio
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
