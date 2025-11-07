import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Imports das páginas
import 'package:gamer_rage/src/presentation/pages/login_page.dart';
import 'package:gamer_rage/src/presentation/pages/app_shell.dart';
import 'package:gamer_rage/src/core/routes/app_routes.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 Tenta conectar aos emuladores locais (opcional)
  try {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    debugPrint('✅ Conectado aos emuladores Firebase.');
  } catch (e) {
    debugPrint('⚠️ Rodando com Firebase real');
  }

  runApp(const GamerRageApp());
}

class GamerRageApp extends StatelessWidget {
  const GamerRageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamer Rage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      // 🔹 Usa o AuthGate como ponto inicial
      home: const AuthGate(),

      // 🔹 Rotas nomeadas globais
      routes: AppRoutes.defineRoutes(),
    );
  }
}

/// 🔐 Controla o fluxo de autenticação do usuário
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Carregando...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
          );
        }

        // ✅ Usuário logado → vai para AppShell (Home)
        if (snapshot.hasData) {
          return const AppShell();
        }

        // ❌ Usuário não logado → vai para LoginPage
        return const LoginPage();
      },
    );
  }
}
