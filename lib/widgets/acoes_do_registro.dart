import 'package:flutter/material.dart';

import '../estado/estado_pata_amiga.dart';
import '../modelos/animal.dart';
import '../modelos/ong.dart';
import '../routes/route_names.dart';
import '../services/animal_service.dart';
import '../tema/cores.dart';

// O que quem cadastrou faz com o próprio registro: encerrar (ou reabrir),
// editar e, depois do resgate, publicar para adoção. A ficha e a lista de
// "Meus registros" usam as mesmas ações

// O argumento da rota de cadastro quando ela abre para editar um registro
class EdicaoDoRegistro {
  final Animal animal;

  const EdicaoDoRegistro(this.animal);
}

// Marca o desfecho (adotado, encontrado ou resgatado) ou volta atrás.
// Confirma antes, porque o animal sai do feed e do mapa
Future<void> mudarStatus(
  BuildContext context,
  Animal atual, {
  AnimalService? api,
}) async {
  final novo = atual.finalizado ? StatusAnimal.disponivel : atual.desfecho;
  final voltando = novo == StatusAnimal.disponivel;
  final textoNovo = atual.comStatus(novo).rotuloDoStatus;
  // O mesmo painel de baixo das outras confirmações do app
  final confirmou = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Cores.cartao,
    showDragHandle: true,
    builder: (painel) => _ConfirmarStatus(
      titulo: voltando
          ? 'Retornar ${atual.nome} para "$textoNovo"?'
          : 'Marcar ${atual.nome} como $textoNovo?',
      texto: voltando
          ? 'O animal voltará a ser exibido no feed e no mapa.'
          : 'O animal deixará de ser exibido no feed e no mapa. A alteração '
                'pode ser revertida a qualquer momento.',
      aoConfirmar: () => Navigator.pop(painel, true),
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

// Quem entrou numa ONG leva para ela um animal que tinha publicado em nome
// próprio: ele passa a sair com o contato da ONG e a aparecer no perfil dela,
// e sai de "Meus registros". A partir daí, qualquer pessoa da ONG cuida dele
Future<void> enviarParaOng(
  BuildContext context,
  Animal atual,
  Ong ong, {
  AnimalService? api,
}) async {
  final confirmou = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Cores.cartao,
    showDragHandle: true,
    builder: (painel) => _ConfirmarStatus(
      titulo: 'Transferir ${atual.nome} para ${ong.nome}?',
      texto:
          'O animal passa a aparecer no perfil da ONG, com o contato dela, e '
          'sai de Meus registros. Qualquer pessoa da ONG poderá atualizar o '
          'status e o registro dele.',
      aoConfirmar: () => Navigator.pop(painel, true),
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

// Abre o cadastro com todos os dados do registro. O formulário grava na API
// antes de fechar; aqui só falta atualizar o feed, a ficha e o perfil
Future<void> editarRegistro(
  BuildContext context,
  Animal atual, {
  AnimalService? api,
}) async {
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

// Depois do resgate, o convite para publicar o animal para adoção
Future<void> _oferecerAdocao(
  BuildContext context,
  Animal atual,
  AnimalService? api,
) async {
  final publicar = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Cores.cartao,
    showDragHandle: true,
    builder: (painel) => _OfertaDeAdocao(
      nome: atual.nome,
      aoPublicar: () => Navigator.pop(painel, true),
    ),
  );
  if (publicar == true && context.mounted) {
    await publicarParaAdocao(context, atual, api: api);
  }
}

// Abre o cadastro já preenchido com os dados do resgate e o tipo Adoção
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

// Antes de mudar o status: o que vai acontecer e a confirmação
class _ConfirmarStatus extends StatelessWidget {
  const _ConfirmarStatus({
    required this.titulo,
    required this.texto,
    required this.aoConfirmar,
  });

  final String titulo;
  final String texto;
  final VoidCallback aoConfirmar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Cores.textoFraco,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: aoConfirmar,
              style: FilledButton.styleFrom(
                backgroundColor: Cores.principal,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Confirmar'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Cores.textoFraco),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

// Depois de marcar como resgatado: o convite para publicar para adoção
class _OfertaDeAdocao extends StatelessWidget {
  const _OfertaDeAdocao({required this.nome, required this.aoPublicar});

  final String nome;
  final VoidCallback aoPublicar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, size: 40, color: Cores.principal),
            const SizedBox(height: 10),
            const Text(
              'Resgate concluído',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Deseja publicar $nome para adoção? O cadastro será aberto com '
              'os dados e as fotos do resgate para você completar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Cores.textoFraco,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: aoPublicar,
              icon: const Icon(Icons.favorite_border, size: 18),
              label: const Text('Publicar para adoção'),
              style: FilledButton.styleFrom(
                backgroundColor: Cores.principal,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Cores.textoFraco),
              child: const Text('Agora não'),
            ),
          ],
        ),
      ),
    );
  }
}
