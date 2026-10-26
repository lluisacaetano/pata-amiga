// Pacote flutter_test: ferramentas de teste de widgets e de unidade do Flutter.
import 'package:flutter_test/flutter_test.dart';
// Arquivo animais_mock.dart: animais de exemplo usados como base.
import 'package:pata_amiga/dados/animais_mock.dart';
// Arquivo animal.dart: modelo do animal e o seu status.
import 'package:pata_amiga/modelos/animal.dart';
// Arquivo avisos_de_denuncia.dart: notificações de denúncias.
import 'package:pata_amiga/modelos/avisos_de_denuncia.dart';
// Arquivo denuncia.dart: modelo da denúncia e as situações.
import 'package:pata_amiga/modelos/denuncia.dart';
// Arquivo etapa_do_historico.dart: as mudanças de situação.
import 'package:pata_amiga/modelos/etapa_do_historico.dart';
// Arquivo ong.dart: modelo da ONG e as finalidades.
import 'package:pata_amiga/modelos/ong.dart';

void main() {
  final agora = DateTime(2026, 10, 26, 12);

  // Denúncia de exemplo enviada à organização de id 2
  Denuncia denuncia({
    String id = '1',
    bool anonima = true,
    List<EtapaDoHistorico>? historico,
    Duration registradaHa = const Duration(hours: 2),
  }) => Denuncia(
    id: id,
    protocolo: 'PA-20261026-000$id',
    tipo: TipoDeDenuncia.mausTratos,
    descricao: 'Cachorro preso sem água.',
    rua: 'Rua Barão de Piumhi',
    bairro: 'Centro',
    anonima: anonima,
    denuncianteNome: 'Ana',
    denuncianteTelefone: '37999990000',
    denuncianteEmail: 'ana@example.com',
    registradaEm: agora.subtract(registradaHa),
    ongId: '2',
    historico:
        historico ??
        [
          EtapaDoHistorico(
            situacao: SituacaoDaDenuncia.recebida.name,
            observacao: 'Denúncia registrada pelo app.',
            em: agora.subtract(registradaHa),
          ),
        ],
  );

  group('finalidades da organização', () {
    // ONG gravada antes do campo vale como adoção, perdidos e resgate, sem
    // denúncias
    test('a ONG antiga não recebe denúncias', () {
      final ong = Ong.fromJson({
        'nome': 'Antiga',
        'responsavelEmail': 'a@example.com',
      });
      expect(ong.finalidades, finalidadesPadrao);
      expect(ong.recebeDenuncias, isFalse);
    });

    // Só a finalidade "denúncias" faz a organização receber denúncias
    test('a finalidade de denúncias vai e volta da API', () {
      final ong = Ong.fromJson({
        'nome': 'APAF',
        'responsavelEmail': 'a@example.com',
        'finalidades': ['denuncias', 'desconhecida'],
      });
      expect(ong.recebeDenuncias, isTrue);
      expect(Ong.fromJson(ong.toJson()).finalidades, {
        FinalidadeDaOng.denuncias,
      });
    });
  });

  group('denúncia para a organização', () {
    // A anônima não leva nome, telefone nem e-mail para a API
    test('a anônima não grava quem denunciou; a identificada grava', () {
      final anonima = denuncia().toJson();
      expect(anonima['denuncianteNome'], '');
      expect(anonima['denuncianteTelefone'], '');
      final identificada = denuncia(anonima: false).toJson();
      expect(identificada['denuncianteNome'], 'Ana');
      expect(identificada['denuncianteTelefone'], '37999990000');
      expect(identificada['ongId'], 2);
    });

    // Mudar a situação acrescenta a etapa com a observação e o autor
    test('a situação atual é a da última etapa do histórico', () {
      final apurando = denuncia().comSituacao(
        SituacaoDaDenuncia.emApuracao,
        observacao: ' Equipe foi ao local. ',
        autor: 'Carla Souza',
        em: agora,
      );
      expect(apurando.situacao, SituacaoDaDenuncia.emApuracao);
      expect(apurando.historico, hasLength(2));
      expect(apurando.historico.last.observacao, 'Equipe foi ao local.');
      expect(apurando.historico.last.autor, 'Carla Souza');
      expect(Denuncia.fromJson(apurando.toJson()).historico, hasLength(2));
    });
  });

  group('notificações de denúncia', () {
    // A denúncia sem mudança notifica a organização; depois de mudar, não
    test('a organização é avisada só da denúncia ainda sem resposta', () {
      final nova = denuncia(id: '1');
      final respondida = denuncia(id: '2').comSituacao(
        SituacaoDaDenuncia.emApuracao,
        observacao: 'Em análise.',
        autor: 'Carla Souza',
        em: agora,
      );
      final avisos = avisosDeDenuncia(
        daOrganizacao: [nova, respondida],
        minhas: const [],
        dispensadas: const {},
        agora: agora,
      );
      expect(avisos.map((aviso) => aviso.denuncia.id), ['1']);
      expect(avisos.single.tipo, TipoDeAvisoDeDenuncia.nova);
    });

    // Quem denunciou é avisado de cada mudança, até dispensar
    test('quem denunciou é avisado da mudança de situação', () {
      final respondida = denuncia().comSituacao(
        SituacaoDaDenuncia.encerrada,
        observacao: 'Tutor orientado.',
        autor: 'Carla Souza',
        em: agora,
      );
      final avisos = avisosDeDenuncia(
        daOrganizacao: const [],
        minhas: [respondida],
        dispensadas: const {},
        agora: agora,
      );
      expect(avisos.single.tipo, TipoDeAvisoDeDenuncia.situacao);
      expect(
        avisosDeDenuncia(
          daOrganizacao: const [],
          minhas: [respondida],
          dispensadas: {avisos.single.chave},
          agora: agora,
        ),
        isEmpty,
      );
    });
  });

  group('histórico do animal', () {
    // A mudança de status grava a etapa com a observação de quem mudou
    test('marcar como adotado acrescenta a etapa com a observação', () {
      final adotado = animaisMock.first.comStatusObservado(
        StatusAnimal.adotado,
        observacao: 'Adotado pela família Pereira.',
        autor: 'Carla Souza',
        em: agora,
      );
      expect(adotado.status, StatusAnimal.adotado);
      expect(adotado.historico.single.situacao, 'adotado');
      expect(
        adotado.historico.single.observacao,
        'Adotado pela família Pereira.',
      );
      expect(Animal.fromJson(adotado.toJson()).historico, hasLength(1));
    });
  });
}
