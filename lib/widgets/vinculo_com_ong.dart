import 'package:flutter/material.dart';

import '../modelos/ong.dart';
import '../routes/route_names.dart';
import '../tema/cores.dart';
import 'avatar_da_ong.dart';

// O vínculo da pessoa com a ONG, no cabeçalho do "Meu perfil", logo abaixo
// do contato: a ONG faz parte de quem a pessoa é, e não é um bloco à parte.
// Tocar abre o perfil da ONG, onde quem a criou tem o editar. Quem pediu
// para entrar vê a mesma etiqueta, aguardando. Sem ONG, nada aparece: criar
// ou entrar numa ONG fica no "Editar perfil"
class VinculoComOng extends StatelessWidget {
  final Ong? ong;
  // A ONG em que a pessoa pediu para entrar, enquanto não houver resposta
  final Ong? pedida;

  const VinculoComOng({super.key, required this.ong, this.pedida});

  @override
  Widget build(BuildContext context) {
    final ong = this.ong;
    final pedida = this.pedida;
    if (ong == null && pedida == null) return const SizedBox.shrink();
    final aguardando = ong == null;
    final alvo = (ong ?? pedida)!;
    return Material(
      color: context.cores.principalClara,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.perfilOng, arguments: alvo),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (aguardando)
                Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.schedule,
                    size: 18,
                    color: context.cores.principal,
                  ),
                )
              else
                AvatarDaOng(ong: alvo, raio: 11),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  aguardando ? 'Aguardando ${alvo.nome}' : alvo.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.cores.principal,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: context.cores.principal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
