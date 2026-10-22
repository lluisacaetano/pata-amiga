import 'package:flutter/foundation.dart';

// Onde a API local responde. Chrome: localhost | Emulador Android: 10.0.2.2 |
// Celular: IP do PC. Fica num lugar só para todos os serviços usarem o mesmo
final enderecoDaApi = kIsWeb || defaultTargetPlatform != TargetPlatform.android
    ? 'http://localhost:3000'
    : 'http://10.0.2.2:3000';
