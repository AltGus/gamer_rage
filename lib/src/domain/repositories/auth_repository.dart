import 'package:firebase_auth/firebase_auth.dart';

/// 🔒 Contrato de autenticação da aplicação.
/// 
/// Essa interface define as operações de autenticação e controle
/// de usuários, separando a lógica do Firebase das regras de negócio.
/// Permite fácil substituição por outro provedor de Auth no futuro.
abstract class AuthRepository {
  /// Registra um novo usuário no Firebase Auth e salva dados adicionais (como username) no Firestore.
  Future<UserCredential> register({
    required String email,
    required String password,
    required String username,
  });

  /// Realiza o login com email e senha.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  });

  /// Realiza o logout do usuário atual.
  Future<void> signOut();

  /// Verifica se um nome de usuário já existe no banco (para garantir unicidade).
  Future<bool> isUsernameUnique(String username);

  /// Retorna o fluxo contínuo do estado de autenticação (ex: logado/deslogado).
  Stream<User?> get authStateChanges;
}
