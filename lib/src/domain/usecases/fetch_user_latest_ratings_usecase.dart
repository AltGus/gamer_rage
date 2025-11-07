// domain/usecases/fetch_user_latest_ratings_usecase.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamer_rage/src/data/models/rating_model.dart';
import 'package:gamer_rage/src/domain/repositories/rating_repository.dart';

class FetchUserLatestRatingsUseCase {
  final RatingRepository repository;
  final FirebaseAuth auth;

  FetchUserLatestRatingsUseCase(this.repository, this.auth);

  /// Retorna um Stream das 10 últimas avaliações do usuário logado.
  Stream<List<RatingModel>> call() {
    final userId = auth.currentUser?.uid;
    
    if (userId == null) {
      // Retorna um Stream vazio se o usuário não estiver logado
      return Stream.value([]); 
    }
    
    // Chama o repositório para obter as avaliações
    return repository.fetchUserLatestRatings(userId: userId);
  }
}