// Widget reutilizável para exibir um carrossel horizontal de avaliações.
import 'package:flutter/material.dart';
import 'package:gamer_rage/src/data/models/rating_model.dart';
import 'package:gamer_rage/src/presentation/widgets/rating_tile.dart';

class RatingCarousel extends StatelessWidget {
  final List<RatingModel> ratings;
  final bool showUserNames; // Usado no carrossel de amigos

  const RatingCarousel({
    super.key,
    required this.ratings,
    this.showUserNames = false,
  });

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Nenhuma avaliação encontrada.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200, // Altura padrão para o carrossel
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ratings.length,
        itemBuilder: (context, index) {
          final rating = ratings[index];
          return RatingTile(
            rating: rating,
            showUser: showUserNames,
          );
        },
      ),
    );
  }
}
