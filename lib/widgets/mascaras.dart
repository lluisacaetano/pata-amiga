import 'package:flutter/services.dart';

// Formata o telefone com DDD enquanto se digita: (37) 99999-0000
class MascaraDeTelefone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    final digitos = novo.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digitos.length > 11 ? digitos.substring(0, 11) : digitos;

    final escrita = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 0) escrita.write('(');
      if (i == 2) escrita.write(') ');
      if (limitado.length >= 10 && i == limitado.length - 4) escrita.write('-');
      escrita.write(limitado[i]);
    }

    final texto = escrita.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

// O mesmo formato da máscara para telefones que chegam sem ela, como os da
// API: "37999990000" vira "(37) 99999-0000". O 55 do país, se vier, sai
String formatarTelefone(String telefone) {
  var digitos = telefone.replaceAll(RegExp(r'\D'), '');
  if (digitos.length > 11 && digitos.startsWith('55')) {
    digitos = digitos.substring(2);
  }
  if (digitos.isEmpty) return telefone.trim();
  return MascaraDeTelefone()
      .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: digitos))
      .text;
}

// E-mail não tem formato fixo, então a máscara só barra o que nunca cabe
// num endereço: espaço, letra maiúscula e um segundo @
class MascaraDeEmail extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    final texto = novo.text.replaceAll(RegExp(r'\s'), '').toLowerCase();
    if ('@'.allMatches(texto).length > 1) return antigo;
    if (texto == novo.text) return novo;
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
