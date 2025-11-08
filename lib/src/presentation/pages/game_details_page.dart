import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamer_rage/src/data/models/game_model.dart';

class GameDetailsPage extends StatefulWidget {
  final GameModel game;
  const GameDetailsPage({super.key, required this.game});

  @override
  State<GameDetailsPage> createState() => _GameDetailsPageState();
}

class _GameDetailsPageState extends State<GameDetailsPage> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  String? _reviewId;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserReview();
  }

  Future<void> _loadUserReview() async {
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.game.appId.toString())
        .collection('comments')
        .where('userId', isEqualTo: user!.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data();
      setState(() {
        _reviewId = doc.id;
        _rating = (data['rating'] ?? 0).toDouble();
        _commentController.text = data['comment'] ?? '';
      });
    }
  }

  Future<void> _submitReview() async {
    if (user == null) return;
    final comment = _commentController.text.trim();

    if (_rating == 0 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê uma nota e escreva um comentário.')),
      );
      return;
    }

    // ✅ Corrigido: Mapa de dados da avaliação sem duplicatas
    final reviewData = {
      'userId': user!.uid,
      'userEmail': user!.email,
      'userName': user!.displayName ?? 'Usuário',
      'gameId': widget.game.appId.toString(),
      'gameName': widget.game.name.isNotEmpty ? widget.game.name : 'Sem título',
      'gameImage': widget.game.headerImage.isNotEmpty
          ? widget.game.headerImage
          : 'https://placehold.co/400x200/000000/FFFFFF?text=Sem+Imagem',
      'rating': _rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final ref = FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.game.appId.toString())
        .collection('comments');

    if (_reviewId != null) {
      await ref.doc(_reviewId).update(reviewData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação atualizada!')),
      );
    } else {
      final newDoc = await ref.add(reviewData);
      setState(() => _reviewId = newDoc.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação enviada!')),
      );
    }
  }

  Future<void> _toggleFollow(String targetUserId) async {
    if (user == null || user!.uid == targetUserId) return;

    final followRef = FirebaseFirestore.instance
        .collection('followers')
        .doc(user!.uid)
        .collection('following')
        .doc(targetUserId);

    final doc = await followRef.get();
    if (doc.exists) {
      await followRef.delete();
    } else {
      await followRef.set({'since': FieldValue.serverTimestamp()});
    }
  }

  Stream<bool> _isFollowing(String targetUserId) {
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('followers')
        .doc(user!.uid)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                game.headerImage,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              game.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              game.description?.isNotEmpty == true
                  ? game.description!
                  : 'Sem descrição disponível.',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Text('Sua Avaliação:',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              children: List.generate(10, (index) {
                final starIndex = index + 1;
                return IconButton(
                  onPressed: () =>
                      setState(() => _rating = starIndex.toDouble()),
                  icon: Icon(
                    Icons.star,
                    color: _rating >= starIndex ? Colors.amber : Colors.white24,
                    size: 28,
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
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
            Center(
              child: ElevatedButton.icon(
                onPressed: _submitReview,
                icon: const Icon(Icons.send),
                label: Text(
                  _reviewId != null ? 'Atualizar Avaliação' : 'Enviar Avaliação',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(color: Colors.white24),
            const Text(
              'Avaliações dos jogadores:',
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
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  );
                }

                final reviews = snapshot.data!.docs;
                if (reviews.isEmpty) {
                  return const Text(
                    'Nenhuma avaliação ainda. Seja o primeiro!',
                    style: TextStyle(color: Colors.white54),
                  );
                }

                return Column(
                  children: reviews.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final targetUserId = data['userId'] ?? '';
                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              data['userName'] ?? 'Usuário',
                              style: const TextStyle(color: Colors.white),
                            ),
                            if (user != null && user!.uid != targetUserId)
                              StreamBuilder<bool>(
                                stream: _isFollowing(targetUserId),
                                builder: (context, snapshot) {
                                  final isFollowing = snapshot.data ?? false;
                                  return TextButton(
                                    onPressed: () =>
                                        _toggleFollow(targetUserId),
                                    child: Text(
                                      isFollowing ? 'Seguindo' : 'Seguir',
                                      style: TextStyle(
                                        color: isFollowing
                                            ? Colors.greenAccent
                                            : Colors.blueAccent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
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
