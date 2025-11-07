import 'package:flutter/material.dart';
import 'package:gamer_rage/src/data/models/game_model.dart';
import 'package:gamer_rage/src/data/services/game_api_service.dart';
import 'package:gamer_rage/src/presentation/pages/game_details_page.dart';
import 'package:gamer_rage/src/presentation/widgets/hover_image.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final GameApiService _gameApi = GameApiService();
  final TextEditingController _searchController = TextEditingController();
  List<GameModel> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
    _performSearch(widget.query);
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    final results = await _gameApi.searchGames(query);
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  void _onSearchSubmitted(String query) {
    FocusScope.of(context).unfocus(); // Fecha o teclado
    _performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar jogos...',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.deepPurple.shade400,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => _onSearchSubmitted(_searchController.text),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _onSearchSubmitted,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : _results.isEmpty
              ? const Center(
                  child: Text(
                    "Nenhum jogo encontrado.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final game = _results[index];
                    return ListTile(
                      leading: HoverImage(
                        imageUrl: game.headerImage,
                        width: 70,
                        height: 40,
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameDetailsPage(game: game),
                            ),
                          );
                        },
                      ),
                      title: Text(
                        game.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameDetailsPage(game: game),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
