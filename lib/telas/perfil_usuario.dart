import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/usuario_provider.dart';
import '../tema/cores.dart';
import 'editar_perfil.dart';

class PerfilUsuario extends StatelessWidget {
  const PerfilUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    // Fica observando o UsuarioProvider.
    // Quando o usuário for alterado, esta tela será reconstruída.
    final usuario = context.watch<UsuarioProvider>().usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 55,
              backgroundColor: Cores.principal.withValues(alpha: 0.15),
              backgroundImage: usuario.foto != null && usuario.foto!.isNotEmpty
                  ? (kIsWeb
                        ? NetworkImage(usuario.foto!)
                        : FileImage(File(usuario.foto!)) as ImageProvider)
                  : null,
              child: usuario.foto == null || usuario.foto!.isEmpty
                  ? const Icon(Icons.person, size: 60, color: Cores.principal)
                  : null,
            ),

            const SizedBox(height: 25),

            //nome do usuario
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nome',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              key: ValueKey(usuario.nome),
              initialValue: usuario.nome,
              readOnly: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // telefone do usuario
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Telefone',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              key: ValueKey(usuario.telefone),
              initialValue: usuario.telefone,
              readOnly: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            //botao de editar perfil
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditarPerfil(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar perfil'),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
