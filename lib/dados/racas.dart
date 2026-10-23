// Arquivo texto.dart: comparação de nomes sem acentos.
import '../modelos/texto.dart';

// As raças oferecidas no cadastro, separadas por espécie, com "Sem raça
// definida" primeiro por ser a mais comum entre os animais para adoção. A raça
// ausente é informada pela opção "Outra".
//
// Fontes:
// - cachorros: guia de raças da Cobasi (cobasi.com.br/racas/cachorro), com o
//   "Vira-lata" como "Sem raça definida";
// - gatos: raças reconhecidas pela FIFe (fifeweb.org/cats/breeds), federação
//   a que a Federação Felina Brasileira é filiada, com os nomes em português,
//   juntando as variações de pelo longo e curto; mais Scottish Fold e Toyger,
//   do guia da Cobasi, e o Pelo Curto Brasileiro, raça brasileira reconhecida
//   pela WCF
const semRacaDefinida = 'Sem raça definida';

const racasDeCachorro = [
  semRacaDefinida,
  'Affenpinscher',
  'Afghan Hound',
  'Airedale Terrier',
  'Akita Americano',
  'American Bully',
  'American Staffordshire Terrier',
  'Basenji',
  'Basset Hound',
  'Beagle',
  'Bearded Collie',
  'Bernese',
  'Bichon Havanês',
  'Biewer Terrier',
  'Bloodhound',
  'Blue Heeler',
  'Boerboel',
  'Border Collie',
  'Boston Terrier',
  'Boxer',
  'Braco Alemão',
  'Bull Terrier',
  'Bulldog Americano',
  'Bulldog Francês',
  'Bulldog Inglês',
  'Bullmastiff',
  'Cairn Terrier',
  'Cane Corso',
  'Cão de Crista Chinês',
  'Cavalier King Charles Spaniel',
  'Chihuahua',
  'Chow Chow',
  'Cocker Spaniel Americano',
  'Cocker Spaniel Inglês',
  'Collie',
  'Coton de Tulear',
  'Dachshund',
  'Dálmata',
  'Dandie Dinmont Terrier',
  'Doberman',
  'Dogo Argentino',
  'Dogue Alemão',
  'Dogue de Bordeaux',
  'Fila Brasileiro',
  'Flat-Coated Retriever',
  'Fox Paulistinha',
  'Fox Terrier de Pelo Duro',
  'Fox Terrier de Pelo Liso',
  'Galgo Italiano',
  'Golden Retriever',
  'Greyhound',
  'Griffon de Bruxelas',
  'Hokkaido',
  'Hovawart',
  'Husky Siberiano',
  'Jack Russell Terrier',
  'Keeshond',
  'Komondor',
  'Kuvasz',
  'Labrador Retriever',
  'Leão da Rodésia',
  'Lébrel Irlandês',
  'Lhasa Apso',
  'Lulu da Pomerânia',
  'Malamute do Alasca',
  'Maltês',
  'Mastiff',
  'Mastim Espanhol',
  'Mastim Napolitano',
  'Mastim Tibetano',
  'Norfolk Terrier',
  'Old English Sheepdog',
  'Pastor Alemão',
  'Pastor Australiano',
  'Pastor Belga',
  'Pastor Belga Groenendael',
  'Pastor Belga Malinois',
  'Pastor Belga Tervuren',
  'Pastor de Beauce',
  'Pastor de Shetland',
  'Pastor do Cáucaso',
  'Pastor Maremano Abruzês',
  'Pastor Suíço',
  'Pequeno Cão Leão',
  'Pequinês',
  'Perdigueiro',
  'Pinscher',
  'Pitbull',
  'Pointer Inglês',
  'Poodle',
  'Pug',
  'Puli',
  'Rottweiler',
  'Saluki',
  'Samoieda',
  'São Bernardo',
  'Schipperke',
  'Schnauzer',
  'Schnauzer Gigante',
  'Scottish Terrier',
  'Setter Irlandês',
  'Shar Pei',
  'Shiba Inu',
  'Shih Tzu',
  'Spaniel Bretão',
  'Spitz Japonês',
  'Terra Nova',
  'Terrier Tibetano',
  'Tosa Inu',
  'Weimaraner',
  'Welsh Corgi Cardigan',
  'Welsh Corgi Pembroke',
  'West Highland White Terrier',
  'Whippet',
  'Yorkshire Terrier',
];

