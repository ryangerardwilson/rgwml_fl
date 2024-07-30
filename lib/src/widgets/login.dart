import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard.dart'; // Ensure this path is correct
import '../modal_config.dart'; // Ensure this path is correct

class LoginPage extends StatefulWidget {
  final String apiHost;
  final String title;
  //final List<String> cardTitles;
  final String versionUrl;
  final String currentVersion;
  final ModalConfigMap modalConfig; // Add this parameter

  LoginPage({
    required this.apiHost,
    required this.title,
    //required this.cardTitles,
    required this.versionUrl,
    required this.currentVersion,
    required this.modalConfig, // Ensure this is a required parameter
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  Future<void> handleLogin() async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('${widget.apiHost}authenticate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      final result = json.decode(response.body);

      if (result['status'] == 'success') {
        final user = result['user'];

        // Save authentication information
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user['id'].toString());
        await prefs.setString('username', user['username']);
        await prefs.setString('user_type', user['type']);
        await prefs.setBool('auth', true);

        // Navigate to CRMDashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CRMDashboard(
              title: widget.title,
              //cardTitles: widget.cardTitles,
              versionUrl: widget.versionUrl,
              currentVersion: widget.currentVersion,
              apiHost: widget.apiHost,
              modalConfig: widget.modalConfig, // Pass modalConfig here
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Authentication failed';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred during authentication. Please try again.';
      });
      print('Error during authentication: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chemical-X',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleLogin,
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24, // Background color of the button
                foregroundColor: Colors.white, // Text color of the button
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

