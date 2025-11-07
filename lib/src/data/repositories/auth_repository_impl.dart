import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamer_rage/src/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepositoryImpl(this.auth, this.firestore);

  /// 🔹 Stream que notifica quando o estado de autenticação muda (login/logout)
  @override
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// 🔹 Registrar novo usuário no Firebase Auth e salvar dados extras no Firestore
  @override
  Future<UserCredential> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-creation-failed',
        message: 'Falha ao criar o usuário.',
      );
    }

    // 🔸 1. Verifica se o nome de usuário é único antes de salvar
    final isUnique = await isUsernameUnique(username);
    if (!isUnique) {
      await user.delete(); // limpa o Auth caso tenha duplicação
      throw FirebaseAuthException(
        code: 'username-already-exists',
        message: 'O nome de usuário já está em uso.',
      );
    }

    // 🔸 2. Salva os dados do usuário no Firestore
    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email.trim(),
      'username': username.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'friends': [], // inicia lista de amizades vazia
    });

    // 🔸 3. Atualiza o displayName do usuário no Firebase Auth
    await user.updateDisplayName(username.trim());

    return userCredential;
  }

  /// 🔹 Login usando email e senha
  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// 🔹 Logout do usuário atual
  @override
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// 🔹 Verifica se o nome de usuário já existe na coleção "users"
  @override
  Future<bool> isUsernameUnique(String username) async {
    final result = await firestore
        .collection('users')
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();

    // se não há resultados, o nome é único
    return result.docs.isEmpty;
  }
}
