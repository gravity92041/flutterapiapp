import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutterapiapp/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_details_screen.dart';
import 'favourites_screen.dart';
import 'cart_screen.dart';
import 'library_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(GameSearchApp());
}

class GameSearchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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


  User? get currentUser => FirebaseAuth.instance.currentUser;


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


  Future<bool> _isInLibrary(String gameId) async {
    final userId = currentUser?.uid;
    if (userId == null) return false;

    final libraryDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('library')
        .doc(gameId)
        .get();

    return libraryDoc.exists;
  }


  Future<bool> _isInCart(String gameId) async {
    final userId = currentUser?.uid;
    if (userId == null) return false;

    final cartDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(gameId)
        .get();

    return cartDoc.exists;
  }

  Future<void> _toggleCart(String gameId, Map<String, dynamic> gameData) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    final cartDoc = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart').doc(gameId);

    final docSnapshot = await cartDoc.get();

    if (docSnapshot.exists) {

      await cartDoc.delete();
    } else {

      await cartDoc.set(gameData);
    }

    setState(() {});
  }


  Future<void> _toggleFavorite(String gameId, Map<String, dynamic> gameData) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    final favoriteDoc = FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').doc(gameId);

    final docSnapshot = await favoriteDoc.get();

    if (docSnapshot.exists) {

      await favoriteDoc.delete();
    } else {

      await favoriteDoc.set(gameData);
    }

    setState(() {});
  }


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
        title: Text('Поиск игр'),
        actions: [
          IconButton(
            icon: Icon(Icons.library_books),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LibraryScreen()), // Переход в библиотеку
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(
                    onBuy: () async {
                      final userId = currentUser?.uid;
                      if (userId == null) return;

                      final cartItems = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('cart')
                          .get();

                      for (var doc in cartItems.docs) {
                        final gameData = doc.data();
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('library')
                            .doc(doc.id)
                            .set(gameData);

                        await doc.reference.delete(); // Удаляем игру из корзины после покупки
                      }

                      setState(() {}); // Обновляем состояние
                    },
                  ),
                ), // Переход в корзину
              );
            },
          ),
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
                labelText: 'Поиск игр',
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
                    future: _isInLibrary(gameId),
                    builder: (context, librarySnapshot) {
                      final isInLibrary = librarySnapshot.data ?? false;

                      if (isInLibrary) {
                        // Если игра в библиотеке
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0), // Добавление отступов между карточками
                          child: Card(
                            elevation: 3, // Добавляем приподнятую поверхность
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  game['thumb'],
                                  width: 100,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  color: Colors.grey, // Серая картинка для купленных игр
                                  colorBlendMode: BlendMode.saturation,
                                ),
                              ),
                              title: Text(
                                game['external'],
                                style: TextStyle(color: Colors.grey), // Серый текст для купленных игр
                              ),
                              subtitle: Text(
                                'Куплено',
                                style: TextStyle(color: Colors.grey),
                              ),
                              trailing: Icon(Icons.check, color: Colors.green), // Иконка купленной игры
                            ),
                          ),
                        );
                      } else {
                        return FutureBuilder<bool>(
                          future: _isFavorite(gameId),
                          builder: (context, favoriteSnapshot) {
                            final isFavorite = favoriteSnapshot.data ?? false;
                            return FutureBuilder<bool>(
                              future: _isInCart(gameId),
                              builder: (context, cartSnapshot) {
                                final isInCart = cartSnapshot.data ?? false;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5.0), // Добавление отступов
                                  child: Card(
                                    elevation: 3, // Приподнятая карточка
                                    child: ListTile(
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
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isInCart ? Icons.shopping_cart : Icons.add_shopping_cart, // Иконка корзины
                                              color: isInCart ? Colors.green : Colors.grey,
                                            ),
                                            onPressed: isInCart
                                                ? null
                                                : () {
                                              _toggleCart(gameId, game); // Добавление/удаление из корзины
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isFavorite ? Icons.favorite : Icons.favorite_border, // Звездочка
                                              color: isFavorite ? Colors.yellow : Colors.grey,
                                            ),
                                            onPressed: () {
                                              _toggleFavorite(gameId, game); // Добавление/удаление из избранного
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => GameDetailsScreen(gameId: gameId),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }
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
