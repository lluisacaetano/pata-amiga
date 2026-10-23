// Biblioteca dart:io: File, para exibir a foto tirada pela câmera.
import 'dart:io';

// Pacote flutter/foundation: kIsWeb, para exibir a foto também na web.
import 'package:flutter/foundation.dart';
// Pacote flutter/material: componentes visuais do Material Design.
import 'package:flutter/material.dart';
// Pacote image_picker: abre a câmera ou a galeria para escolher fotos.
import 'package:image_picker/image_picker.dart';
// Pacote provider: compartilha estado entre as telas e as reconstrói.
import 'package:provider/provider.dart';

// Arquivo estado_pata_amiga.dart: estado compartilhado do app.
import '../estado/estado_pata_amiga.dart';
// Arquivo ponto_de_alimentacao.dart: ponto de alimentação e suas regras.
import '../modelos/ponto_de_alimentacao.dart';
// Arquivo usuario_provider.dart: dados do usuário logado.
import '../provider/usuario_provider.dart';
// Arquivo alimentacao_service.dart: acesso à API dos pontos de alimentação.
import '../services/alimentacao_service.dart';
// Arquivo localizacao_service.dart: leitura da posição atual do aparelho.
import '../services/localizacao_service.dart';
// Arquivo cores.dart: paleta de cores do tema claro e escuro.
import '../tema/cores.dart';

// Tela para confirmar o abastecimento de um ponto de alimentação. O registro
// só é aceito com a pessoa a até 150 m do ponto e uma vez por dia; a foto é
// opcional e aparece no resumo do ponto
class RegistrarAbastecimento extends StatefulWidget {
  final PontoDeAlimentacao ponto;
  final AlimentacaoService? servico;
  final LocalizacaoService? localizacao;

  const RegistrarAbastecimento({
    super.key,
    required this.ponto,
    this.servico,
    this.localizacao,
  });

  @override
  State<RegistrarAbastecimento> createState() => _RegistrarAbastecimentoState();
}

class _RegistrarAbastecimentoState extends State<RegistrarAbastecimento> {
  late final _servico = widget.servico ?? AlimentacaoService();
  late final _localizacao = widget.localizacao ?? LocalizacaoService();
  final _camera = ImagePicker();
  XFile? _foto;
  bool _salvando = false;
  String? _recusa;

  // Abre a câmera e guarda a foto escolhida para enviar com o registro
  Future<void> _tirarFoto() async {
    try {
      final foto = await _camera.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (foto != null && mounted) setState(() => _foto = foto);
    } on Exception {
      setState(() => _recusa = 'Não foi possível abrir a câmera.');
    }
  }

  // Lê a posição atual, aplica as regras de distância e de um registro por
  // dia e, se aprovado, grava o abastecimento na API e no estado do app
  Future<void> _confirmar() async {
    if (_salvando) return;
    setState(() {
      _salvando = true;
      _recusa = null;
    });
    final estado = PataAmigaScope.of(context);
    final usuario = context.read<UsuarioProvider?>()?.usuario;
    final agora = DateTime.now();
    try {
      final onde = await _localizacao.posicaoAtual();
      final motivo = verificarAbastecimento(
        latitudeDoPonto: widget.ponto.latitude,
        longitudeDoPonto: widget.ponto.longitude,
        idDoPonto: widget.ponto.id,
        latitudeDaPessoa: onde.latitude,
        longitudeDaPessoa: onde.longitude,
        email: usuario?.email ?? '',
        abastecimentos: estado.abastecimentos,
        agora: agora,
      );
      if (motivo != null) {
        setState(() {
          _salvando = false;
          _recusa = motivo.texto;
        });
        return;
      }
      final gravado = await _servico.registrarAbastecimento(
        Abastecimento(
          ponto: widget.ponto.id!,
          data: agora,
          registradoPor: usuario?.nome.trim() ?? '',
          email: usuario?.email ?? '',
          foto: _foto?.path ?? '',
        ),
      );
      estado.adicionarAbastecimento(gravado);
      if (!mounted) return;
      Navigator.pop(context, gravado);
    } on ErroDeLocalizacao catch (erro) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _recusa = erro.texto;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _recusa = 'Não foi possível registrar agora. Tente de novo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ponto = widget.ponto;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.cores.fundo,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
            color: context.cores.principal,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          'REGISTRAR ABASTECIMENTO',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.cores.principal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Cartao(
            icone: Icons.place_outlined,
            titulo: ponto.tipo.rotulo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ponto.lugar.isNotEmpty)
                  Text(
                    ponto.lugar,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (ponto.referencia.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ponto.referencia,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.cores.textoFraco,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.cores.principalClara,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.my_location, size: 18, color: context.cores.principal),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ao confirmar, conferimos se você está no ponto. '
                          'O abastecimento só vale a até 150 m dele, uma vez '
                          'por dia.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.cores.texto,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Cartao(
            icone: Icons.photo_camera_outlined,
            titulo: 'Foto (opcional)',
            child: _foto == null
                ? OutlinedButton.icon(
                    onPressed: _tirarFoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Tirar foto do ponto abastecido'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.cores.principal,
                      side: BorderSide(color: context.cores.principal),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: kIsWeb
                              ? Image.network(_foto!.path, fit: BoxFit.cover)
                              : Image.file(
                                  File(_foto!.path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      ColoredBox(color: context.cores.fundo),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: context.cores.cartao,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Remover foto',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _foto = null),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          if (_recusa != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: context.cores.destaque,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _recusa!,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.cores.destaque,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          FilledButton.icon(
            onPressed: _salvando ? null : _confirmar,
            icon: _salvando
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.sobrePrincipal,
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(
              _salvando
                  ? 'Conferindo sua localização…'
                  : 'Confirmar abastecimento',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: context.cores.principal,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Cartão de seção do formulário: fundo de cartão, borda e título com ícone
// na cor principal, no mesmo padrão do cadastro de animal
class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.icone,
    required this.titulo,
    required this.child,
  });

  final IconData icone;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: context.cores.principal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: context.cores.principal,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
