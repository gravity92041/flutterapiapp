import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  String _sortOrder = 'asc'; // Переменная для отслеживания текущего порядка сортировки

  Future<List<Map<String, dynamic>>> _getLibraryItems() async {
    final userId = currentUser?.uid;
    if (userId == null) return [];

    final libraryCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('library');
    final librarySnapshot = await libraryCollection.get();

    List<Map<String, dynamic>> libraryItems = librarySnapshot.docs.map((doc) => doc.data()).toList();

    // Сортировка по названию
    switch (_sortOrder) {
      case 'asc_name':
        libraryItems.sort((a, b) => a['external'].compareTo(b['external']));
        break;
      case 'desc_name':
        libraryItems.sort((a, b) => b['external'].compareTo(a['external']));
        break;
      case 'asc_price':
        libraryItems.sort((a, b) {
          // Преобразование цены в числовой тип перед сравнением
          final priceA = double.tryParse(a['cheapest'].toString()) ?? 0.0;
          final priceB = double.tryParse(b['cheapest'].toString()) ?? 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'desc_price':
        libraryItems.sort((a, b) {
          final priceA = double.tryParse(a['cheapest'].toString()) ?? 0.0;
          final priceB = double.tryParse(b['cheapest'].toString()) ?? 0.0;
          return priceB.compareTo(priceA);
        });
        break;
    }

    return libraryItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Библиотека'),
        actions: [
          DropdownButton<String>(
            value: _sortOrder,
            icon: Icon(Icons.sort, color: Colors.black),
            dropdownColor: Colors.white,
            onChanged: (String? newValue) {
              setState(() {
                _sortOrder = newValue ?? 'asc'; // Обновляем порядок сортировки
              });
            },
            items: [
              DropdownMenuItem(
                value: 'asc',
                child: Text('По названию (А-Я)', style: TextStyle(color: Colors.black)),
              ),
              DropdownMenuItem(
                value: 'desc',
                child: Text('По названию (Я-А)', style: TextStyle(color: Colors.black)),
              ),
              DropdownMenuItem(
                value: 'asc_price',
                child: Text('По цене (↓-↑)', style: TextStyle(color: Colors.black)),
              ),
              DropdownMenuItem(
                value: 'desc_price',
                child: Text('По цене (↑-↓)', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ],
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

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
                child: Card(
                  elevation: 3,
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
                    subtitle: Text('Price: \$${game['cheapest']}'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
