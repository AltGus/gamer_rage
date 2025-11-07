import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Avaliação (Review) feita por um usuário em um jogo.
class RatingModel {
  final String id;
  final String userId;
  final String username;
  final int appId;
  final String gameName;
  final int rating; // 0 a 10 estrelas
  final String comment; // Máximo 800 caracteres
  final Timestamp timestamp;

  RatingModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.appId,
    required this.gameName,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  /// 🔹 Cria um modelo a partir de um documento Firestore
  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw StateError("Documento de avaliação inválido: ${doc.id}");
    }

    return RatingModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? 'Usuário Desconhecido',
      appId: (data['appId'] is int)
          ? data['appId'] as int
          : int.tryParse(data['appId'].toString()) ?? 0,
      gameName: data['gameName'] as String? ?? 'Jogo Desconhecido',
      rating: (data['rating'] is int)
          ? data['rating'] as int
          : int.tryParse(data['rating'].toString()) ?? 0,
      comment: data['comment'] as String? ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp'] as Timestamp
          : Timestamp.now(),
    );
  }

  /// 🔹 Converte o modelo em mapa para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'appId': appId,
      'gameName': gameName,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp,
    };
  }

  /// 🔹 Converte o timestamp em uma data legível (ex: "07/11/2025")
  String get formattedDate {
    final date = timestamp.toDate();
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }
}
