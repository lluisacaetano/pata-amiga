// Arquivo racas.dart: lista de raças e a busca pelo nome oficial.
import '../dados/racas.dart';
// Arquivo animal.dart: modelo do animal que os filtros avaliam.
import 'animal.dart';

// Reexporta a opção "Sem raça definida" para as telas do filtro.
export '../dados/racas.dart' show semRacaDefinida;

// Os grupos de filtro do feed, na ordem em que aparecem no painel. No grupo
// da ONG, a opção é o id, e não o nome, porque o nome pode mudar
enum GrupoDeFiltro { especie, porte, sexo, raca, bairro, ong, saude }

extension TituloDoGrupo on GrupoDeFiltro {
  // O nome do grupo como aparece no painel
  String get titulo => switch (this) {
    GrupoDeFiltro.especie => 'Espécie',
    GrupoDeFiltro.porte => 'Porte',
    GrupoDeFiltro.sexo => 'Sexo',
    GrupoDeFiltro.raca => 'Raça',
    GrupoDeFiltro.bairro => 'Bairro',
    GrupoDeFiltro.ong => 'ONG',
    GrupoDeFiltro.saude => 'Saúde',
  };
}

// As opções marcadas em cada grupo. Dentro de um grupo basta o animal ter
// uma das opções ("médio ou grande"); entre grupos, precisa atender a todos.
// Na saúde, o animal precisa ter todos os cuidados marcados
class FiltrosDoFeed {
  final Map<GrupoDeFiltro, Set<String>> marcados;

  const FiltrosDoFeed([this.marcados = const {}]);

  // As opções marcadas no grupo
  Set<String> de(GrupoDeFiltro grupo) => marcados[grupo] ?? const {};

  // Se nenhum filtro está marcado
  bool get vazio => marcados.values.every((opcoes) => opcoes.isEmpty);

  // Quantas opções estão marcadas no total
  int get quantos =>
      marcados.values.fold(0, (soma, opcoes) => soma + opcoes.length);

  // Se o animal passa por todos os filtros marcados
  bool combina(Animal animal) {
    for (final MapEntry(key: grupo, value: opcoes) in marcados.entries) {
      if (opcoes.isEmpty) continue;
      final doAnimal = valoresDe(animal, grupo);
      final passa = grupo == GrupoDeFiltro.saude
          ? doAnimal.containsAll(opcoes)
          : opcoes.any(doAnimal.contains);
      if (!passa) return false;
    }
    return true;
  }

  // Substitui de uma vez as opções marcadas em um grupo
  FiltrosDoFeed comGrupo(GrupoDeFiltro grupo, Set<String> opcoes) =>
      FiltrosDoFeed({...marcados, grupo: opcoes});

  // Marca a opção ou, se ela já estava marcada, desmarca
  FiltrosDoFeed alternar(GrupoDeFiltro grupo, String opcao) {
    final atuais = de(grupo);
    return FiltrosDoFeed({
      ...marcados,
      grupo: atuais.contains(opcao)
          ? ({...atuais}..remove(opcao))
          : {...atuais, opcao},
    });
  }
}

// As opções fixas de porte, espécie, sexo e saúde, iguais às do cadastro
const portesDoFeed = ['pequeno', 'médio', 'grande'];
const _especies = ['cachorro', 'gato'];
const _sexos = ['macho', 'fêmea'];
const _cuidados = ['castrado', 'vacinado', 'vermifugado'];

