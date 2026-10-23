// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';

// Arquivo ong.dart: modelo da ONG.
import '../modelos/ong.dart';
// Arquivo route_names.dart: nomes das rotas de navegação.
import '../routes/route_names.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';
// Arquivo avatar_da_ong.dart: avatar circular da ONG.
import 'avatar_da_ong.dart';

// Etiqueta com a ONG do usuário, exibida no cabeçalho de "Meu perfil".
// Membro aprovado vê o avatar e o nome da ONG; quem tem pedido pendente vê
// "Aguardando <ONG>". O toque abre o perfil da ONG. Sem ONG nem pedido, não
// ocupa espaço
class VinculoComOng extends StatelessWidget {
  final Ong? ong;
  // ONG com pedido de entrada ainda não aprovado
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
