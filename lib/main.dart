import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutterapiapp/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // Для работы с Firestore
import 'game_details_screen.dart'; // Экран с деталями игры
import 'favourites_screen.dart'; // Экран с избранным

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(GameSearchApp());
}

class GameSearchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasData) {
            return GameSearchScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}

class GameSearchScreen extends StatefulWidget {
  @override
  _GameSearchScreenState createState() => _GameSearchScreenState();
}

class _GameSearchScreenState extends State<GameSearchScreen> {
  List<dynamic> _games = [];
  String _query = '';

  // Получаем текущего пользователя
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Поиск игр
  Future<void> _searchGames(String query) async {
    final url = Uri.parse('https://www.cheapshark.com/api/1.0/games?title=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> games = json.decode(response.body);
      setState(() {
        _games = games;
      });
    } else {
      throw Exception('Failed to load games');
    }
  }

  // Добавление/удаление игры в избранное
  Future<void> _toggleFavorite(String gameId, Map<String, dynamic> gameData) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    final favoriteDoc = FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').doc(gameId);

    final docSnapshot = await favoriteDoc.get();

    if (docSnapshot.exists) {
      // Если игра уже в избранном, удаляем
      await favoriteDoc.delete();
    } else {
      // Если игры нет в избранном, добавляем
      await favoriteDoc.set(gameData);
    }

    setState(() {}); // Обновляем состояние для перерисовки списка
  }

  // Проверяем, находится ли игра в избранном
  Future<bool> _isFavorite(String gameId) async {
    final userId = currentUser?.uid;
    if (userId == null) return false;

    final favoriteDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(gameId)
        .get();

    return favoriteDoc.exists;
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Search'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite), // Иконка избранного
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavoritesScreen()), // Переход в избранное
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout), // Иконка выхода
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search for a game',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                _searchGames(value);
              },
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _games.length,
                itemBuilder: (context, index) {
                  final game = _games[index];
                  final gameId = game['gameID'];

                  return FutureBuilder<bool>(
                    future: _isFavorite(gameId),
                    builder: (context, snapshot) {
                      final isFavorite = snapshot.data ?? false;
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
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border, // Звездочка
                            color: isFavorite ? Colors.yellow : Colors.grey,
                          ),
                          onPressed: () {
                            _toggleFavorite(gameId, game); // Добавление/удаление из избранного
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameDetailsScreen(gameId: gameId),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
