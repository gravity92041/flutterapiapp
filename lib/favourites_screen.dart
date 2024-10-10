import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'game_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Center(child: Text('You need to be logged in to see favorites.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No favorites yet.'));
          }

          final favoriteGames = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favoriteGames.length,
            itemBuilder: (context, index) {
              final game = favoriteGames[index].data() as Map<String, dynamic>;
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
                onTap: () {
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
