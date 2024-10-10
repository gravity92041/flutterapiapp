import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GameDetailsScreen extends StatefulWidget {
  final String gameId;

  GameDetailsScreen({required this.gameId});

  @override
  _GameDetailsScreenState createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  Map<String, dynamic>? _gameDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGameDetails();
  }

  Future<void> _fetchGameDetails() async {
    final url = Uri.parse('https://www.cheapshark.com/api/1.0/games?id=${widget.gameId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _gameDetails = json.decode(response.body);
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load game details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Details'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _gameDetails != null
          ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              _gameDetails!['info']['thumb'],
              height: 200,
              width: double.infinity,  // Makes the image take the full available width
              fit: BoxFit.cover,  // Ensures the image covers the available space while maintaining the aspect ratio
            ),
            SizedBox(height: 10),
            Text(
              _gameDetails!['info']['title'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Cheapest Price Ever: \$${_gameDetails!['cheapestPriceEver']['price']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Deals:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _gameDetails!['deals'].length,
                itemBuilder: (context, index) {
                  final deal = _gameDetails!['deals'][index];
                  return ListTile(
                    title: Text('Price: \$${deal['price']}'),
                    subtitle: Text('Retail Price: \$${deal['retailPrice']} (Savings: ${deal['savings']}%)'),
                  );
                },
              ),
            ),
          ],
        ),
      )
          : Center(child: Text('Failed to load game details')),
    );
  }
}
