import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();



  Future<void> _register() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _usernameController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _showError('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        _showError('An account already exists for that email.');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  // Future<void> _register() async {
  //   final url = Uri.parse('http://10.0.2.2:8080/api/v1/auth/registration');
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
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => LoginScreen()),
  //     );
  //   } else {
  //     _showError("Registration failed");
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
      appBar: AppBar(title: Text('Register')),
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
              onPressed: _register,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
