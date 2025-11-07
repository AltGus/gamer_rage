// data/repositories/game_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gamer_rage/src/data/models/game_model.dart';
import 'package:gamer_rage/src/data/services/game_api_service.dart';

import 'package:gamer_rage/src/domain/repositories/game_repository.dart';
import 'package:flutter/foundation.dart';

/// 🎮 Implementação do repositório de jogos.
/// Gerencia o cache no Firestore e a busca local de jogos por nome.
class GameRepositoryImpl implements GameRepository {
  final FirebaseFirestore firestore;
  final SteamApiService apiService;

  static const String _gamesCollection = 'cached_games';

  GameRepositoryImpl(this.firestore, this.apiService);

  // ---------------------------------------------------------------------------
  // 🧩 Inicializa o cache local de jogos da Steam no Firestore.
  // ---------------------------------------------------------------------------
  @override
  Future<Either<String, int>> initializeGameCache() async {
    try {
      final collectionRef = firestore.collection(_gamesCollection);

      // 1️⃣ Verifica se já existe cache.
      final existing = await collectionRef.limit(1).get();
      if (existing.docs.isNotEmpty) {
        debugPrint('✅ Cache de jogos já inicializado. Pulando API da Steam.');
        return const Right(0);
      }

      // 2️⃣ Busca lista de jogos na Steam API.
      debugPrint('🌐 Buscando lista de jogos da Steam...');
      final List<GameModel> steamGames = await apiService.fetchAppList();

      if (steamGames.isEmpty) {
        return const Left('Falha ao buscar lista de jogos da Steam.');
      }

      // 3️⃣ Salva os jogos no Firestore em lotes (WriteBatch).
      int savedCount = 0;
      WriteBatch batch = firestore.batch();

      for (var game in steamGames) {
        final docRef = collectionRef.doc(game.appId.toString());
        batch.set(docRef, game.toMap());
        savedCount++;

        // ⚠️ Firestore limita batches a 500 operações.
        if (savedCount % 499 == 0) {
          await batch.commit();
          batch = firestore.batch(); // Cria novo batch
        }
      }

      await batch.commit();
      debugPrint('🎯 Cache inicial de $savedCount jogos criado com sucesso.');
      return Right(savedCount);
    } on FirebaseException catch (e) {
      return Left('Erro no Firebase: ${e.message}');
    } catch (e) {
      return Left('Erro desconhecido: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 🔍 Busca local por jogos no Firestore usando prefixo do nome.
  // ---------------------------------------------------------------------------
  @override
  Future<List<GameModel>> searchGames(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase();

      final QuerySnapshot snapshot = await firestore
          .collection(_gamesCollection)
          .orderBy('name') // 🔹 Importante para suportar consultas range
          .startAt([queryLower])
          .endAt(['$queryLower\uf8ff']) // 🔹 Busca com prefixo (similar a startsWith)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => GameModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      debugPrint('Erro ao buscar jogos: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Erro desconhecido: $e');
      return [];
    }
  }
}
