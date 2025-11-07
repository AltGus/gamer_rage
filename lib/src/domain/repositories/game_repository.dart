import 'package:dartz/dartz.dart';
import 'package:gamer_rage/src/data/models/game_model.dart';

/// 🔹 Contrato do repositório de jogos.
/// Define a interface para inicialização e busca de jogos
/// via cache local no Firestore ou integração com a Steam API.
abstract class GameRepository {
  /// Inicializa o cache local de jogos no Firestore.
  /// Retorna:
  /// - [Right(int)] → número de jogos salvos;
  /// - [Right(0)] → cache já existente;
  /// - [Left(String)] → mensagem de erro.
  Future<Either<String, int>> initializeGameCache();

  /// Busca jogos pelo nome, com base no cache local do Firestore.
  /// Retorna uma lista de [GameModel].
  Future<List<GameModel>> searchGames(String query);

  /// (Opcional Futuro) Busca detalhes completos de um jogo específico.
  /// Pode ser implementado com integração à Steam API diretamente.
  Future<GameModel?> fetchGameDetails(int appId) => 
      throw UnimplementedError('fetchGameDetails não implementado.');
}
