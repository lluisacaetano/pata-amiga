// Funções de texto e de datas usadas em várias telas e modelos

// Devolve o texto com a primeira letra maiúscula. Os dados do cadastro são
// gravados em minúsculas e passam por aqui antes de aparecer na tela
String comMaiuscula(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

// O texto em minúsculas, sem acentos e sem espaços repetidos, para comparar
// e ordenar nomes: "agua  vermelha" corresponde a "Água Vermelha"
String semAcento(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  final limpo = texto.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  final saida = StringBuffer();
  for (final letra in limpo.split('')) {
    final i = de.indexOf(letra);
    saida.write(i < 0 ? letra : para[i]);
  }
  return saida.toString();
}

// Há quanto tempo foi a data: "hoje", "ontem", "há 3 dias" e, depois de 30
// dias, "há 1 mês" ou "há 2 meses". Compara só as datas, sem a hora; o mês
// conta 30 dias
String haQuantosDias(DateTime data, DateTime agora) {
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(data.year, data.month, data.day);
  final dias = hoje.difference(dia).inDays;
  if (dias <= 0) return 'hoje';
  if (dias == 1) return 'ontem';
  if (dias <= 30) return 'há $dias dias';
  final meses = dias ~/ 30;
  return meses == 1 ? 'há 1 mês' : 'há $meses meses';
}
