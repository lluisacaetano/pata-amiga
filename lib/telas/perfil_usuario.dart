import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../tema/cores.dart';
import '../provider/usuario_provider.dart';

class PerfilUsuario extends StatelessWidget {
  const PerfilUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = context.watch<UsuarioProvider>();
    final usuario = usuarioProvider.usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
              child: const Icon(
                Icons.person,
                size: 60,
              ),
            ),

            const SizedBox(height: 12),

            TextButton.icon(
              onPressed: () {
             
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Alterar foto'),
            ),

            const SizedBox(height: 25),

            
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nome',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              initialValue: usuario.nome,
              readOnly: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Telefone',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              initialValue: usuario.telefone,
              readOnly: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                 
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