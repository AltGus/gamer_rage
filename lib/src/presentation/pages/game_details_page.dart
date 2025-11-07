import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gamer_rage/src/data/models/game_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameDetailsPage extends StatefulWidget {
  final GameModel game;

  const GameDetailsPage({super.key, required this.game});

  @override
  State<GameDetailsPage> createState() => _GameDetailsPageState();
}

class _GameDetailsPageState extends State<GameDetailsPage> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final comment = _commentController.text.trim();
    if (_rating == 0 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê uma nota e escreva um comentário.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.game.appId.toString())
        .collection('comments')
        .add({
      'userId': user.uid,
      'userName': user.displayName ?? 'Usuário',
      'rating': _rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
    setState(() => _rating = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avaliação enviada!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          game.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Imagem de capa
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                game.headerImage,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            // 🎮 Nome
            Text(
              game.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // 💬 Descrição
            Text(
              game.description?.isNotEmpty == true
                  ? game.description!
                  : 'Sem descrição disponível.',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 20),

            // ⭐ Avaliação
            const Text(
              'Avalie este jogo:',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              children: List.generate(10, (index) {
                final starIndex = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = starIndex.toDouble()),
                  icon: Icon(
                    Icons.star,
                    color: _rating >= starIndex
                        ? Colors.amber
                        : Colors.white24,
                    size: 28,
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            // 📝 Campo de comentário
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Deixe seu comentário...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 🚀 Botão de enviar
            Center(
              child: ElevatedButton.icon(
                onPressed: _submitReview,
                icon: const Icon(Icons.send),
                label: const Text('Enviar Avaliação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 💬 Lista de avaliações
            const Divider(color: Colors.white24),
            const Text(
              'Avaliações de outros jogadores:',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .doc(widget.game.appId.toString())
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: Colors.deepPurple),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'Nenhuma avaliação ainda. Seja o primeiro!',
                    style: TextStyle(color: Colors.white54),
                  );
                }

                final reviews = snapshot.data!.docs;

                return Column(
                  children: reviews.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          data['userName'] ?? 'Usuário',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(
                                10,
                                (i) => Icon(
                                  Icons.star,
                                  size: 16,
                                  color: i < (data['rating'] ?? 0)
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
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
