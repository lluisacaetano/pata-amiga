// Pacote flutter/services: serviços da plataforma, como TextInputFormatter.
import 'package:flutter/services.dart';

// Formata o telefone com DDD durante a digitação: (37) 99999-0000 para
// celular e (37) 9999-0000 para fixo. Aceita até 11 dígitos e descarta o
// restante
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

// Aplica o formato da máscara a um telefone já gravado, como os que vêm da
// API: "37999990000" vira "(37) 99999-0000". Remove o código do país (55)
// quando presente. Sem dígitos, devolve o texto sem espaços nas pontas
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

// Máscara de e-mail: como o endereço não tem formato fixo, ela só impede o
// que nunca é válido. Remove espaços, converte para minúsculas e rejeita um
// segundo @
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
