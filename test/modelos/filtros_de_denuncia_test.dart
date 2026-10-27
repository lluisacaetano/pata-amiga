// Pacote flutter_test: ferramentas de teste de widgets e de unidade do Flutter.
import 'package:flutter_test/flutter_test.dart';
// Arquivo racas.dart: a opção "Sem raça definida".
import 'package:pata_amiga/dados/racas.dart';
// Arquivo denuncia.dart: modelo da denúncia e as opções do animal.
import 'package:pata_amiga/modelos/denuncia.dart';
// Arquivo filtros_de_denuncia.dart: filtros e busca da lista de denúncias.
import 'package:pata_amiga/modelos/filtros_de_denuncia.dart';

void main() {
  final agora = DateTime(2026, 10, 26, 12);

  // Denúncia de exemplo, registrada há [dias] dias
  Denuncia denuncia({
    String protocolo = 'PA-20261026-0001',
    TipoDeDenuncia tipo = TipoDeDenuncia.mausTratos,
    String especie = 'Cachorro',
    String porte = 'médio',
    String sexo = 'macho',
    String raca = '',
    String descricao = 'Cachorro preso sem água.',
    String bairro = 'Centro',
    int dias = 0,
  }) => Denuncia(
    protocolo: protocolo,
    tipo: tipo,
    descricao: descricao,
    especie: especie,
    porte: porte,
    sexo: sexo,
    raca: raca,
    rua: 'Rua Barão de Piumhi',
    bairro: bairro,
    registradaEm: agora.subtract(Duration(days: dias)),
  );

  group('animal da denúncia', () {
    // Os campos do animal vão e voltam da API
    test('espécie, porte, sexo e raça vão e voltam da API', () {
      final volta = Denuncia.fromJson(
        denuncia(raca: semRacaDefinida, sexo: naoSei).toJson(),
      );
      expect(volta.especie, 'Cachorro');
      expect(volta.porte, 'médio');
      expect(volta.sexo, naoSei);
      expect(volta.raca, semRacaDefinida);
    });

    // O resumo deixa de fora o que a pessoa não soube informar
    test('o resumo do animal não mostra o "não sei"', () {
      expect(denuncia(porte: naoSei, sexo: naoSei).resumoDoAnimal, 'Cachorro');
      expect(denuncia().resumoDoAnimal, 'Cachorro, porte médio, macho');
    });
  });

  group('filtros da lista', () {
    // Dentro do grupo vale qualquer opção; entre grupos, precisa atender a
    // todos
    test('o tipo e a espécie precisam combinar juntos', () {
      final filtros = const FiltrosDeDenuncia()
          .alternar(GrupoDaDenuncia.tipo, 'Maus-tratos')
          .alternar(GrupoDaDenuncia.especie, 'Gato');
      expect(filtros.combina(denuncia(especie: 'Gato'), agora), isTrue);
      expect(filtros.combina(denuncia(), agora), isFalse);
      expect(
        filtros.combina(
          denuncia(especie: 'Gato', tipo: TipoDeDenuncia.abandono),
          agora,
        ),
        isFalse,
      );
      expect(filtros.quantos, 2);
    });

    // "7 dias" conta hoje e os seis dias anteriores
    test('o atalho de 7 dias aceita até seis dias atrás', () {
      final filtros = const FiltrosDeDenuncia().comData(
        atalho: AtalhoDeData.seteDias,
      );
      expect(filtros.combina(denuncia(dias: 6), agora), isTrue);
      expect(filtros.combina(denuncia(dias: 7), agora), isFalse);
      expect(filtros.quantos, 1);
    });

    // O período escolhido inclui o primeiro e o último dia
    test('o período inclui as duas pontas', () {
      final filtros = const FiltrosDeDenuncia().comData(
        periodo: (de: DateTime(2026, 10, 20), ate: DateTime(2026, 10, 24)),
      );
      expect(filtros.combina(denuncia(dias: 2), agora), isTrue);
      expect(filtros.combina(denuncia(dias: 6), agora), isTrue);
      expect(filtros.combina(denuncia(dias: 1), agora), isFalse);
      expect(filtros.combina(denuncia(dias: 7), agora), isFalse);
    });

    // A denúncia antiga, sem os dados do animal, sai quando o grupo filtra
    test('sem espécie, a denúncia não passa no filtro de espécie', () {
      final filtros = const FiltrosDeDenuncia().alternar(
        GrupoDaDenuncia.especie,
        'Cachorro',
      );
      expect(filtros.combina(denuncia(especie: ''), agora), isFalse);
    });
  });

  group('busca da lista', () {
    // O protocolo é achado sem hífen; o texto, sem acentos
    test('acha pelo protocolo, pela descrição e pelo bairro', () {
      final alvo = denuncia(
        protocolo: 'PA-20261026-4321',
        descricao: 'Gato sem água no quintal.',
        bairro: 'Água Vermelha',
      );
      expect(denunciaContem(alvo, 'pa 20261026 4321'), isTrue);
      expect(denunciaContem(alvo, '4321'), isTrue);
      expect(denunciaContem(alvo, 'agua'), isTrue);
      expect(denunciaContem(alvo, 'vermelha'), isTrue);
      expect(denunciaContem(alvo, 'cachorro'), isFalse);
      expect(denunciaContem(alvo, '  '), isTrue);
    });
  });
}
