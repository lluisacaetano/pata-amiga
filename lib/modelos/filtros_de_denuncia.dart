// Arquivo denuncia.dart: modelo da denúncia, tipo, situação e opções do
// animal.
import 'denuncia.dart';
// Arquivo texto.dart: comparação de textos sem acentos.
import 'texto.dart';

// Os grupos de filtro da lista de denúncias, na ordem em que aparecem no
// painel. A data fica fora dos grupos, em [FiltrosDeDenuncia.periodo]
enum GrupoDaDenuncia { tipo, situacao, especie, porte, sexo, bairro }

extension TituloDoGrupoDaDenuncia on GrupoDaDenuncia {
  // O nome do grupo como aparece no painel
  String get titulo => switch (this) {
    GrupoDaDenuncia.tipo => 'Tipo',
    GrupoDaDenuncia.situacao => 'Situação',
    GrupoDaDenuncia.especie => 'Espécie',
    GrupoDaDenuncia.porte => 'Porte',
    GrupoDaDenuncia.sexo => 'Sexo',
    GrupoDaDenuncia.bairro => 'Bairro',
  };
}

// Os atalhos de data do painel, contados a partir de hoje
enum AtalhoDeData { hoje, seteDias, trintaDias }

extension RotuloDoAtalho on AtalhoDeData {
  String get rotulo => switch (this) {
    AtalhoDeData.hoje => 'Hoje',
    AtalhoDeData.seteDias => '7 dias',
    AtalhoDeData.trintaDias => '30 dias',
  };
}

// Um intervalo de dias, com o primeiro e o último incluídos
typedef PeriodoDeDias = ({DateTime de, DateTime ate});

// As opções marcadas em cada grupo e a data. Dentro de um grupo basta a
// denúncia ter uma das opções; entre grupos, precisa atender a todos. A data
// é a do registro, por atalho ou por um período escolhido no calendário
class FiltrosDeDenuncia {
  final Map<GrupoDaDenuncia, Set<String>> marcados;
  final AtalhoDeData? atalho;
  final PeriodoDeDias? periodo;

  const FiltrosDeDenuncia({
    this.marcados = const {},
    this.atalho,
    this.periodo,
  });

  // As opções marcadas no grupo
  Set<String> de(GrupoDaDenuncia grupo) => marcados[grupo] ?? const {};

  // Se a data está filtrada, por atalho ou por período
  bool get temData => atalho != null || periodo != null;

  // Se nenhum filtro está marcado
  bool get vazio =>
      !temData && marcados.values.every((opcoes) => opcoes.isEmpty);

  // Quantos filtros estão marcados no total; a data conta como um
  int get quantos =>
      marcados.values.fold(0, (soma, opcoes) => soma + opcoes.length) +
      (temData ? 1 : 0);

  // O intervalo de dias que o filtro de data aceita, ou null sem data
  PeriodoDeDias? intervalo(DateTime agora) {
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return switch (atalho) {
      AtalhoDeData.hoje => (de: hoje, ate: hoje),
      AtalhoDeData.seteDias => (
        de: hoje.subtract(const Duration(days: 6)),
        ate: hoje,
      ),
      AtalhoDeData.trintaDias => (
        de: hoje.subtract(const Duration(days: 29)),
        ate: hoje,
      ),
      null => periodo,
    };
  }

  // Se a denúncia passa por todos os filtros marcados
  bool combina(Denuncia denuncia, DateTime agora) {
    for (final MapEntry(key: grupo, value: opcoes) in marcados.entries) {
      if (opcoes.isEmpty) continue;
      if (!opcoes.any(valoresDaDenuncia(denuncia, grupo).contains)) {
        return false;
      }
    }
    final dias = intervalo(agora);
    if (dias == null) return true;
    final momento = denuncia.registradaEm;
    final dia = DateTime(momento.year, momento.month, momento.day);
    return !dia.isBefore(dias.de) && !dia.isAfter(dias.ate);
  }

