import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gamer_rage/src/data/models/game_model.dart';
import 'package:gamer_rage/src/data/services/game_api_service.dart';
import 'package:gamer_rage/src/presentation/pages/game_details_page.dart';
import 'package:gamer_rage/src/presentation/widgets/hover_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GameApiService _gameApi = GameApiService();
  List<GameModel> _popularGames = [];
  bool _isLoading = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchPopularGames();
  }

  Future<void> _fetchPopularGames() async {
    try {
      final loadedGames = await _gameApi.getPopularGames();
      setState(() {
        _popularGames = loadedGames;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar jogos populares: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Stream das avaliações dos amigos que o usuário segue
  Stream<List<Map<String, dynamic>>> _getFollowerReviews() async* {
    if (user == null) {
      yield [];
      return;
    }

    final followingSnap = await FirebaseFirestore.instance
        .collection('followers')
        .doc(user!.uid)
        .collection('following')
        .get();

    final followingIds = followingSnap.docs.map((d) => d.id).toList();

    if (followingIds.isEmpty) {
      yield [];
      return;
    }

    yield* FirebaseFirestore.instance
        .collectionGroup('comments')
        .where(
          'userId',
          whereIn: followingIds.length > 10
              ? followingIds.sublist(0, 10)
              : followingIds,
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => d.data() as Map<String, dynamic>).toList());
  }

  /// 🔹 Busca e valida o jogo de uma avaliação
  Future<GameModel?> _resolveGame(Map<String, dynamic> data) async {
    final possibleId = data['gameId']?.toString();
    final possibleName =
        data['gameName']?.toString() ?? data['title']?.toString();

    GameModel? found;

    // Busca por ID nos jogos já carregados
    if (possibleId != null && possibleId.isNotEmpty) {
      found = _popularGames
          .where((g) => g.appId.toString() == possibleId)
          .cast<GameModel?>()
          .firstWhere((g) => g != null, orElse: () => null);
    }

    // Busca por nome, se ID não achou
    if (found == null && possibleName != null && possibleName.isNotEmpty) {
      found = _popularGames.firstWhere(
        (g) => g.name.toLowerCase() == possibleName.toLowerCase(),
        orElse: () => GameModel(
          appId: 0,
          name: possibleName,
          headerImage:
              data['gameImage'] ?? 'https://placehold.co/400x200?text=Imagem',
          description: '',
          developer: '',
          publisher: '',
          price: 'N/A',
          initialPrice: 0.0,
        ),
      );
    }

    // Busca na API se não encontrou localmente
    if (found == null && possibleId != null) {
      found = await _gameApi.getGameByAppId(possibleId);
    }

    return found;
  }

  /// 🔹 Abre a página de detalhes do jogo a partir de uma avaliação
  Future<void> _openGameFromReview(Map<String, dynamic> data) async {
    final found = await _resolveGame(data);
    if (found != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameDetailsPage(game: found!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jogo não encontrado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Gamer Rage — Jogos Populares'),
        backgroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : RefreshIndicator(
              onRefresh: _fetchPopularGames,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        '🔥 Jogos Populares',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _popularGames.length,
                        itemBuilder: (context, index) {
                          final game = _popularGames[index];
                          return _buildGameCard(context, game);
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        '👥 Avaliações dos que você segue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _getFollowerReviews(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                  color: Colors.deepPurple),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Nenhuma avaliação dos usuários que você segue.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          );
                        }

                        final reviews = snapshot.data!;
                        return Column(
                          children: reviews.take(10).map((data) {
                            final String gameName =
                                (data['gameName'] ?? 'Jogo desconhecido')
                                    .toString();
                            final String? imageUrl = data['gameImage'];

                            return Card(
                              color: Colors.white10,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                leading: GestureDetector(
                                  onTap: () => _openGameFromReview(data),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl ??
                                          'https://placehold.co/100x60/000000/FFFFFF?text=Sem+Imagem',
                                      width: 80,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                title: InkWell(
                                  onTap: () => _openGameFromReview(data),
                                  child: Text(
                                    gameName,
                                    style: const TextStyle(
                                      color: Colors.lightBlueAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Avaliação de ${data['userName'] ?? 'Usuário'}:',
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: List.generate(
                                        10,
                                        (i) => Icon(
                                          Icons.star,
                                          size: 16,
                                          color: i <
                                                  ((data['rating'] ?? 0)
                                                      .toInt())
                                              ? Colors.amber
                                              : Colors.white24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['comment'] ?? '',
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGameCard(BuildContext context, GameModel game) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailsPage(game: game)),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HoverImage(
              imageUrl: game.headerImage,
              width: 180,
              height: 120,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GameDetailsPage(game: game)),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                game.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                game.price ?? "N/A",
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
