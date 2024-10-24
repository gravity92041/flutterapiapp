import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartScreen extends StatefulWidget {
  final Function onBuy;

  CartScreen({required this.onBuy});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<List<Map<String, dynamic>>> _getCartItems() async {
    final userId = currentUser?.uid;
    if (userId == null) return [];

    final cartCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');
    final cartSnapshot = await cartCollection.get();

    return cartSnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> _removeFromCart(String gameId) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).collection('cart').doc(gameId).delete();
    setState(() {}); // Обновляем состояние для перерисовки списка
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Корзина'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getCartItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final cartItems = snapshot.data ?? [];

          if (cartItems.isEmpty) {
            return Center(child: Text('Корзина пуста'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final game = cartItems[index];
                    final gameId = game['gameID'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0), // Добавляем отступы между карточками
                      child: Card(
                        elevation: 3, // Добавляем эффект приподнятой поверхности
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
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _removeFromCart(gameId);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await widget.onBuy(); // Покупка игр
                    Navigator.pop(context); // Возвращаемся после покупки
                  },
                  child: Text('Купить все игры'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
