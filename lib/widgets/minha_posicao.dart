// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote flutter_map: mapa interativo com os blocos do OpenStreetMap.
import 'package:flutter_map/flutter_map.dart';
// Pacote latlong2: coordenadas (latitude e longitude) e cálculo de distâncias.
import 'package:latlong2/latlong.dart';

// Arquivo estado_pata_amiga.dart: última posição conhecida do aparelho.
import '../estado/estado_pata_amiga.dart';
// Arquivo localizacao_service.dart: leitura da posição sem pedir permissão.
import '../services/localizacao_service.dart';

// Camada do mapa com um ponto azul na posição atual do usuário. Usa a última
// posição conhecida pelo app e, se ainda não houver uma, tenta lê-la sem
// pedir permissão. Sem posição, não desenha nada
class CamadaDaMinhaPosicao extends StatefulWidget {
  const CamadaDaMinhaPosicao({super.key});

  @override
  State<CamadaDaMinhaPosicao> createState() => _CamadaDaMinhaPosicaoState();
}

class _CamadaDaMinhaPosicaoState extends State<CamadaDaMinhaPosicao> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _buscarSeFaltar());
  }

  // Lê a posição só quando o app ainda não tem nenhuma
  Future<void> _buscarSeFaltar() async {
    if (!mounted) return;
    final estado = PataAmigaScope.talvez(context);
    if (estado == null || estado.posicao != null) return;
    final posicao = await const LocalizacaoService().posicaoSemPedir();
    if (posicao != null && mounted) estado.atualizarPosicao(posicao);
  }

  @override
  Widget build(BuildContext context) {
    // Escuta o estado, para o ponto aparecer assim que a posição chegar
    final posicao = context
        .dependOnInheritedWidgetOfExactType<PataAmigaScope>()
        ?.notifier
        ?.posicao;
    // Sem posição, a camada fica vazia, mas continua sendo uma camada do
    // mapa, para não atrapalhar os gestos de arrastar e aproximar
    return MarkerLayer(
      markers: [
        if (posicao != null)
          Marker(
            point: LatLng(posicao.latitude, posicao.longitude),
            width: 22,
            height: 22,
            child: Semantics(
              label: 'Você está aqui',
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
