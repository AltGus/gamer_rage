import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 IMPORTANTE
import 'package:gamer_rage/src/data/repositories/auth_repository_impl.dart';
import 'package:gamer_rage/src/domain/repositories/auth_repository.dart';
import 'package:gamer_rage/src/domain/usecases/register_usecase.dart';

// NOTE: Para fins de demonstração, instanciamos as dependências aqui.
// Em um projeto real, você usaria Injeção de Dependência (Provider/Riverpod).

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  final AuthRepository _repository = AuthRepositoryImpl(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );

  late final RegisterUseCase _registerUseCase;

  @override
  void initState() {
    super.initState();
    _registerUseCase = RegisterUseCase(_repository);
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'A senha é obrigatória.';
    }
    if (value.length < 8) {
      return 'A senha deve ter no mínimo 8 caracteres.';
    }
    final specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    if (!specialCharRegex.hasMatch(value)) {
      return 'A senha deve conter pelo menos um caractere especial.';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrando...')),
      );

      final result = await _registerUseCase.execute(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );

      result.fold(
        (failure) {
          String message;
          switch (failure) {
            case RegisterFailure.emailAlreadyInUse:
              message = 'Este e-mail já está em uso.';
              break;
            case RegisterFailure.usernameNotUnique:
              message = 'Nome de usuário já existe.';
              break;
            case RegisterFailure.weakPassword:
              message = 'Senha muito fraca ou inválida. Siga as regras.';
              break;
            default:
              message = 'Erro desconhecido ao registrar. Tente novamente.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $message')),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Registro concluído! Entrando...')),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Cadastro')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome de Usuário (Único)',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Campo obrigatório.' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email (Único)'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value == null || !value.contains('@') ? 'Email inválido.' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                      labelText: 'Senha (mín. 8 caracteres, 1 especial)'),
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text('Cadastrar', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Já tenho uma conta. Voltar para Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
