// domain/usecases/fetch_friends_latest_ratings_usecase.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamer_rage/src/data/models/rating_model.dart';
import 'package:gamer_rage/src/domain/repositories/friendship_repository.dart';
import 'package:gamer_rage/src/domain/repositories/rating_repository.dart';
import 'package:rxdart/rxdart.dart'; // Necessário para a função switchMap

class FetchFriendsLatestRatingsUseCase {
  final RatingRepository ratingRepository;
  final FriendshipRepository friendshipRepository;
  final FirebaseAuth auth;

  FetchFriendsLatestRatingsUseCase(this.ratingRepository, this.friendshipRepository, this.auth);

  /// Retorna um Stream das avaliações recentes dos amigos.
  /// O stream combina a lista de UIDs de amigos com a busca de avaliações.
  Stream<List<RatingModel>> call() {
    final userId = auth.currentUser?.uid;
    
    if (userId == null) {
      // Retorna um Stream vazio se o usuário não estiver logado
      return Stream.value([]); 
    }
    
    // 1. Obtém o stream dos UIDs dos amigos
    return friendshipRepository.getFriendUids(userId)
        .switchMap((friendUids) {
          // 2. Usa os UIDs para buscar o stream de avaliações
          return ratingRepository.fetchFriendsLatestRatings(friendUids: friendUids);
        });
  }
}