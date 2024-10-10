import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart'; // Импортируем главный экран
import 'registration_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Future<void> _login() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameSearchApp(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showError('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        _showError('Wrong password provided.');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }
  // Future<void> _login() async {
  //   final url = Uri.parse('http://10.0.2.2:8080/api/v1/auth/login');
  //   final response = await http.post(
  //     url,
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode({
  //       "username": _usernameController.text,
  //       "password": _passwordController.text,
  //     }),
  //   );
  //
  //   if (response.statusCode == 200) {
  //
  //     final data = jsonDecode(response.body);
  //
  //     if (data['Auth'] == 'Fine') {
  //       // SharedPreferences prefs = await SharedPreferences.getInstance();
  //       // await prefs.setString('username', _usernameController.text);
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           // builder: (context) => GameSearchApp(username: _usernameController.text),
  //           builder: (context) => GameSearchApp(),
  //         ),
  //       );
  //     } else {
  //       print("Invalid credentials");
  //     }
  //   } else {
  //     print("Login failed");
  //   }
  // }

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
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationScreen()),
                );
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
