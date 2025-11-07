import 'package:flutter/material.dart';
import 'package:gamer_rage/src/data/models/game_model.dart';
import 'package:gamer_rage/src/data/services/game_api_service.dart';
import 'package:gamer_rage/src/presentation/pages/game_details_page.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final GameApiService _gameApi = GameApiService();
  List<GameModel> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    final results = await _gameApi.searchGames(widget.query);
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Resultados: ${widget.query}"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : _results.isEmpty
              ? const Center(
                  child: Text(
                    "Nenhum jogo encontrado.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final game = _results[index];
                    return ListTile(
                      leading: Image.network(
                        game.headerImage,
                        width: 70,
                        height: 40,
                        fit: BoxFit.cover,
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
