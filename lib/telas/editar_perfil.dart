import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../provider/usuario_provider.dart';
import '../tema/cores.dart';
import '../widgets/mascaras.dart';

class EditarPerfil extends StatefulWidget {
  const EditarPerfil({super.key});

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;

  // Permite selecionar uma foto no computador/navegador.
  XFile? _fotoSelecionada;

  // Guarda os bytes da imagem para conseguir mostrar a foto no Chrome.
  Uint8List? _fotoBytes;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final usuario = context.read<UsuarioProvider>().usuario;

    _nomeController = TextEditingController(
      text: usuario.nome,
    );

    _telefoneController = TextEditingController(
      text: usuario.telefone,
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  // Abre a galeria de arquivos do computador.
  Future<void> _selecionarFoto() async {
    final imagem = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    // Se o usuário cancelar a seleção, não faz nada.
    if (imagem == null) {
      return;
    }

    // Lê a imagem como bytes.
    final bytes = await imagem.readAsBytes();

    setState(() {
      _fotoSelecionada = imagem;
      _fotoBytes = bytes;
    });
  }

  // Salva as alterações do usuário.
  void _salvar() {
    final provider = context.read<UsuarioProvider>();

    provider.atualizarUsuario(
      nome: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim(),

      // Se uma nova foto foi escolhida, envia o caminho dela.
      // Caso contrário, mantém a foto que já estava salva.
      foto: _fotoSelecionada?.path ?? provider.usuario.foto,
    );

    // Volta para a tela de perfil.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // foto perfil do usuario
            CircleAvatar(
              radius: 55,
              backgroundColor: Cores.principal.withValues(alpha: 0.15),

              // Se uma foto foi escolhida, mostra a foto.
              backgroundImage: _fotoBytes != null
                  ? MemoryImage(_fotoBytes!)
                  : null,

              // Se não existe foto, mostra o ícone de pessoa.
              child: _fotoBytes == null
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: Cores.principal,
                    )
                  : null,
            ),

            const SizedBox(height: 12),

            // Botão para escolher uma foto.
            TextButton.icon(
              onPressed: _selecionarFoto,
              icon: const Icon(
                Icons.camera_alt_outlined,
              ),
              label: const Text(
                'Alterar foto',
              ),
            ),

            const SizedBox(height: 25),

            //nome do usuario
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(
                  Icons.person_outline,
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // telefone
            TextField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                // a mesma máscara do resto do app: (37) 99999-0000
                MascaraDeTelefone(),
              ],
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 40),

            // botao de salvar alterações
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvar,
                child: const Text(
                  'Salvar alterações',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}