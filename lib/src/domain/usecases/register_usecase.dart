import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamer_rage/src/domain/repositories/auth_repository.dart';

/// Tipos de erro possíveis no registro
enum RegisterFailure {
  invalidEmail,
  weakPassword,
  emailAlreadyInUse,
  usernameNotUnique,
  unknownError,
}

/// Caso de uso: Registrar novo usuário
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  /// 🔹 Regra de negócio — senha deve ter pelo menos 8 caracteres e 1 especial
  bool _isPasswordValid(String password) {
    if (password.length < 8) return false;
    final specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    return specialCharRegex.hasMatch(password);
  }

  /// 🔹 Execução do caso de uso: registro + validações
  Future<Either<RegisterFailure, UserCredential>> execute({
    required String email,
    required String password,
    required String username,
  }) async {
    // 1️⃣ Validação local da senha
    if (!_isPasswordValid(password)) {
      return const Left(RegisterFailure.weakPassword);
    }

    try {
      // 2️⃣ Verificar se o nome de usuário é único (consultando o Firestore)
      final isUnique = await repository.isUsernameUnique(username);
      if (!isUnique) {
        return const Left(RegisterFailure.usernameNotUnique);
      }

      // 3️⃣ Registrar o usuário no Firebase Auth
      final result = await repository.register(
        email: email,
        password: password,
        username: username,
      );

      return Right(result);
    } on FirebaseAuthException catch (e) {
      // 4️⃣ Tratar erros específicos do Firebase
      switch (e.code) {
        case 'weak-password':
          return const Left(RegisterFailure.weakPassword);
        case 'email-already-in-use':
          return const Left(RegisterFailure.emailAlreadyInUse);
        case 'invalid-email':
          return const Left(RegisterFailure.invalidEmail);
        default:
          return const Left(RegisterFailure.unknownError);
      }
    } catch (_) {
      return const Left(RegisterFailure.unknownError);
    }
  }
}
