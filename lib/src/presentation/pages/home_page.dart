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
              child: CircularProgressIndicator(color: Colors.deepPurple))
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
                        '🎮 Últimas Avaliações de Amigos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 160,
                      child: Center(
                        child: Text(
                          "🕹️ Em breve: avaliações recentes dos seus amigos",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
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
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GameDetailsPage(game: game)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                  ),
                  child:
                      const Text("Detalhes", style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
