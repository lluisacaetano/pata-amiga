// Funções comuns à leitura do JSON da API, usadas por todos os modelos

// Lê o id vindo da API como texto. O json-server mais novo grava os ids em
// texto ("x_cwI-8YbkU"), e os dados de exemplo usam números; os dois casos
// viram texto aqui. Devolve null quando o campo não existe
String? idDaApi(Object? valor) {
  if (valor == null) return null;
  final texto = valor is num ? valor.toInt().toString() : valor.toString();
  return texto.trim().isEmpty ? null : texto;
}

// Prepara o id para gravar na API: o id numérico volta a ser número, para
// manter o formato dos dados de exemplo; os demais seguem como texto
Object idParaApi(String id) => int.tryParse(id) ?? id;

// Converte a lista do JSON em objetos, descartando os itens que não puderem
// ser lidos (campo obrigatório ausente, tipo ou valor desconhecido). Assim
// um registro com defeito não impede a leitura dos demais
List<T> itensValidos<T>(
  List<dynamic> lista,
  T Function(Map<String, dynamic> json) ler,
) {
  final itens = <T>[];
  for (final item in lista) {
    try {
      itens.add(ler(item as Map<String, dynamic>));
    } catch (_) {
      // Item com defeito: fica de fora da lista
    }
  }
  return itens;
}