  // Substitui de uma vez as opções marcadas em um grupo
  FiltrosDeDenuncia comGrupo(GrupoDaDenuncia grupo, Set<String> opcoes) =>
      FiltrosDeDenuncia(
        marcados: {...marcados, grupo: opcoes},
        atalho: atalho,
        periodo: periodo,
      );

  // Marca a opção ou, se ela já estava marcada, desmarca
  FiltrosDeDenuncia alternar(GrupoDaDenuncia grupo, String opcao) {
    final atuais = de(grupo);
    return comGrupo(
      grupo,
      atuais.contains(opcao)
          ? ({...atuais}..remove(opcao))
          : {...atuais, opcao},
    );
  }

  // Troca a data por um atalho, por um período ou por nenhuma das duas
  FiltrosDeDenuncia comData({AtalhoDeData? atalho, PeriodoDeDias? periodo}) =>
      FiltrosDeDenuncia(marcados: marcados, atalho: atalho, periodo: periodo);
}

// Os valores da denúncia em um grupo, já no texto exibido nas opções.
// Espécie, porte ou sexo vazios (denúncias antigas) não geram valor
Set<String> valoresDaDenuncia(Denuncia denuncia, GrupoDaDenuncia grupo) =>
    switch (grupo) {
      GrupoDaDenuncia.tipo => {denuncia.tipo.rotulo},
      GrupoDaDenuncia.situacao => {denuncia.situacao.rotulo},
      GrupoDaDenuncia.especie => {
        if (denuncia.especie.trim().isNotEmpty) denuncia.especie.trim(),
      },
      GrupoDaDenuncia.porte => {
        if (denuncia.porte.trim().isNotEmpty)
          denuncia.porte.trim().toLowerCase(),
      },
      GrupoDaDenuncia.sexo => {
        if (denuncia.sexo.trim().isNotEmpty) denuncia.sexo.trim().toLowerCase(),
      },
      GrupoDaDenuncia.bairro => {
        if (denuncia.bairro.trim().isNotEmpty) denuncia.bairro.trim(),
      },
    };

// As opções de cada grupo. O bairro vem das denúncias da lista, em ordem
// alfabética, para não oferecer opção que não retorna nenhuma denúncia
List<String> opcoesDaDenuncia(
  GrupoDaDenuncia grupo,
  Iterable<Denuncia> denuncias,
) => switch (grupo) {
  GrupoDaDenuncia.tipo => [
    for (final tipo in TipoDeDenuncia.values) tipo.rotulo,
  ],
  GrupoDaDenuncia.situacao => [
    for (final situacao in SituacaoDaDenuncia.values) situacao.rotulo,
  ],
  GrupoDaDenuncia.especie => especiesDaDenuncia,
  GrupoDaDenuncia.porte => portesDaDenuncia,
  GrupoDaDenuncia.sexo => sexosDaDenuncia,
  GrupoDaDenuncia.bairro => {
    for (final denuncia in denuncias)
      ...valoresDaDenuncia(denuncia, GrupoDaDenuncia.bairro),
  }.toList()..sort((a, b) => semAcento(a).compareTo(semAcento(b))),
};

// Se a denúncia contém o texto buscado: o protocolo sem hífen nem espaço
// ("pa 2026" encontra "PA-20261022-9204"), ou a descrição, a rua, o bairro e
// a raça sem acentos. Busca vazia aceita todas
bool denunciaContem(Denuncia denuncia, String busca) {
  final texto = semAcento(busca.trim());
  if (texto.isEmpty) return true;
  String protocolo(String valor) =>
      valor.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  final numero = protocolo(busca);
  if (numero.isNotEmpty && protocolo(denuncia.protocolo).contains(numero)) {
    return true;
  }
  return [
    denuncia.descricao,
    denuncia.rua,
    denuncia.bairro,
    denuncia.raca,
  ].any((campo) => semAcento(campo).contains(texto));
}