const racasDeGato = [
  semRacaDefinida,
  'Abissínio',
  'American Curl',
  'Angorá Turco',
  'Azul Russo',
  'Balinês',
  'Bengal',
  'Bobtail Japonês',
  'Bombay',
  'British Longhair',
  'British Shorthair',
  'Burmês',
  'Burmilla',
  'Chartreux',
  'Cornish Rex',
  'Cymric',
  'Devon Rex',
  'Don Sphynx',
  'Europeu',
  'Exótico',
  'Floresta Norueguesa',
  'German Rex',
  'Korat',
  'Kurilian Bobtail',
  'LaPerm',
  'Lykoi',
  'Maine Coon',
  'Manx',
  'Mau Egípcio',
  'Neva Masquerade',
  'Ocicat',
  'Oriental',
  'Pelo Curto Brasileiro',
  'Persa',
  'Peterbald',
  'Ragdoll',
  'Sagrado da Birmânia',
  'Scottish Fold',
  'Selkirk Rex',
  'Siamês',
  'Siberiano',
  'Singapura',
  'Snowshoe',
  'Sokoke',
  'Somali',
  'Sphynx',
  'Thai',
  'Toyger',
  'Van Turco',
];

// A opção para informar uma raça que não está na lista
const outraRaca = 'Outra';

// Nomes populares das raças da lista, sem acentos, ligados ao nome oficial.
// Assim "labrador" ou "vira-lata" são reconhecidos como a raça correta
const _apelidos = {
  'vira-lata': semRacaDefinida,
  'vira lata': semRacaDefinida,
  'viralata': semRacaDefinida,
  'srd': semRacaDefinida,
  'sem raca': semRacaDefinida,
  'labrador': 'Labrador Retriever',
  'golden': 'Golden Retriever',
  'jack russell': 'Jack Russell Terrier',
  'yorkshire': 'Yorkshire Terrier',
  'spitz alemao': 'Lulu da Pomerânia',
  'spitz alemao anao': 'Lulu da Pomerânia',
  'lulu': 'Lulu da Pomerânia',
  'buldogue frances': 'Bulldog Francês',
  'buldogue ingles': 'Bulldog Inglês',
  'pit bull': 'Pitbull',
  'husky': 'Husky Siberiano',
  'salsicha': 'Dachshund',
  'rhodesian ridgeback': 'Leão da Rodésia',
  'angora': 'Angorá Turco',
  'birmanes': 'Sagrado da Birmânia',
  'birman': 'Sagrado da Birmânia',
};

// As raças da espécie (cachorro ou gato); outra espécie não tem lista
List<String> racasDa(String? especie) => switch (especie?.toLowerCase()) {
  'cachorro' => racasDeCachorro,
  'gato' => racasDeGato,
  _ => const [],
};

// O nome oficial da raça, de qualquer espécie, sem ligar para maiúsculas e
// acentos e aceitando os apelidos; null se não for nenhuma raça da lista
String? racaConhecida(String nome) {
  final busca = semAcento(nome);
  if (busca.isEmpty) return null;
  final apelido = _apelidos[busca];
  if (apelido != null) return apelido;
  for (final raca in [...racasDeCachorro, ...racasDeGato]) {
    if (semAcento(raca) == busca) return raca;
  }
  return null;
}

// A raça da lista da espécie com esse nome, ou null se não houver
String? racaDaLista(String? especie, String nome) {
  final raca = racaConhecida(nome);
  return raca != null && racasDa(especie).contains(raca) ? raca : null;
}

// As raças da espécie cujo nome contém o que foi digitado
Iterable<String> filtrarRacas(String? especie, String digitado) =>
    buscarNaLista(racasDa(especie), digitado);

// As raças da lista cujo nome contém o que foi digitado, sem ligar para
// maiúsculas e acentos
Iterable<String> buscarNaLista(Iterable<String> racas, String digitado) {
  final busca = semAcento(digitado);
  if (busca.isEmpty) return racas;
  return racas.where((raca) => semAcento(raca).contains(busca));
}