// Os valores do animal em um grupo, já normalizados para comparar com as
// opções. Sexo "não informado" e raça ou bairro vazios não geram valor
Set<String> valoresDe(Animal animal, GrupoDeFiltro grupo) => switch (grupo) {
  GrupoDeFiltro.especie => {animal.especie.trim().toLowerCase()},
  GrupoDeFiltro.porte => {portePadrao(animal.porte)},
  GrupoDeFiltro.sexo => {
    if (_sexos.contains(animal.sexo.trim().toLowerCase()))
      animal.sexo.trim().toLowerCase(),
  },
  GrupoDeFiltro.raca => {
    if (racaPadrao(animal.raca).isNotEmpty) racaPadrao(animal.raca),
  },
  GrupoDeFiltro.bairro => {
    if (animal.bairro.trim().isNotEmpty) animal.bairro.trim(),
  },
  GrupoDeFiltro.ong => {if (animal.ongId != null) '${animal.ongId}'},
  GrupoDeFiltro.saude => {
    if (animal.castrado) 'castrado',
    if (animal.vacinado) 'vacinado',
    if (animal.vermifugado) 'vermifugado',
  },
};

// As opções de cada grupo. Raça, bairro e ONG vêm dos animais do feed, para
// não oferecer opção que não retorna nenhum animal
List<String> opcoesDe(GrupoDeFiltro grupo, Iterable<Animal> animais) =>
    switch (grupo) {
      GrupoDeFiltro.especie => _especies,
      GrupoDeFiltro.porte => portesDoFeed,
      GrupoDeFiltro.sexo => _sexos,
      GrupoDeFiltro.saude => _cuidados,
      GrupoDeFiltro.raca => racasDoFeed(animais),
      GrupoDeFiltro.bairro => _emOrdem({
        for (final animal in animais)
          ...valoresDe(animal, GrupoDeFiltro.bairro),
      }),
      GrupoDeFiltro.ong => {
        for (final animal in animais) ...valoresDe(animal, GrupoDeFiltro.ong),
      }.toList(),
    };

// O texto da opção na tela, com a primeira letra maiúscula
String rotuloDaOpcao(String opcao) =>
    opcao.isEmpty ? opcao : opcao[0].toUpperCase() + opcao.substring(1);

// Preposições e conjunções mantidas em minúsculas no meio do nome da raça
const _ligacoes = {'de', 'da', 'do', 'dos', 'das', 'e'};

// O porte em minúsculas e com acento, para "Medio" e "médio" serem iguais
String portePadrao(String porte) =>
    porte.trim().toLowerCase().replaceAll('medio', 'médio');

// Normaliza a raça digitada livremente: "labrador" e "Labrador Retriever"
// viram a mesma raça, assim como "vira-lata", "SRD" e "sem raça definida".
// Raça da lista sai com o nome oficial; as demais, com iniciais maiúsculas
String racaPadrao(String raca) {
  final limpa = raca.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (limpa.isEmpty) return '';
  final conhecida = racaConhecida(limpa);
  if (conhecida != null) return conhecida;
  final palavras = limpa.toLowerCase().split(' ');
  return [
    for (var i = 0; i < palavras.length; i++)
      i > 0 && _ligacoes.contains(palavras[i])
          ? palavras[i]
          : palavras[i][0].toUpperCase() + palavras[i].substring(1),
  ].join(' ');
}

// As raças presentes no feed, sem repetição: "Sem raça definida" primeiro e
// as demais em ordem alfabética
List<String> racasDoFeed(Iterable<Animal> animais) {
  final racas = {
    for (final animal in animais) ...valoresDe(animal, GrupoDeFiltro.raca),
  };
  return [
    if (racas.contains(semRacaDefinida)) semRacaDefinida,
    ..._emOrdem(racas.where((raca) => raca != semRacaDefinida)),
  ];
}

// Ordena em ordem alfabética ignorando acentos, para "Água Vermelha" não ir
// para depois do "Z"
List<String> _emOrdem(Iterable<String> opcoes) =>
    opcoes.toList()..sort((a, b) => _semAcento(a).compareTo(_semAcento(b)));

// O texto em minúsculas e sem acentos, usado na ordenação
String _semAcento(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const para = 'aaaaaeeeeiiiiooooouuuuc';
  final minusculo = texto.toLowerCase();
  return String.fromCharCodes(
    minusculo.runes.map((letra) {
      final indice = de.indexOf(String.fromCharCode(letra));
      return indice < 0 ? letra : para.codeUnitAt(indice);
    }),
  );
}
