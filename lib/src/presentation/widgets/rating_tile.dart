import 'package:dartz/dartz.dart';
import 'package:gamer_rage/data/models/rating_model.dart';

abstract class RatingRepository {
  /// Contrato para salvar ou atualizar uma avaliação e comentário de um usuário para um jogo.
  /// Retorna um erro (String) ou o ID da nova avaliação (String).
  Future<Either<String, String>> saveRating({
    required String userId,
    required String username,
    required int appId,
    required String gameName,
    required int rating,
    required String comment,
  });

  /// Contrato para buscar as últimas N avaliações feitas por um usuário.
  /// Necessário para o Carrossel 1 (Suas 10 Últimas Avaliações).
  Stream<List<RatingModel>> fetchUserLatestRatings({
    required String userId,
    int limit = 10,
  });

  /// Contrato para buscar as últimas N avaliações feitas pelos amigos de um usuário.
  /// Necessário para o Carrossel 2 (Avaliações de Amigos).
  Stream<List<RatingModel>> fetchFriendsLatestRatings({
    required List<String> friendUids,
    int limit = 10,
  });

  /// Contrato para buscar todas as avaliações de um jogo específico.
  /// Necessário para a página de detalhes do jogo.
  Stream<List<RatingModel>> fetchGameRatings(int appId);
}