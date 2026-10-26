// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo animal.dart: comMaiuscula, para a inicial maiúscula.
import '../modelos/animal.dart';
// Arquivo ong.dart: as finalidades da ONG e os rótulos delas.
import '../modelos/ong.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Etiqueta arredondada exibida ao lado do nome do animal. A versão clara
// classifica (tipo do registro); a versão cheia ([cheia] = true) destaca o
// desfecho, como "Adotado"
class Etiqueta extends StatelessWidget {
  final String texto;
  final bool cheia;

  const Etiqueta(this.texto, {super.key, this.cheia = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cheia ? context.cores.principal : context.cores.principalClara,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        comMaiuscula(texto),
        style: TextStyle(
          color: cheia ? context.sobrePrincipal : context.cores.principal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Etiquetas com as finalidades da ONG, sempre na mesma ordem, quebrando a
// linha quando não cabem. [centralizadas] alinha as etiquetas ao centro
class FinalidadesDaOng extends StatelessWidget {
  final Ong ong;
  final bool centralizadas;

  const FinalidadesDaOng(this.ong, {super.key, this.centralizadas = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: centralizadas ? WrapAlignment.center : WrapAlignment.start,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final finalidade in FinalidadeDaOng.values)
          if (ong.finalidades.contains(finalidade))
            Etiqueta(finalidade.rotulo),
      ],
    );
  }
}
