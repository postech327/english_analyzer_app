import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _loginResult = "";

  Future<void> _login() async {
    final url = Uri.parse("http://localhost:8000/login"); // ✅ FastAPI 주소

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _loginResult = result['message'] == 'login success'
              ? "✅ 로그인 성공!"
              : "❌ 로그인 실패!";
        });
      } else {
        setState(() {
          _loginResult = "❌ 로그인 실패: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _loginResult = "❗ 네트워크 오류: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(title: const Text("English Analyzer")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Login",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _login,
                child: const Text("Login"),
              ),
            ),
            const SizedBox(height: 16),
            if (_loginResult.isNotEmpty)
              Center(
                child: Text(
                  _loginResult,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
