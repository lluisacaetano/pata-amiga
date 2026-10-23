// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo estado_pata_amiga.dart: estado global com a lista de animais.
import '../estado/estado_pata_amiga.dart';
// Arquivo animal.dart: modelo do animal e o status do registro.
import '../modelos/animal.dart';
// Arquivo ong.dart: modelo da ONG.
import '../modelos/ong.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo animal_service.dart: serviço que grava os animais na API.
import '../services/animal_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo painel_de_confirmacao.dart: painel inferior de confirmação.
import 'painel_de_confirmacao.dart';

// Ações do dono sobre o próprio registro: encerrar ou reabrir, editar,
// transferir para uma ONG e, após um resgate, publicar para adoção. São
// compartilhadas pela tela de detalhes e pela lista "Meus registros"

// Argumento da rota de cadastro que indica edição de um registro existente
// (em vez de um cadastro novo)
class EdicaoDoRegistro {
  final Animal animal;

  const EdicaoDoRegistro(this.animal);
}

// Alterna o status do animal entre disponível e o desfecho do tipo
// (adotado, encontrado ou resgatado), após confirmação, porque a mudança tira
// ou devolve o animal ao feed e ao mapa. Grava na API, atualiza o estado
// local e, num resgate concluído, oferece publicar para adoção
Future<void> mudarStatus(
  BuildContext context,
  Animal atual, {
  AnimalService? api,
}) async {
  final novo = atual.finalizado ? StatusAnimal.disponivel : atual.desfecho;
  final voltando = novo == StatusAnimal.disponivel;
  final textoNovo = atual.comStatus(novo).rotuloDoStatus;
  final confirmou = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.cores.cartao,
    showDragHandle: true,
    builder: (painel) => PainelDeConfirmacao(
      titulo: voltando
          ? 'Retornar ${atual.nome} para "$textoNovo"?'
          : 'Marcar ${atual.nome} como $textoNovo?',
      texto: voltando
          ? 'O animal voltará a ser exibido no feed e no mapa.'
          : 'O animal deixará de ser exibido no feed e no mapa. A alteração '
                'pode ser revertida a qualquer momento.',
      rotuloPrincipal: 'Confirmar',
      aoPrincipal: () => Navigator.pop(painel, true),
      rotuloSecundario: 'Cancelar',
      aoSecundario: () => Navigator.pop(painel, false),
    ),
  );
  if (confirmou != true || !context.mounted) return;

  final estado = PataAmigaScope.of(context);
  final mensageiro = ScaffoldMessenger.of(context);
  try {
    await (api ?? AnimalService()).atualizarStatus(atual, novo);
  } on Exception {
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Não foi possível mudar agora. Tente de novo.'),
        ),
      );
    return;
  }
  await estado.substituirAnimal(atual.comStatus(novo));
  if (novo == StatusAnimal.resgatado && context.mounted) {
    await _oferecerAdocao(context, atual, api);
  }
}

// Transfere para a ONG um animal publicado em nome próprio, após
// confirmação. O registro passa a ter o contato da ONG, aparece no perfil
// dela e sai de "Meus registros"; qualquer membro da ONG pode atualizá-lo
Future<void> enviarParaOng(
  BuildContext context,
  Animal atual,
  Ong ong, {
  AnimalService? api,
}) async {
  final confirmou = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.cores.cartao,
    showDragHandle: true,
    builder: (painel) => PainelDeConfirmacao(
      titulo: 'Transferir ${atual.nome} para ${ong.nome}?',
      texto:
          'O animal passa a aparecer no perfil da ONG, com o contato dela, e '
          'sai de Meus registros. Qualquer pessoa da ONG poderá atualizar o '
          'status e o registro dele.',
      rotuloPrincipal: 'Confirmar',
      aoPrincipal: () => Navigator.pop(painel, true),
      rotuloSecundario: 'Cancelar',
      aoSecundario: () => Navigator.pop(painel, false),
    ),
  );
  if (confirmou != true || !context.mounted) return;

  final estado = PataAmigaScope.of(context);
  final mensageiro = ScaffoldMessenger.of(context);
  final daOng = Animal.fromJson({
    ...atual.toJson(),
    'ongId': ong.id,
    'dono': {'nome': ong.nome, 'telefone': ong.telefone},
  });
  try {
    await (api ?? AnimalService()).atualizarAnimal(daOng);
  } on Exception {
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Não foi possível transferir agora. Tente de novo.'),
        ),
      );
    return;
  }
  await estado.substituirAnimal(daOng);
  mensageiro
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${atual.nome} agora aparece no perfil de ${ong.nome}.'),
      ),
    );
}

// Abre o cadastro preenchido para edição. O formulário já grava na API antes
// de fechar; aqui o estado local é atualizado com o registro devolvido
Future<void> editarRegistro(BuildContext context, Animal atual) async {
  final estado = PataAmigaScope.of(context);
  final mensageiro = ScaffoldMessenger.of(context);
  final editado = await Navigator.pushNamed(
    context,
    AppRoutes.registerAnimal,
    arguments: EdicaoDoRegistro(atual),
  );
  if (editado is! Animal) return;
  await estado.substituirAnimal(editado, chaveAntiga: atual.chave);
  mensageiro
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Alterações salvas.')));
}

// Após um resgate, pergunta se a pessoa quer publicar o animal para adoção
Future<void> _oferecerAdocao(
  BuildContext context,
  Animal atual,
  AnimalService? api,
) async {
  final publicar = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.cores.cartao,
    showDragHandle: true,
    builder: (painel) => PainelDeConfirmacao(
      icone: Icons.check_circle,
      titulo: 'Resgate concluído',
      texto:
          'Deseja publicar ${atual.nome} para adoção? O cadastro será aberto '
          'com os dados e as fotos do resgate para você completar.',
      rotuloPrincipal: 'Publicar para adoção',
      iconeDoPrincipal: Icons.favorite_border,
      aoPrincipal: () => Navigator.pop(painel, true),
      rotuloSecundario: 'Agora não',
      aoSecundario: () => Navigator.pop(painel, false),
    ),
  );
  if (publicar == true && context.mounted) {
    await publicarParaAdocao(context, atual, api: api);
  }
}

// Abre o cadastro preenchido com os dados do resgate e o tipo Adoção. Se a
// API falhar, o registro fica salvo apenas no aparelho e o aviso informa isso
Future<void> publicarParaAdocao(
  BuildContext context,
  Animal atual, {
  AnimalService? api,
}) async {
  final estado = PataAmigaScope.of(context);
  final mensageiro = ScaffoldMessenger.of(context);
  final novo = await Navigator.pushNamed(
    context,
    AppRoutes.registerAnimal,
    arguments: atual,
  );
  if (novo is! Animal) return;
  var naApi = true;
  try {
    await (api ?? AnimalService()).criarAnimal(novo);
  } on Exception {
    naApi = false;
  }
  await estado.registrarCadastro(novo);
  estado.atualizarAnimais([...estado.animais, novo]);
  mensageiro
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          naApi
              ? '${novo.nome} foi publicado para adoção.'
              : '${novo.nome} foi publicado só neste aparelho. '
                    'Não foi possível enviar à API.',
        ),
      ),
    );
}
