import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/usuario_provider.dart';
import '../tema/cores.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditarPerfil extends StatefulWidget {
  const EditarPerfil({super.key});

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  // mascara para o campo de telefone, permitindo apenas números e formatando como (##) #####-####
  final _mascaraTelefone = MaskTextInputFormatter(
  mask: '(##) #####-####',
  filter: {
    '#': RegExp(r'[0-9]'),
  },
);

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

  void _salvar() {
    final provider = context.read<UsuarioProvider>();

    provider.atualizarUsuario(
      nome: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim(),
      foto: provider.usuario.foto,
    );

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

            CircleAvatar(
              radius: 55,
              backgroundColor: Cores.principal.withValues(alpha: 0.15),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Cores.principal,
              ),
            ),

            const SizedBox(height: 12),

            TextButton.icon(
              onPressed: () {
                // A foto será implementada na próxima etapa.
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Alterar foto'),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
// aqui esta a mascara para o campo de telefone, permitindo apenas números e formatando como (##) #####-####
            TextField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [_mascaraTelefone],
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvar,
                child: const Text('Salvar alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}