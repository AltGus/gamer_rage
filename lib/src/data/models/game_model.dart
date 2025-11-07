import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo principal de jogo utilizado em toda a aplicação.
/// Pode ser construído a partir da API da Steam, da RAWG ou do Firestore local.
class GameModel {
  final int appId;
  final String name;
  final String headerImage; // URL da imagem de capa
  final double initialPrice; // Preço base (usado para exibição e cache)
  final String developer;
  final String publisher;
  final String? description;
  final String? price; // Preço formatado ou "Free"

  GameModel({
    required this.appId,
    required this.name,
    required this.headerImage,
    this.initialPrice = 0.0,
    this.developer = '',
    this.publisher = '',
    this.description,
    this.price,
  });

  /// 🔹 Construtor da API Steam (lista básica)
  factory GameModel.fromSteamAppListJson(Map<String, dynamic> json) {
    return GameModel(
      appId: json['appid'] as int,
      name: json['name'] as String,
      headerImage:
          'https://placehold.co/400x150/1B2838/FFFFFF?text=${json['name']}',
    );
  }

  /// 🔹 Construtor da API Steam (detalhes completos)
  factory GameModel.fromSteamDetailsJson(Map<String, dynamic> json) {
    return GameModel(
      appId: json['steam_appid'] ?? 0,
      name: json['name'] ?? 'Sem nome',
      headerImage: json['header_image'] ??
          'https://placehold.co/400x150/1B2838/FFFFFF?text=No+Image',
      description: json['short_description'],
      developer: (json['developers'] != null && json['developers'] is List)
          ? (json['developers'] as List).join(', ')
          : (json['developer'] ?? ''),
      publisher: (json['publishers'] != null && json['publishers'] is List)
          ? (json['publishers'] as List).join(', ')
          : (json['publisher'] ?? ''),
      price: json['is_free'] == true
          ? 'Free'
          : (json['price_overview'] != null
              ? json['price_overview']['final_formatted']
              : null),
      initialPrice: json['is_free'] == true
          ? 0.0
          : (json['price_overview'] != null
              ? (json['price_overview']['final'] / 100).toDouble()
              : 0.0),
    );
  }

  /// 🔹 Construtor da API RAWG.io (usado para busca e navegação)
  factory GameModel.fromRawgJson(Map<String, dynamic> json) {
    return GameModel(
      appId: json['id'] ?? 0,
      name: json['name'] ?? 'Sem título',
      headerImage: json['background_image'] ??
          'https://placehold.co/400x150/1B2838/FFFFFF?text=No+Image',
      description: json['slug'],
      developer: json['developers'] != null
          ? (json['developers'] as List)
              .map((d) => d['name'])
              .join(', ')
          : '',
      publisher: json['publishers'] != null
          ? (json['publishers'] as List)
              .map((p) => p['name'])
              .join(', ')
          : '',
      price: "Desconhecido", // RAWG não traz preços
      initialPrice: 0.0,
    );
  }

  /// 🔹 Construtor Firestore
  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameModel(
      appId: data['appId'] as int,
      name: data['name'] as String,
      headerImage: data['headerImage'] as String,
      initialPrice: (data['initialPrice'] as num?)?.toDouble() ?? 0.0,
      developer: data['developer'] as String? ?? '',
      publisher: data['publisher'] as String? ?? '',
      description: data['description'] as String?,
      price: data['price'] as String?,
    );
  }

  /// 🔹 Converter para mapa (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'appId': appId,
      'name': name,
      'headerImage': headerImage,
      'initialPrice': initialPrice,
      'developer': developer,
      'publisher': publisher,
      'description': description,
      'price': price,
      'cachedAt': FieldValue.serverTimestamp(),
    };
  }
}
