import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<List<Map<String, dynamic>>> _getLibraryItems() async {
    final userId = currentUser?.uid;
    if (userId == null) return [];

    final libraryCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('library');
    final librarySnapshot = await libraryCollection.get();

    return librarySnapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Библиотека'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getLibraryItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final libraryItems = snapshot.data ?? [];

          if (libraryItems.isEmpty) {
            return Center(child: Text('Библиотека пуста'));
          }

          return ListView.builder(
            itemCount: libraryItems.length,
            itemBuilder: (context, index) {
              final game = libraryItems[index];

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
                subtitle: Text('Price: \$${game['cheapest']}'),
              );
            },
          );
        },
      ),
    );
  }
}
