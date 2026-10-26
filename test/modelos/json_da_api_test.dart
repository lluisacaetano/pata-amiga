// Biblioteca dart:convert: converte texto JSON em objetos e vice-versa.
import 'dart:convert';

// Pacote flutter_test: ferramentas de teste de widgets e de unidade do Flutter.
import 'package:flutter_test/flutter_test.dart';
// Pacote http: faz as requisições à API (GET, POST, PATCH, DELETE).
import 'package:http/http.dart' as http;
// Pacote http/testing: cliente HTTP falso (MockClient) para os testes.
import 'package:http/testing.dart';
// Arquivo animal.dart: modelo do animal e o seu status.
import 'package:pata_amiga/modelos/animal.dart';
// Arquivo avistamento.dart: modelo do avistamento.
import 'package:pata_amiga/modelos/avistamento.dart';
// Arquivo denuncia.dart: modelo da denúncia e os seus tipos.
import 'package:pata_amiga/modelos/denuncia.dart';
// Arquivo dono.dart: responsável pelo animal e o número no WhatsApp.
import 'package:pata_amiga/modelos/dono.dart';
// Arquivo json_da_api.dart: leitura dos ids e descarte de itens inválidos.
import 'package:pata_amiga/modelos/json_da_api.dart';
// Arquivo ong.dart: modelo da ONG.
import 'package:pata_amiga/modelos/ong.dart';
// Arquivo ponto_de_alimentacao.dart: pontos, abastecimentos e regra diária.
import 'package:pata_amiga/modelos/ponto_de_alimentacao.dart';
// Arquivo texto.dart: remoção de acentos e texto de há quantos dias.
import 'package:pata_amiga/modelos/texto.dart';
// Arquivo denuncia_service.dart: registro e busca das denúncias na API.
import 'package:pata_amiga/services/denuncia_service.dart';
// Pacote shared_preferences: guarda dados simples no aparelho (chave e valor).
import 'package:shared_preferences/shared_preferences.dart';

// JSON completo de um animal, com o id informado (número ou texto)
Map<String, dynamic> animalJson(Object? id) => {
  'id': id,
  'nome': 'Thor',
  'especie': 'cachorro',
  'sexo': 'macho',
  'porte': 'médio',
  'idade': 'adulto',
  'bairro': 'Centro',
  'cidade': 'Formiga',
  'tipo': 'adocao',
  'dono': {'nome': 'Ana', 'telefone': '37999990000'},
  'publicadoEm': '2026-10-01T10:00:00.000',
  'ongId': 2,
};

