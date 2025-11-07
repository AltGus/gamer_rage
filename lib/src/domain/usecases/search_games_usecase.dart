import 'package:gamer_rage/src/data/models/game_model.dart';
import 'package:gamer_rage/src/domain/repositories/game_repository.dart';

class SearchGamesUseCase {
  final GameRepository repository;

  SearchGamesUseCase(this.repository);

  /// Executa a busca por jogos no cache.
  Future<List<GameModel>> execute(String query) async {
    // 1. Regra de Negócio: Garante que a query não é apenas espaços em branco
    final sanitizedQuery = query.trim();
    if (sanitizedQuery.isEmpty) {
      return [];
    }
    
    // 2. Chama o Repositório para buscar os dados
    return repository.searchGames(sanitizedQuery);
  }
}