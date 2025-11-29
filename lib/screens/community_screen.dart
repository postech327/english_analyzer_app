// lib/screens/community_screen.dart
import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('커뮤니티'),
      ),
      body: const Center(
        child: Text(
          '커뮤니티(준비 중)...\n\n'
          '앞으로 선생님·학생들이 스터디 모집,\n'
          '질문/답변, 자료 나눔을 할 수 있는 공간이 될 예정입니다.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}