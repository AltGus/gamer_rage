import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gamer_rage/src/data/models/game_model.dart';

/// Serviço que consome a RAWG API para buscar jogos.
class GameApiService {
  static const String _apiKey = '4d5d3cb275e643cc889aecc464f07a00';
  static const String _baseUrl = 'https://api.rawg.io/api';

  /// 🔍 Busca jogos pelo nome
  Future<List<GameModel>> searchGames(String query) async {
    final url =
        Uri.parse('$_baseUrl/games?key=$_apiKey&search=$query&page_size=40');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'];

        return results.map((json) => _mapRawgToGameModel(json)).toList();
      } else {
        debugPrint('Erro ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Erro ao buscar jogos: $e');
      return [];
    }
  }

  /// 🎮 Jogos populares (para a Home)
  Future<List<GameModel>> getPopularGames() async {
    final url =
        Uri.parse('$_baseUrl/games?key=$_apiKey&ordering=-rating&page_size=20');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'];

        return results.map((json) => _mapRawgToGameModel(json)).toList();
      } else {
        debugPrint('Erro ao buscar jogos populares: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Erro: $e');
      return [];
    }
  }

  /// 🧾 Detalhes completos de um jogo
  Future<GameModel?> getGameDetails(int id) async {
    final url = Uri.parse('$_baseUrl/games/$id?key=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _mapRawgToGameModel(data);
      } else {
        debugPrint('Erro ao buscar detalhes: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erro: $e');
      return null;
    }
  }

  /// 🧩 Conversor de JSON para GameModel
  GameModel _mapRawgToGameModel(Map<String, dynamic> json) {
    return GameModel(
      appId: json['id'] ?? 0,
      name: json['name'] ?? 'Sem título',
      headerImage: json['background_image'] ??
          'https://placehold.co/400x200/000000/FFFFFF?text=Sem+Imagem',
      description: json['description_raw'] ?? '',
      developer: json['developers'] != null && json['developers'] is List
          ? (json['developers'] as List)
              .map((d) => d['name'])
              .whereType<String>()
              .join(', ')
          : '',
      publisher: json['publishers'] != null && json['publishers'] is List
          ? (json['publishers'] as List)
              .map((p) => p['name'])
              .whereType<String>()
              .join(', ')
          : '',
      price: 'N/A',
      initialPrice: 0.0,
    );
  }
}