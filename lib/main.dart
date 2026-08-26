import 'package:flutter/material.dart';
import 'telas/feed_adocao.dart';

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
      home: const FeedAdocao(),
    );
  }
}
