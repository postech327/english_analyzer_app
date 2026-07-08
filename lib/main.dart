// lib/main.dart
import 'package:flutter/material.dart';

// 기본 화면
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';

// 분석/기능
import 'screens/analyzer_m3_screen.dart';
import 'screens/topic_summary_page.dart';
import 'screens/word_synonym_page.dart';
import 'screens/export_ppt_page.dart';

// 모드
import 'screens/text_analysis_hub_screen.dart';
import 'screens/teacher_mode.dart';
import 'screens/manage_mode.dart';
import 'screens/register_screen.dart';

// 학생
import 'screens/student/student_exam_list_screen.dart';
import 'screens/student/mock_exam_list_screen.dart';
import 'screens/teacher_mock_exam_list_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/student_quiz_screen.dart';

// 커뮤니티
import 'screens/community/community_list_screen.dart';

// 문제 제작
import 'screens/question_maker/question_maker_home.dart';
import 'screens/question_maker/pages/topic_question_page.dart';
import 'screens/question_maker/pages/title_question_page.dart';
import 'screens/question_maker/pages/gist_question_page.dart';
import 'screens/question_maker/pages/summary_question_page.dart';
import 'screens/question_maker/pages/cloze_question_page.dart';
import 'screens/question_maker/pages/insertion_question_page.dart';
import 'screens/question_maker/pages/order_question_page.dart';

// 🔥 추가 (핵심)
import 'screens/exam_result_summary_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.deepPurple,
      fontFamily: 'NotoSansKR',
    );

    return MaterialApp(
      title: 'English Analyzer',
      debugShowCheckedModeBanner: false,
      theme: base,
      darkTheme: base.copyWith(brightness: Brightness.dark),
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthScreen(),
        '/app': (_) => const MainNavigationScreen(),

        // 기능
        '/analyzer': (_) => const AnalyzerM3Screen(),
        '/topic_summary': (_) => const TopicSummaryPage(),
        '/word_synonym': (_) => const WordSynonymPage(),
        '/export_ppt': (_) => const ExportPptPage(),

        // 모드
        '/text_analysis_hub': (_) => const TextAnalysisHubScreen(),
        '/teacher': (_) => const TeacherModePage(),
        '/student': (_) => const MainNavigationScreen(),
        '/manage': (_) => const ManageModePage(),
        '/register': (_) => const RegisterScreen(),

        // 학생
        '/student_exam_list': (_) => const StudentExamListScreen(),
        '/student_mock_exams': (_) => const MockExamListScreen(),
        '/teacher_mock_exams': (_) => const TeacherMockExamListScreen(),
        '/dashboard': (_) => const StudentDashboardScreen(),

        // 🔥 핵심
        '/exam_result_summary': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;

          return ExamResultSummaryScreen(
            problemSetId: args['problemSetId'],
            userId: args['userId'],
          );
        },

        // 퀴즈
        '/student_quiz': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;

          late int problemSetId;

          if (args is int) {
            problemSetId = args;
          } else if (args is Map<String, dynamic>) {
            problemSetId = args['problemSetId'] as int;
          } else {
            throw ArgumentError('Invalid arguments');
          }

          return StudentQuizScreen(problemSetId: problemSetId);
        },

        // 문제 제작
        '/qm': (_) => const QuestionMakerHome(),
        '/qm/topic': (_) => const TopicQuestionPage(),
        '/qm/title': (_) => const TitleQuestionPage(),
        '/qm/gist': (_) => const GistQuestionPage(),
        '/qm/summary': (_) => const SummaryQuestionPage(),
        '/qm/cloze': (_) => const ClozeQuestionPage(),
        '/qm/insertion': (_) => const InsertionQuestionPage(),
        '/qm/order': (_) => const OrderQuestionPage(),

        // 커뮤니티
        '/community': (_) => const CommunityListScreen(),
      },
      onUnknownRoute: (s) =>
          MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }
}
