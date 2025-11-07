import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamer_rage/src/presentation/pages/register_page.dart';
import 'package:gamer_rage/src/presentation/pages/app_shell.dart';
import 'package:gamer_rage/src/core/routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.appShell);
      }
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' || 'wrong-password' => 'Email ou senha inválidos.',
        _ => 'Erro ao fazer login: ${e.message}',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $message')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: ${e.toString()}')),
      );
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Gamer Rage')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Entrar'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _navigateToRegister,
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Ainda não tenho conta. Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}
