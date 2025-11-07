import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:gamer_rage/data/models/game_model.dart';
import 'package:gamer_rage/src/domain/usecases/search_games_usecase.dart';
import 'package:gamer_rage/src/domain/repositories/game_repository.dart';

enum GameCacheStatus { initial, loading, success, error }

class GameViewModel extends ChangeNotifier {
  final SearchGamesUseCase _searchGamesUseCase;
  final GameRepository _gameRepository;

  GameViewModel(this._searchGamesUseCase, this._gameRepository);

  // --- Estado do Cache Inicial ---
  GameCacheStatus _cacheStatus = GameCacheStatus.initial;
  GameCacheStatus get cacheStatus => _cacheStatus;
  
  String _cacheMessage = '';
  String get cacheMessage => _cacheMessage;

  // --- Estado da Busca Universal ---
  List<GameModel> _searchResults = [];
  List<GameModel> get searchResults => _searchResults;
  
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  // ------------------------------------------
  // 1. Inicialização do Cache de Jogos
  // ------------------------------------------

  /// Tenta inicializar o cache de jogos no Firestore.
  Future<void> initializeCache() async {
    if (_cacheStatus == GameCacheStatus.success) return; // Não inicializar se já estiver pronto

    _cacheStatus = GameCacheStatus.loading;
    _cacheMessage = 'Verificando e inicializando cache de jogos da Steam...';
    notifyListeners();

    final result = await _gameRepository.initializeGameCache();

    result.fold(
      (error) {
        _cacheStatus = GameCacheStatus.error;
        _cacheMessage = '❌ ERRO ao carregar cache: $error';
      },
      (count) {
        _cacheStatus = GameCacheStatus.success;
        if (count > 0) {
          _cacheMessage = '✅ Cache inicial de $count jogos criado com sucesso!';
        } else {
          _cacheMessage = '✅ Cache de jogos já estava pronto.';
        }
      },
    );
    notifyListeners();
  }

  // ------------------------------------------
  // 2. Lógica da Barra de Pesquisa Universal
  // ------------------------------------------

  /// Realiza a busca de jogos no cache do Firestore.
  /// (Usado para busca efetiva - quando o usuário pressiona Enter ou Lupa)
  Future<void> executeSearch(String query) async {
    _isSearching = true;
    _searchResults = [];
    notifyListeners();

    final results = await _searchGamesUseCase.execute(query);

    _searchResults = results;
    _isSearching = false;
    notifyListeners();
  }

  /// Limpa os resultados da busca (Ex: quando o usuário fecha a barra).
  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }
}