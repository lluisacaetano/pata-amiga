import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../tema/cores.dart';

class ReportarScreen extends StatefulWidget {
  const ReportarScreen({super.key});

  @override
  State<ReportarScreen> createState() => _ReportarScreenState();
}

class _ReportarScreenState extends State<ReportarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _localController = TextEditingController();
  final _seletorDeFoto = ImagePicker();

  String? _tipo;
  DateTime? _data;
  XFile? _foto;

  static const _tipos = {
    'maus-tratos': 'Maus-tratos',
    'abandono': 'Abandono',
    'negligencia': 'Negligência',
    'outros': 'Outros',
  };

  @override
  void dispose() {
    _descricaoController.dispose();
    _localController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _data ?? hoje,
      firstDate: DateTime(2000),
      lastDate: DateTime(hoje.year, hoje.month, hoje.day),
      helpText: 'Quando aconteceu?',
    );
    if (data != null && mounted) setState(() => _data = data);
  }

  Future<void> _selecionarFoto() async {
    try {
      final foto = await _seletorDeFoto.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (foto != null && mounted) setState(() => _foto = foto);
    } on Exception {
      if (mounted) _avisar('Não foi possível abrir a galeria neste aparelho.');
    }
  }

  void _enviarDenuncia() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    _avisar(
      'O envio ainda não está disponível. Nenhuma denúncia foi enviada ou salva.',
    );
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/${data.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.cores.fundo,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          color: context.cores.principal,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Denunciar situação',
          style: TextStyle(
            color: context.cores.principal,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cores.principalClara,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: context.cores.principal),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Relate apenas o que você observou, com o máximo de '
                        'clareza e responsabilidade. Evite suposições e '
                        'compartilhe somente informações necessárias.',
                        style: TextStyle(height: 1.4, color: context.cores.texto),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _CampoSecao(
                titulo: 'Tipo de denúncia',
                icone: Icons.report_outlined,
                child: DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  decoration: _decoracaoCampo(
                    context,
                    hint: 'Selecione uma opção',
                  ),
                  items: _tipos.entries
                      .map(
                        (tipo) => DropdownMenuItem(
                          value: tipo.key,
                          child: Text(tipo.value),
                        ),
                      )
                      .toList(),
                  onChanged: (tipo) => setState(() => _tipo = tipo),
                  validator: (tipo) =>
                      tipo == null ? 'Selecione o tipo de denúncia.' : null,
                ),
              ),
              const SizedBox(height: 14),
              _CampoSecao(
                titulo: 'O que aconteceu?',
                icone: Icons.notes_outlined,
                child: TextFormField(
                  key: const Key('descricao-denuncia'),
                  controller: _descricaoController,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoracaoCampo(
                    context,
                    hint: 'Descreva a situação com detalhes importantes.',
                    alignLabelWithHint: true,
                  ),
                  validator: (valor) => valor == null || valor.trim().isEmpty
                      ? 'Descreva o que aconteceu.'
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              _CampoSecao(
                titulo: 'Endereço ou local aproximado',
                icone: Icons.location_on_outlined,
                child: TextFormField(
                  key: const Key('local-denuncia'),
                  controller: _localController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoracaoCampo(
                    context,
                    hint: 'Rua, bairro, ponto de referência ou cidade',
                  ),
                  validator: (valor) => valor == null || valor.trim().isEmpty
                      ? 'Informe o endereço ou local aproximado.'
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              _CampoSecao(
                titulo: 'Data da ocorrência (opcional)',
                icone: Icons.calendar_today_outlined,
                child: OutlinedButton.icon(
                  onPressed: _selecionarData,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _data == null ? 'Selecionar data' : _formatarData(_data!),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.cores.principal,
                    side: BorderSide(color: context.cores.borda),
                    minimumSize: const Size.fromHeight(48),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _CampoSecao(
                titulo: 'Fotos (opcional)',
                icone: Icons.photo_camera_outlined,
                child: _foto == null
                    ? OutlinedButton.icon(
                        onPressed: _selecionarFoto,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Anexar uma foto'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.cores.principal,
                          side: BorderSide(color: context.cores.borda),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.image_outlined,
                          color: context.cores.principal,
                        ),
                        title: Text(
                          _foto!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'Remover foto',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _foto = null),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _enviarDenuncia,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text(
                    'Enviar denúncia',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'O envio pelo aplicativo ainda não está disponível.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.cores.textoFraco, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoracaoCampo(
  BuildContext context, {
  required String hint,
  bool alignLabelWithHint = false,
}) {
  return InputDecoration(
    hintText: hint,
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: context.cores.cartao,
    contentPadding: const EdgeInsets.all(14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.cores.borda),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.cores.borda),
    ),
  );
}

class _CampoSecao extends StatelessWidget {
  const _CampoSecao({
    required this.titulo,
    required this.icone,
    required this.child,
  });

  final String titulo;
  final IconData icone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cores.cartao,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 20, color: context.cores.principal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: context.cores.texto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
