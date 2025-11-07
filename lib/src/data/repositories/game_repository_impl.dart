import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gamer_rage/src/data/models/game_model.dart';
import 'package:gamer_rage/src/data/services/game_api_service.dart';

import 'package:gamer_rage/src/domain/repositories/game_repository.dart';
import 'package:flutter/foundation.dart';

class GameRepositoryImpl implements GameRepository {
  final FirebaseFirestore firestore;
  final SteamApiService apiService;

  // Nome da coleção para armazenar o cache de jogos.
  static const String _gamesCollection = 'cached_games';

  GameRepositoryImpl(this.firestore, this.apiService);

  @override
  Future<Either<String, int>> initializeGameCache() async {
    try {
      final collectionRef = firestore.collection(_gamesCollection);

      // 🔹 1. Verifica se o cache já existe (para evitar regravar tudo)
      final existingSnapshot = await collectionRef.limit(1).get();
      if (existingSnapshot.docs.isNotEmpty) {
        debugPrint('✅ Cache de jogos já existente. Pulando inicialização.');
        return const Right(0);
      }

      // 🔹 2. Busca lista completa da Steam API
      debugPrint('🌐 Iniciando busca de jogos na Steam API...');
      final List<GameModel> steamGames = await apiService.fetchAppList();

      if (steamGames.isEmpty) {
        return const Left('Falha ao buscar a lista de jogos da Steam.');
      }

      // 🔹 3. Salva os jogos no Firestore em lotes (batch)
      int savedCount = 0;
      WriteBatch batch = firestore.batch();

      for (var game in steamGames) {
        final docRef = collectionRef.doc(game.appId.toString());
        batch.set(docRef, game.toMap());
        savedCount++;

        // ⚠️ Firestore permite no máximo 500 operações por batch
        if (savedCount % 499 == 0) {
          await batch.commit();
          batch = firestore.batch(); // cria novo lote
        }
      }

      await batch.commit();
      debugPrint('🎯 Cache inicial de $savedCount jogos criado com sucesso.');
      return Right(savedCount);

    } on FirebaseException catch (e) {
      return Left('Erro no Firebase: ${e.message}');
    } catch (e) {
      return Left('Erro desconhecido: ${e.toString()}');
    }
  }

  @override
  Future<List<GameModel>> searchGames(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase();

      // 🔎 Busca simples: Firestore não suporta buscas "contém",
      // então fazemos um prefix search (exemplo: "doom" → "doomz")
      final QuerySnapshot snapshot = await firestore
          .collection(_gamesCollection)
          .where('name', isGreaterThanOrEqualTo: queryLower)
          .where('name', isLessThan: '$queryLowerz')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => GameModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      debugPrint('Erro Firebase na busca: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Erro desconhecido na busca: ${e.toString()}');
      return [];
    }
  }
}
    /// Limpa os resultados da busca (Ex: quando o usuário fecha a barra).
    void clearSearchResults() {
        _searchResults = [];
        notifyListeners();
    }