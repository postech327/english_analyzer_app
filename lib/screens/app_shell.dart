// lib/screens/app_shell.dart
import 'package:flutter/material.dart';

// 새 홈 대시보드
import 'home_screen.dart';

// 모드별 페이지
import 'teacher_mode.dart';
import 'student_mode.dart';
import 'manage_mode.dart'; // ✅ 관리형
import 'chat_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// 기본 탭 인덱스 (0: 홈)
  int _idx = 0;

  late final List<Widget> _pages = <Widget>[
    const HomeScreen(), // 0: 홈(대시보드)
    const ManageModePage(), // 1: 관리형(관리자)
    const TeacherModePage(), // 2: 선생님
    const StudentModePage(), // 3: 학생
    const ChatScreen(), // 4: 챗봇
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Navigator.pushNamed(context, '/app', arguments: index) 로 진입 시 해당 탭으로 열기
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is int && arg >= 0 && arg < _pages.length) {
      _idx = arg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: '홈'),
          NavigationDestination(
              icon: Icon(Icons.admin_panel_settings), label: '관리형'),
          NavigationDestination(icon: Icon(Icons.school_rounded), label: '선생님'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: '학생'),
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: '챗봇'),
        ],
      ),
    );
  }
}
