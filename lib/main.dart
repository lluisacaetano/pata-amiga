import 'package:flutter/material.dart';
import 'telas/feed_adocao.dart';
import 'tema/cores.dart';

void main() {
  runApp(const AplicativoPataAmiga());
}

class AplicativoPataAmiga extends StatelessWidget {
  const AplicativoPataAmiga({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pata Amiga',
      debugShowCheckedModeBanner: false,
      theme: temaPataAmiga(),
      home: const FeedAdocao(),
    );
  }
}
