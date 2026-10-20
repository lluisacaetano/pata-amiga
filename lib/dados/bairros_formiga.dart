// Bairros de Formiga (MG) para o cadastro de animal, em ordem alfabética.
// É a união de duas bases de CEP montadas a partir dos Correios, consultadas
// em 19/10/2026: ruacep.com.br/mg/formiga/bairros (112 bairros) e
// cepsbrasil.com.br/mg/formiga (109). Nenhuma é a lista oficial da
// prefeitura; quem não achar o seu bairro escolhe "Outro" e escreve.
const List<String> bairrosDeFormiga = [
  'Água Vermelha',
  'Albertos',
  'Alto da Praia',
  'Alto dos Pinheiros',
  'Alvorada',
  'Área Rural de Formiga',
  'Areias Brancas',
  'Baiões',
  'Balbino Ribeiro da Silva',
  'Beira Rio',
  'Bela Vista',
  'Belvedere',
  'Boa Esperança',
  'Centenário',
  'Centro',
  'Cidade da Serra',
  'Cidade Nova',
  'Condomínio Morada do Sol',
  'da Lajinha',
  'da Saudade',
  'das Andorinhas',
  'das Oliveiras',
  'Del Rey',
  "Distrito Empresarial D'Carlos",
  'Distrito Industrial Mirtô Albergaria Pieroni',
  'Distrito Industrial Vereador José Luiz Andrade',
  'Distrito Industrial Vereador José Luiz Andrade II',
  'Dom Couto',
  'Eldorado',
  'Engenho de Serra',
  'Ercio Rocha',
  'Esplanada do Castelo',
  'Furnas Iate Clube',
  'Furnastur',
  'Geraldo Veloso',
  'Industrial',
  'Jardim Alvorada',
  'Jardim América',
  'Jardim Califórnia',
  'Jardim das Acácias',
  'Jardim Elza Dinorah',
  'Jardim Florença',
  'Jardim Guanabara',
  'Jardim Minas Gerais',
  'Jardim Montanhez',
  'Jardim Morumbi',
  'Jardim Primavera',
  'José Honorato de Castro',
  'Lagoa do Fundão',
  'Leal',
  'Mangabeiras',
  'Maringá',
  'Moradas do Engenho',
  'Nossa Senhora Aparecida',
  'Nossa Senhora de Lourdes',
  'Nova Conquista',
  'Nova Vista',
  'Novo Horizonte',
  'Novo Jardim Alvorada',
  'Novo Santo Antônio',
  'Ouro Branco',
  'Ouro Verde',
  'Padre Remaclo Fóxius',
  'Palmeiras',
  'Planalto',
  'Ponte Vila',
  'Pôr do Sol',
  'Povoado Pouso Alegre',
  'Quartéis',
  'Quinzinho',
  'Ramiro Batista da Costa',
  'Recanto da Praia',
  'Residencial dos Lagos',
  'Residencial Ouro Negro',
  'Rosa Mística',
  'Rosário',
  'Sagrado Coração de Jesus',
  'Santa Luzia',
  'Santa Tereza',
  'Santana I',
  'Santana II',
  'Santo Antônio',
  'São Cristóvão',
  'São Geraldo',
  'São Lourenço',
  'São Luiz',
  'São Raimundo',
  'Serra Verde',
  'Terra Santa',
  'Tino Pereira',
  'Universitário',
  'Vargem Grande',
  'Vila Bom Pastor',
  'Vila Carmelita',
  'Vila Castro',
  'Vila Didi',
  'Vila Esperança',
  'Vila Ferreira',
  'Vila Formosa',
  'Vila Imperial',
  'Vila Irba',
  'Vila Jardim Colorido',
  'Vila José Branco',
  'Vila Maria Conceição de Castro',
  'Vila Maria Cristina',
  'Vila Nirmatelle',
  'Vila Operária São José',
  'Vila Padre João da Mata Rodarte',
  'Vila Santa Maria',
  'Vila São Domingos',
  'Vila São Vicente',
  'Vila Souza e Silva',
  'Vista Alegre',
];

// A opção para o bairro que não está na lista
const outroBairro = 'Outro';

// Compara sem maiúsculas e sem acentos: "agua vermelha" acha "Água Vermelha"
String _semAcento(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  final minusculo = texto.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  final saida = StringBuffer();
  for (final letra in minusculo.split('')) {
    final i = de.indexOf(letra);
    saida.write(i < 0 ? letra : para[i]);
  }
  return saida.toString();
}

bool mesmoBairro(String a, String b) => _semAcento(a) == _semAcento(b);

// O bairro da lista com esse nome, ou null se não houver
String? bairroDaLista(String nome) {
  if (nome.trim().isEmpty) return null;
  for (final bairro in bairrosDeFormiga) {
    if (mesmoBairro(bairro, nome)) return bairro;
  }
  return null;
}

// Os bairros cujo nome contém o que foi digitado
Iterable<String> filtrarBairros(String digitado) {
  final busca = _semAcento(digitado);
  if (busca.isEmpty) return bairrosDeFormiga;
  return bairrosDeFormiga.where((bairro) => _semAcento(bairro).contains(busca));
}

// O serviço de endereços do Android às vezes devolve o nome da cidade no lugar
// do bairro. Quando isso acontece, o bairro é tratado como desconhecido
String bairroDoServico(String? bairro, String? cidade) {
  final lido = bairro?.trim() ?? '';
  if (lido.isEmpty) return '';
  if (mesmoBairro(lido, cidade ?? '') || mesmoBairro(lido, 'Formiga')) {
    return '';
  }
  return lido;
}
