import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import 'analyzer_screen.dart'; // 로그인 후 이동

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _loading = false;
  String _msg = '';

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _msg = '';
    });

    try {
      final res = await http
          .post(
            ApiConfig.u(ApiConfig.login),
            headers: const {
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({
              'username': _id.text.trim(),
              'password': _pw.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode == 200) {
        // 로그인 성공 → 분석 화면으로 이동
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AnalyzerScreen()),
        );
      } else {
        setState(() => _msg = '❌ 로그인 실패: ${res.body}');
      }
    } catch (e) {
      setState(() => _msg = '네트워크 오류: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(title: const Text('English Analyzer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Login',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 28),
            TextField(
              controller: _id,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pw,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 12),
            if (_msg.isNotEmpty)
              Text(
                _msg,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