void main() {
  // Leitura do id da API, que pode chegar como número ou como texto
  group('id da API', () {
    // Id em texto é lido e devolvido igual
    test('aceita id em texto, como o json-server novo grava', () {
      final animal = Animal.fromJson(animalJson('x_cwI-8YbkU'));
      expect(animal.id, 'x_cwI-8YbkU');
      expect(animal.toJson()['id'], 'x_cwI-8YbkU');
    });

    // Id numérico vira texto no app e volta como número para a API
    test('aceita id numérico e o devolve como número', () {
      final animal = Animal.fromJson(animalJson(1));
      expect(animal.id, '1');
      expect(animal.ongId, '2');
      expect(animal.toJson()['id'], 1);
      expect(animal.toJson()['ongId'], 2);
    });

    // Todos os modelos aceitam id em texto, inclusive nas referências
    test('todos os modelos leem o id em texto', () {
      expect(Ong.fromJson({'id': 'ab12', 'nome': 'X'}).id, 'ab12');
      expect(Denuncia.fromJson({'id': 'cd34'}).id, 'cd34');
      expect(
        PontoDeAlimentacao.fromJson({
          'id': 'ef56',
          'tipo': 'comedouro',
          'latitude': -20.46,
          'longitude': -45.43,
          'cadastradoEm': '2026-10-01T10:00:00.000',
        }).id,
        'ef56',
      );
      final abastecimento = Abastecimento.fromJson({
        'id': 'gh78',
        'ponto': 'ef56',
        'data': '2026-10-01T10:00:00.000',
      });
      expect(abastecimento.id, 'gh78');
      expect(abastecimento.ponto, 'ef56');
      expect(
        Avistamento.fromJson({
          'id': 'ij90',
          'animal': 3,
          'data': '2026-10-01T10:00:00.000',
          'latitude': -20.46,
          'longitude': -45.43,
          'registradoEm': '2026-10-01T10:00:00.000',
        }).animal,
        '3',
      );
    });

    // Avistamento sem animal fica com a referência vazia
    test('avistamento sem animal não vira o texto "null"', () {
      final avistamento = Avistamento.fromJson({
        'data': '2026-10-01T10:00:00.000',
        'latitude': -20.46,
        'longitude': -45.43,
        'registradoEm': '2026-10-01T10:00:00.000',
      });
      expect(avistamento.animal, '');
    });
  });

  // Leitura de listas da API com itens inválidos
  group('lista com item defeituoso', () {
    // Itens sem campos obrigatórios ou com tipo desconhecido são descartados
    test('o item inválido fica de fora e os demais aparecem', () {
      final lista = [
        animalJson(1),
        {'id': 2, 'nome': 'Sem tipo'},
        {...animalJson(3), 'tipo': 'desconhecido'},
        'texto solto',
        animalJson('abc'),
      ];
      final animais = itensValidos(lista, Animal.fromJson);
      expect(animais.map((animal) => animal.id), ['1', 'abc']);
    });

    // Campos de texto ausentes viram vazio e o status desconhecido vira
    // disponível
    test('campos de texto ausentes ficam vazios', () {
      final animal = Animal.fromJson({
        'tipo': 'perdido',
        'publicadoEm': '2026-10-01T10:00:00.000',
        'status': 'inexistente',
      });
      expect(animal.nome, '');
      expect(animal.dono.telefone, '');
      expect(animal.status, StatusAnimal.disponivel);
    });
  });

  // Número do responsável no formato do WhatsApp (55 + DDD + número)
  group('WhatsApp do responsável', () {
    // Número no WhatsApp de um responsável com o telefone informado
    String numero(String telefone) =>
        Dono(nome: 'Ana', telefone: telefone).numeroNoWhatsApp;

    // Celular completo recebe o código do país
    test('celular completo ganha o 55', () {
      expect(numero('(37) 99999-0000'), '5537999990000');
    });

    // Celular de 8 dígitos recebe o 9 na frente
    test('celular de 8 dígitos ganha o 9', () {
      expect(numero('(37) 9999-0000'), '5537999990000');
    });

    // Telefone fixo mantém os 8 dígitos
    test('fixo continua com 8 dígitos', () {
      expect(numero('(37) 3321-0000'), '553733210000');
    });

    // O 0 antes do DDD e o 55 já digitado são retirados
    test('o 0 antes do DDD e o 55 repetido saem', () {
      expect(numero('037 99999-0000'), '5537999990000');
      expect(numero('+55 37 99999-0000'), '5537999990000');
    });

    // Sem telefone, o número fica vazio
    test('sem telefone, fica vazio', () {
      expect(numero(''), '');
    });
  });

  // Funções de texto compartilhadas
  group('textos', () {
    // semAcento tira acentos, inclusive o ñ, e normaliza os espaços
    test('semAcento trata o ñ e os espaços', () {
      expect(semAcento('  Água   Vermelha '), 'agua vermelha');
      expect(semAcento('Piñata'), 'pinata');
    });

    // haQuantosDias usa hoje, ontem, dias e, depois de 30 dias, meses
    test('haQuantosDias passa a meses depois de 30 dias', () {
      final agora = DateTime(2026, 10, 22, 9);
      expect(haQuantosDias(DateTime(2026, 10, 22, 1), agora), 'hoje');
      expect(haQuantosDias(DateTime(2026, 10, 21, 23), agora), 'ontem');
      expect(haQuantosDias(DateTime(2026, 10, 19), agora), 'há 3 dias');
      expect(haQuantosDias(DateTime(2026, 8, 20), agora), 'há 2 meses');
    });

    // Sem rua, o local da denúncia começa direto pelo bairro
    test('a mensagem da denúncia sem rua não deixa vírgula sobrando', () {
      final denuncia = Denuncia.fromJson({'bairro': 'Centro', 'rua': ''});
      expect(denuncia.mensagemParaOCanal, contains('Local: Centro, Formiga'));
    });
  });

  // A regra de um abastecimento por dia ignora maiúsculas e espaços no e-mail
  test('abastecimento compara o e-mail sem diferenciar maiúsculas', () {
    final agora = DateTime(2026, 10, 22, 15);
    final antes = [
      Abastecimento(
        ponto: '1',
        data: DateTime(2026, 10, 22, 8),
        email: 'Ana@Example.com ',
      ),
    ];
    expect(jaAbasteceuHoje('1', 'ana@example.com', antes, agora), isTrue);
  });

  // Protocolo da denúncia conferido na API antes de gravar
  group('protocolo da denúncia', () {
    // Cabeçalho das respostas falsas, em JSON com UTF-8
    const utf8Json = {'content-type': 'application/json; charset=utf-8'};
    setUp(() => SharedPreferences.setMockInitialValues({}));

    // Um protocolo que já existe na API é sorteado de novo antes de gravar
    test('protocolo repetido na API é sorteado de novo', () async {
      final gravadas = <Map<String, dynamic>>[
        {'id': 'a1', 'protocolo': 'PA-20261022-0001'},
      ];
      // API falsa: o GET procura pelo protocolo e o POST grava com id b2
      final cliente = MockClient((pedido) async {
        if (pedido.method == 'GET') {
          final protocolo = pedido.url.queryParameters['protocolo'];
          return http.Response(
            jsonEncode([
              for (final item in gravadas)
                if (item['protocolo'] == protocolo) item,
            ]),
            200,
            headers: utf8Json,
          );
        }
        final corpo = jsonDecode(pedido.body) as Map<String, dynamic>;
        final gravada = {...corpo, 'id': 'b2'};
        gravadas.add(gravada);
        return http.Response(jsonEncode(gravada), 201, headers: utf8Json);
      });
      final denuncia = Denuncia(
        protocolo: 'PA-20261022-0001',
        tipo: TipoDeDenuncia.abandono,
        descricao: 'Cachorro deixado na praça.',
        rua: '',
        bairro: 'Centro',
        anonima: true,
        registradaEm: DateTime(2026, 10, 22, 9),
      );
      final gravada = await http.runWithClient(
        () => DenunciaService().registrar(denuncia),
        () => cliente,
      );
      expect(gravada.protocolo, isNot('PA-20261022-0001'));
      expect(gravada.protocolo, startsWith('PA-20261022-'));
      expect(gravada.id, 'b2');

      // Minhas denúncias busca só os protocolos guardados neste aparelho
      final minhas = await http.runWithClient(
        () => DenunciaService().minhasDenuncias(),
        () => cliente,
      );
      expect(minhas.map((item) => item.id), ['b2']);
    });
  });
}
