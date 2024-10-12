import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'game_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  // Удаление игры из избранного
  Future<void> _removeFavorite(String gameId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(gameId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;


    return Scaffold(
      appBar: AppBar(
        title: Text('Избранное'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Нет избранных игр.'));
          }

          final favoriteGames = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favoriteGames.length,
            itemBuilder: (context, index) {
              final game = favoriteGames[index].data() as Map<String, dynamic>;
              final gameId = favoriteGames[index].id; // Получаем ID игры

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    game['thumb'],
                    width: 100,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(game['external']),
                subtitle: Text('Cheapest Price: \$${game['cheapest']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red), // Иконка удаления
                  onPressed: () {
                    // Подтверждение перед удалением
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Удалить из избранного'),
                        content: Text('Вы уверены что хотите удалить эту игру из избранного?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context), // Закрыть диалог
                            child: Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () {
                              _removeFavorite(gameId); // Удаляем игру
                              Navigator.pop(context); // Закрыть диалог
                            },
                            child: Text('Удалить'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                onTap: () {
                  // Переход на экран с подробностями об игре
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameDetailsScreen(gameId: game['gameID']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
