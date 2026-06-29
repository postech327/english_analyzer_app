// lib/screens/student_mode.dart
import 'package:flutter/material.dart';

// 학생용 Dashboard
import 'student_dashboard_screen.dart';

class StudentModePage extends StatefulWidget {
  const StudentModePage({super.key});

  @override
  State<StudentModePage> createState() => _StudentModePageState();
}

class _StudentModePageState extends State<StudentModePage> {
  @override
  Widget build(BuildContext context) {
    /*
      학생 모드 진입 허브 역할

      ✔ 현재 구조:
        - 학생 모드 진입 시 Dashboard를 바로 보여준다
        - 문제 ID 직접 입력 / 퀴즈 시작 로직은 더 이상 여기서 처리하지 않는다
        - 실제 학습 흐름은 Dashboard → Exam List → Exam Take 로 이어짐

      ✔ 이 페이지는 "껍데기" 역할만 수행
    */
    return const StudentDashboardScreen();
  }
}
