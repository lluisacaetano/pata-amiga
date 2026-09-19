//Padronização de rotas da aplicação
import 'package:flutter/material.dart';

import '../modelos/animal.dart';
import '../telas/feed_adocao.dart';
import '../telas/detalhes_animal.dart';
import '../telas/cadastro_animal.dart';

class AppRoutes {
  static const feed = '/';
  static const detalhesAnimal = '/detalhes-animal';
  static const cadastroAnimal = '/cadastro-animal';

  static Map<String, WidgetBuilder> get routes => {
    feed: (_) => const FeedAdocao(),
    detalhesAnimal: (context) {
      final animal = ModalRoute.of(context)!.settings.arguments as Animal;
      return DetalhesAnimal(animal: animal);
    },
    cadastroAnimal: (_) => const CadastroAnimal(),
  };
}
