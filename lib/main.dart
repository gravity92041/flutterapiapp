import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'game_details_screen.dart'; // Импортируем экран с деталями

void main() {
  runApp(GameSearchApp());
}

class GameSearchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameSearchScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Search'),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
