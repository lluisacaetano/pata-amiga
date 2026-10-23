// Arquivo texto.dart: comparação de nomes sem acentos.
import '../modelos/texto.dart';

// Bairros de Formiga (MG), em ordem alfabética, usados nos cadastros. A lista
// une duas bases de CEP derivadas dos Correios (ruacep.com.br e
// cepsbrasil.com.br) e não é a lista oficial da prefeitura; o bairro ausente
// é informado pela opção "Outro"
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

// A opção para informar um bairro que não está na lista
const outroBairro = 'Outro';

// Se os dois nomes são do mesmo bairro, ignorando maiúsculas e acentos
bool mesmoBairro(String a, String b) => semAcento(a) == semAcento(b);

// O nome oficial do bairro na lista, ou null se ele não estiver nela
String? bairroDaLista(String nome) {
  if (nome.trim().isEmpty) return null;
  for (final bairro in bairrosDeFormiga) {
    if (mesmoBairro(bairro, nome)) return bairro;
  }
  return null;
}

// Os bairros cujo nome contém o texto digitado; sem texto, todos
Iterable<String> filtrarBairros(String digitado) {
  final busca = semAcento(digitado);
  if (busca.isEmpty) return bairrosDeFormiga;
  return bairrosDeFormiga.where((bairro) => semAcento(bairro).contains(busca));
}

// Limpa o bairro devolvido pelo geocoding do aparelho, que às vezes traz o
// nome da cidade no lugar dele. Nesse caso, devolve vazio (desconhecido)
String bairroDoServico(String? bairro, String? cidade) {
  final lido = bairro?.trim() ?? '';
  if (lido.isEmpty) return '';
  if (mesmoBairro(lido, cidade ?? '') || mesmoBairro(lido, 'Formiga')) {
    return '';
  }
  return lido;
}
