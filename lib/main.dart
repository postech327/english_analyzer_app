// lib/main.dart
import 'package:flutter/material.dart';

// modes & screens
import 'screens/auth_screen.dart';
import 'screens/app_shell.dart';
import 'screens/analyzer_m3_screen.dart';
import 'screens/register_screen.dart';
import 'screens/teacher_mode.dart';
import 'screens/student_mode.dart';
import 'screens/manage_mode.dart';
import 'screens/topic_summary_page.dart';
import 'screens/word_synonym_page.dart';
import 'screens/export_ppt_page.dart';
import 'screens/text_analysis_hub_screen.dart';
import 'screens/analyses_list_screen.dart';
import 'screens/analysis_detail_screen.dart';
import 'screens/problem_set_preview_screen.dart';

// ✅ question maker
import 'screens/question_maker/question_maker_home.dart';
import 'screens/question_maker/pages/topic_question_page.dart';
import 'screens/question_maker/pages/title_question_page.dart';
import 'screens/question_maker/pages/gist_question_page.dart';
import 'screens/question_maker/pages/summary_question_page.dart';
import 'screens/question_maker/pages/cloze_question_page.dart';
import 'screens/question_maker/pages/insertion_question_page.dart';
import 'screens/question_maker/pages/order_question_page.dart';

// 🆕 선생님용 문제제작 단일 화면
import 'screens/teacher_question_maker_screen.dart';

// 🆕 학생 퀴즈 화면
import 'screens/student_quiz_screen.dart';

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
        // 기본
        '/': (_) => const AuthScreen(),
        '/app': (_) => const AppShell(),

        // 기능
        '/analyzer': (_) => const AnalyzerM3Screen(),
        '/topic_summary': (_) => const TopicSummaryPage(),
        '/word_synonym': (_) => const WordSynonymPage(),
        '/export_ppt': (_) => const ExportPptPage(),

        // 모드
        '/text_analysis_hub': (context) => const TextAnalysisHubScreen(),
        '/teacher': (_) => const TeacherModePage(),
        '/student': (_) => const StudentModePage(),
        '/manage': (_) => const ManageModePage(),
        '/register': (_) => const RegisterScreen(),

        // 🆕 선생님용 문제 제작 화면
        '/teacher_qm': (_) => const TeacherQuestionMakerScreen(),

        // 🆕 학생 퀴즈 화면
        //  - 예전 코드: arguments 를 int (problemSetId) 로만 넘김
        //  - 새로운 코드: {'problemSetId': int, 'questionType': String?} 형태의 Map 을 넘김
        //  → 둘 다 지원하도록 타입 분기 처리
        '/student_quiz': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;

          int problemSetId;
          String? questionType;

          if (args is int) {
            // 옛날 방식: 그냥 problemSetId 만 넘긴 경우
            problemSetId = args;
            questionType = null;
          } else if (args is Map<String, dynamic>) {
            // 새 방식: { 'problemSetId': ..., 'questionType': ... }
            problemSetId = args['problemSetId'] as int;
            questionType = args['questionType'] as String?;
          } else {
            // 둘 다 아니면 에러
            throw ArgumentError(
              'Invalid arguments for /student_quiz: $args',
            );
          }

          return StudentQuizScreen(
            problemSetId: problemSetId,
            questionType: questionType,
          );
        },

        // ✅ 문제제작(홈 + 세부 유형)
        '/qm': (_) => const QuestionMakerHome(),
        '/qm/topic': (_) => const TopicQuestionPage(),
        '/qm/title': (_) => const TitleQuestionPage(),
        '/qm/gist': (_) => const GistQuestionPage(),
        '/qm/summary': (_) => const SummaryQuestionPage(),
        '/qm/cloze': (_) => const ClozeQuestionPage(),
        '/qm/insertion': (_) => const InsertionQuestionPage(),
        '/qm/order': (_) => const OrderQuestionPage(),
        '/analyses_list': (_) => const AnalysesListScreen(),
        '/analysis_detail': (_) => const AnalysisDetailScreen(),
        '/problem_set_preview': (_) => const ProblemSetPreviewScreen(),
      },
      onUnknownRoute: (s) =>
          MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }
}
