import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gamer_rage/src/data/models/game_model.dart';

class GameApiService {
  static const String _apiKey = '4d5d3cb275e643cc889aecc464f07a00';
  static const String _baseUrl = 'https://api.rawg.io/api';

  Future<List<GameModel>> searchGames(String query) async {
    final url = Uri.parse('$_baseUrl/games?key=$_apiKey&search=$query&page_size=40');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['results'] as List)
            .map((json) => _mapRawgToGameModel(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar jogos: $e');
      return [];
    }
  }

  Future<List<GameModel>> getPopularGames() async {
    final url = Uri.parse('$_baseUrl/games?key=$_apiKey&ordering=-rating&page_size=20');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['results'] as List)
            .map((json) => _mapRawgToGameModel(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar jogos populares: $e');
      return [];
    }
  }

  Future<GameModel?> getGameByAppId(String appId) async {
    final id = int.tryParse(appId);
    if (id == null) {
      debugPrint('❌ ID inválido: $appId');
      return null;
    }
    final url = Uri.parse('$_baseUrl/games/$id?key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _mapRawgToGameModel(data);
      } else {
        debugPrint('Erro ao buscar jogo por ID $appId: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro em getGameByAppId: $e');
    }
    return null;
  }

  GameModel _mapRawgToGameModel(Map<String, dynamic> json) {
    return GameModel(
      appId: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? 'Sem título',
      headerImage: json['background_image'] ??
          'https://placehold.co/400x200/000000/FFFFFF?text=Sem+Imagem',
      description: json['description_raw'] ?? '',
      developer: (json['developers'] is List)
          ? (json['developers'] as List)
              .map((d) => d['name'])
              .whereType<String>()
              .join(', ')
          : '',
      publisher: (json['publishers'] is List)
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
