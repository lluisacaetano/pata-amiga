// Pacote flutter/foundation: kIsWeb e defaultTargetPlatform (plataforma).
import 'package:flutter/foundation.dart';

// Endereço base da API local, compartilhado por todos os serviços. No
// navegador e no desktop é localhost; no emulador Android, 10.0.2.2 aponta
// para o computador. Em celular físico, troque pelo IP do computador na rede
final enderecoDaApi = kIsWeb || defaultTargetPlatform != TargetPlatform.android
    ? 'http://localhost:3000'
    : 'http://10.0.2.2:3000';
