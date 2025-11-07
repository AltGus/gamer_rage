import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // O usuário logado
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? 'Usuário Desconhecido';
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔔 Central de Notificações',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text('Bem-vindo, $username!', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 30),
            const Text(
              'Solicitações de Amizade Pendentes:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Expanded(
              // TODO: Implementar um StreamBuilder para ouvir solicitações de amizade do Firestore.
              child: Center(
                child: Text('Nenhuma solicitação pendente no momento.', style: TextStyle(color: Colors.white70)),
              ),
            ),
            // Aqui você listaria e gerenciaria as solicitações:
            // ListTile(
            //   title: Text('Fulano de Tal'),
            //   trailing: Row(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       IconButton(icon: Icon(Icons.check), onPressed: () => {}), // Aceitar
            //       IconButton(icon: Icon(Icons.close), onPressed: () => {}), // Recusar
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}