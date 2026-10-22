import '../dados/racas.dart';
import 'animal.dart';

export '../dados/racas.dart' show semRacaDefinida;

// Os grupos de filtro do feed, na ordem em que aparecem no painel. Todos usam
// dados que o cadastro já pede. A ONG guarda o id, e não o nome, porque o
// nome pode mudar; quem mostra o nome é a tela
enum GrupoDeFiltro { especie, porte, sexo, raca, bairro, ong, saude }

extension TituloDoGrupo on GrupoDeFiltro {
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

// O que está marcado em cada grupo. Dentro de um grupo vale qualquer opção
// marcada ("médio ou grande"); entre os grupos, o animal precisa combinar com
// todos. A saúde é a exceção: marcar "castrado" e "vacinado" pede os dois
// cuidados, porque é isso que quem filtra quer saber
class FiltrosDoFeed {
  final Map<GrupoDeFiltro, Set<String>> marcados;

  const FiltrosDoFeed([this.marcados = const {}]);

  Set<String> de(GrupoDeFiltro grupo) => marcados[grupo] ?? const {};

  bool get vazio => marcados.values.every((opcoes) => opcoes.isEmpty);

  int get quantos =>
      marcados.values.fold(0, (soma, opcoes) => soma + opcoes.length);

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

  // Troca o que está marcado num grupo de uma vez, como as abas devolvem
  FiltrosDoFeed comGrupo(GrupoDeFiltro grupo, Set<String> opcoes) =>
      FiltrosDoFeed({...marcados, grupo: opcoes});

  // Marca a opção, ou desmarca se já estava marcada
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

// Os portes, as espécies, os sexos e os cuidados são os mesmos do cadastro
const portesDoFeed = ['pequeno', 'médio', 'grande'];
const _especies = ['cachorro', 'gato'];
const _sexos = ['macho', 'fêmea'];
const _cuidados = ['castrado', 'vacinado', 'vermifugado'];

// Como o animal se encaixa em cada grupo. Sexo "não informado" e raça ou
// bairro em branco ficam fora do filtro
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

// As opções de cada grupo. Raça e bairro saem dos próprios animais do feed,
// para nunca oferecer uma opção que não devolve ninguém
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

// Como a opção aparece na tela: as fixas começam com maiúscula, e raça e
// bairro já vêm escritos como devem aparecer
String rotuloDaOpcao(String opcao) =>
    opcao.isEmpty ? opcao : opcao[0].toUpperCase() + opcao.substring(1);

// Palavras que ficam minúsculas no meio do nome da raça
const _ligacoes = {'de', 'da', 'do', 'dos', 'das', 'e'};

String portePadrao(String porte) =>
    porte.trim().toLowerCase().replaceAll('medio', 'médio');

// A raça dos cadastros antigos foi escrita livremente: "labrador",
// "Labrador" e "Labrador Retriever" são a mesma, e "vira-lata", "SRD" e "sem
// raça definida" também. Raça da lista sai com o nome da lista; a que não
// está nela sai com cada palavra em maiúscula
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

// As raças do feed, sem repetir: "Sem raça definida" primeiro, por ser a mais
// comum entre os animais para adoção, e o resto em ordem alfabética
List<String> racasDoFeed(Iterable<Animal> animais) {
  final racas = {
    for (final animal in animais) ...valoresDe(animal, GrupoDeFiltro.raca),
  };
  return [
    if (racas.contains(semRacaDefinida)) semRacaDefinida,
    ..._emOrdem(racas.where((raca) => raca != semRacaDefinida)),
  ];
}

// Ordem alfabética sem deixar "Água Vermelha" depois do "Z"
List<String> _emOrdem(Iterable<String> opcoes) =>
    opcoes.toList()..sort((a, b) => _semAcento(a).compareTo(_semAcento(b)));

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
