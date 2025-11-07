import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamer_rage/src/data/models/rating_model.dart';
import 'package:gamer_rage/src/domain/repositories/rating_repository.dart';
import 'package:flutter/foundation.dart';

class RatingRepositoryImpl implements RatingRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  RatingRepositoryImpl(this.firestore, this.auth);

  static const String _ratingsCollection = 'ratings';

  // 🔒 Regra de Negócio: Moderação de Conteúdo (Simples)
  bool _containsOffensiveWords(String comment) {
    const offensiveKeywords = ['ofensa1', 'ofensa2', 'palavrão']; // Exemplo
    final normalizedComment = comment.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    return offensiveKeywords.any((keyword) => normalizedComment.contains(keyword));
  }

  // -----------------------------------------------------------
  // 📝 Salvar ou atualizar avaliação de um jogo
  @override
  Future<Either<String, String>> saveRating({
    required String userId,
    required String username,
    required int appId,
    required String gameName,
    required int rating,
    required String comment,
  }) async {
    // 1️⃣ Validações locais
    if (comment.length > 800) {
      return const Left('O comentário excede o limite máximo de 800 caracteres.');
    }
    if (_containsOffensiveWords(comment)) {
      return const Left('O comentário contém palavras ofensivas e não pode ser publicado.');
    }

    try {
      // 2️⃣ Monta o modelo de avaliação
      final ratingModel = RatingModel(
        id: '', // será gerado pelo Firestore
        userId: userId,
        username: username,
        appId: appId,
        gameName: gameName,
        rating: rating,
        comment: comment,
        timestamp: DateTime.now(),
      );

      // 3️⃣ Define ID único por usuário + jogo
      final docId = '${userId}_$appId';
      final docRef = firestore.collection(_ratingsCollection).doc(docId);

      await docRef.set(ratingModel.toMap(), SetOptions(merge: true));

      debugPrint('✅ Avaliação salva com sucesso para $gameName ($appId)');
      return Right(docId);
    } on FirebaseException catch (e) {
      debugPrint('❌ Erro Firebase: ${e.message}');
      return Left('Erro no Firebase ao salvar avaliação: ${e.message}');
    } catch (e) {
      debugPrint('❌ Erro desconhecido: $e');
      return Left('Erro desconhecido ao salvar avaliação: ${e.toString()}');
    }
  }

  // -----------------------------------------------------------
  // 📄 Buscar as últimas avaliações do usuário logado
  @override
  Stream<List<RatingModel>> fetchUserLatestRatings({
    required String userId,
    int limit = 10,
  }) {
    return firestore
        .collection(_ratingsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RatingModel.fromFirestore(doc)).toList());
  }

  // -----------------------------------------------------------
  // 🤝 Buscar as últimas avaliações dos amigos
  @override
  Stream<List<RatingModel>> fetchFriendsLatestRatings({
    required List<String> friendUids,
    int limit = 10,
  }) {
    if (friendUids.isEmpty) return Stream.value([]);

    // ⚠️ O Firestore limita a cláusula `whereIn` a 10 valores.
    final chunkedUids = friendUids.take(10).toList();

    return firestore
        .collection(_ratingsCollection)
        .where('userId', whereIn: chunkedUids)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RatingModel.fromFirestore(doc)).toList());
  }

  // -----------------------------------------------------------
  // 🎮 Buscar todas as avaliações de um jogo específico
  @override
  Stream<List<RatingModel>> fetchGameRatings(int appId) {
    return firestore
        .collection(_ratingsCollection)
        .where('appId', isEqualTo: appId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RatingModel.fromFirestore(doc)).toList());
  }
}
