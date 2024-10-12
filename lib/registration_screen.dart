import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Import Firestore

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _register() async {
    try {
      // Firebase Authentication registration
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _usernameController.text,
        password: _passwordController.text,
      );

      // Add the user to Firestore after successful registration
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'email': _usernameController.text,
        'createdAt': Timestamp.now(),
      });

      // Navigate to the login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _showError('Выбранный пароль слишком слабый.');
      } else if (e.code == 'email-already-in-use') {
        _showError('Уже существует пользователь с такой почтой.');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.lightBlueAccent,
              Colors.blueAccent,
            ],
          ),
        ),
        child: Center( // Центрируем содержимое
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card( // Используем Card для эффекта окна
              elevation: 8, // Эффект тени
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Закругленные углы
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Внутренний отступ
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Сжимаем колонку по содержимому
                  children: [
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Почта',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16), // Отступ между полями
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 20), // Отступ перед кнопкой
                    ElevatedButton(
                      onPressed: _register,
                      child: Text('Регистрация'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
