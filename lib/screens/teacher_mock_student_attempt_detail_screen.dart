import 'package:flutter/material.dart';

import '../services/teacher_mock_exam_service.dart';
import 'student/mock_exam_attempt_detail_screen.dart';

class TeacherMockStudentAttemptDetailScreen extends StatelessWidget {
  const TeacherMockStudentAttemptDetailScreen({
    super.key,
    required this.studentId,
    required this.attemptId,
    required this.nickname,
  });

  final int studentId;
  final int attemptId;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    return StudentMockExamAttemptDetailScreen(
      attemptId: attemptId,
      title: '$nickname 오답 상세',
      fetcher: (id) => TeacherMockExamService.fetchMockStudentAttemptDetail(
        studentId: studentId,
        attemptId: id,
      ),
    );
  }
}
