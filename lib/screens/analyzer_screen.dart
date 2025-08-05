import 'package:flutter/material.dart';

class AnalyzerScreen extends StatelessWidget {
  const AnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analyzer")),
      body: const Center(
        child: Text(
          "✅ 로그인 성공! 여기가 Analyzer 화면입니다.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}