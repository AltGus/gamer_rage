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

  Stream<List<Map<String, dynamic>>> _getFollowerReviews() async* {
    if (user == null) {
      yield [];
      return;
    }

    // 🔹 Busca IDs das pessoas que o usuário segue
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

    // 🔹 Escuta todas as avaliações (limite de 10 IDs por query)
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

  // Adiciona função para abrir página do jogo a partir dos dados da avaliação.
  void _openGameFromReview(Map<String, dynamic> data) {
    // Tenta identificar o jogo pela maior quantidade de possibilidades
    final dynamic possibleId = data['gameId'] ?? data['id'] ?? data['appId'];
    final String? possibleName =
        (data['gameName'] ?? data['gameTitle'] ?? data['title'])?.toString();

    GameModel? found;

    // Tenta encontrar pelo id entre os populares
    if (possibleId != null) {
      try {
        found = _popularGames.firstWhere((g) {
          // evita acessar getters que não existem no model
          final gid = (g.appId ?? '').toString();
          return gid.isNotEmpty && gid == possibleId.toString();
        });
      } catch (_) {
        // não encontrado por id
      }
    }

    // Se não achou por id, tenta por nome (case-insensitive)
    if (found == null && possibleName != null) {
      try {
        found = _popularGames.firstWhere((g) =>
            g.name.toLowerCase() == possibleName.toLowerCase());
      } catch (_) {
        // não encontrado por nome
      }
    }

    if (found != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameDetailsPage(game: found!)),
      );
    } else {
      // Se não estiver nos populares, informa e sugere abrir página de busca (extensível)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jogo não encontrado nos populares.')),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : RefreshIndicator(
              onRefresh: _fetchPopularGames,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(color: Colors.deepPurple),
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
                            // tenta extrair nome do jogo para mostrar e linkar
                            final String gameName = (data['gameName'] ?? data['gameTitle'] ?? data['title'] ?? 'Jogo desconhecido').toString();

                            return Card(
                              color: Colors.white10,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                // Mostra o nome do jogo como link clicável
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () => _openGameFromReview(data),
                                      child: Text(
                                        gameName,
                                        style: const TextStyle(
                                          color: Colors.lightBlueAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Avaliação de ${data['userName'] ?? 'Usuário'}:',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Row(
                                      children: List.generate(
                                        10,
                                        (i) => Icon(
                                          Icons.star,
                                          size: 16,
                                          color: i < ((data['rating'] ?? 0).toInt())
                                              ? Colors.amber
                                              : Colors.white24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['comment'] ?? '',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                                onTap: () => _openGameFromReview(data),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
