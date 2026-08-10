import 'package:english_analyzer_app/models/learning_assignment.dart';
import 'package:english_analyzer_app/models/problem_set_result_summary.dart';
import 'package:english_analyzer_app/models/vocabulary.dart';
import 'package:english_analyzer_app/models/workbook_attempt.dart';
import 'package:english_analyzer_app/screens/student/mock_exam_report_screen.dart';
import 'package:english_analyzer_app/screens/student/problem_set_results_screen.dart';
import 'package:english_analyzer_app/screens/student_learning_assignments_screen.dart';
import 'package:english_analyzer_app/screens/student_vocabulary_screens.dart';
import 'package:english_analyzer_app/widgets/student/unified_learning_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('common result card keeps zero score and fits 260px',
      (tester) async {
    tester.view.physicalSize = const Size(260, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: UnifiedLearningResultCard(
              title: '아주 긴 학습 자료명이 두 줄까지 자연스럽게 표시되는 결과',
              subtitle: '교재 · 폴더 · 출처',
              dateLabel: '최근 제출 2026-08-04 11:47',
              score: 0,
              correctCount: 0,
              totalCount: 25,
              leadingIcon: Icons.menu_book_rounded,
              accentColor: Color(0xFF2563EB),
              badges: ['1회차', '완료'],
              primaryActionLabel: '결과 보기',
              secondaryActionLabel: '다시 풀기',
              onPrimaryAction: _noop,
              onSecondaryAction: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.text('0점'), findsOneWidget);
    expect(find.text('0/25'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workbook results separate completed and in-progress items',
      (tester) async {
    tester.view.physicalSize = const Size(260, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final completed = _assignment(id: 1, title: '한글TF', status: 'completed');
    final pending = _assignment(id: 2, title: '다음 워크북', status: 'assigned');
    const attempt = WorkbookAttempt(
      id: 11,
      assignmentId: 1,
      workbookId: 101,
      attemptNo: 1,
      totalQuestions: 25,
      correctCount: 13,
      wrongCount: 12,
      scorePercent: 52,
      submittedAt: '2026-08-04T11:47:00',
      results: [
        WorkbookAttemptAnswerResult(
          questionId: 1,
          questionType: 'true_false',
          studentAnswer: 'T',
          correctAnswer: 'F',
          isCorrect: false,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudentLearningAssignmentsScreen(
          resultsMode: true,
          assignmentLoader: () async => [completed, pending],
          latestAttemptLoader: (id) async => id == 1 ? attempt : null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('52점'), findsOneWidget);
    expect(find.text('13/25'), findsOneWidget);
    expect(find.text('최근 제출 2026-08-04 11:47'), findsOneWidget);
    expect(find.text('1회차'), findsWidgets);
    expect(find.text('학습 중'), findsOneWidget);
    expect(find.text('다음 워크북'), findsOneWidget);

    await tester.tap(find.text('결과 보기'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentWorkbookAttemptResultScreen), findsOneWidget);
    expect(find.text('정답: F'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vocabulary results show attempts and no-record set separately',
      (tester) async {
    tester.view.physicalSize = const Size(260, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final resultSet = _vocabularySet(1, '수라(상)단어');
    final emptySet = _vocabularySet(2, '새 단어장');
    const attempt = VocabularyAttempt(
      id: 21,
      setId: 1,
      score: 92.3,
      totalCount: 78,
      correctCount: 72,
      createdAt: '2026-08-04T09:00:00',
      results: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudentVocabularyListScreen(
          resultsMode: true,
          setsLoader: () async => [resultSet, emptySet],
          attemptsLoader: (id) async => id == 1 ? [attempt, attempt] : [],
          attemptDetailLoader: (_) async => attempt,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('92.3%'), findsOneWidget);
    expect(find.text('72/78'), findsOneWidget);
    expect(find.text('2회 완료'), findsOneWidget);
    expect(find.text('새 단어장'), findsOneWidget);
    expect(find.textContaining('학습 기록 없음'), findsWidgets);
    expect(find.text('학습하기'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('결과 보기'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentVocabularyResultScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('problem set and mock results use the common card',
      (tester) async {
    const problemResult = ProblemSetResultSummary(
      attemptId: 31,
      problemSetId: 41,
      problemSetName: '내신 변형문제 세트',
      score: 80,
      correctCount: 8,
      totalCount: 10,
      weakTypes: ['빈칸'],
      source: '교재 1과',
      submittedAt: '2026-08-04T10:00:00',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProblemSetResultsScreen(
          resultsLoader: () async => [problemResult],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(UnifiedLearningResultCard), findsOneWidget);
    expect(find.text('80점'), findsOneWidget);
    expect(find.text('오답 다시보기'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: StudentMockExamReportScreen(
          reportLoader: () async => {
            'summary': {
              'attempt_count': 1,
              'average_score': 85,
              'highest_score': 85,
              'latest_score': 85,
              'weak_types': ['순서'],
            },
            'type_stats': const [],
            'score_trend': const [],
            'recent_attempts': [
              {
                'attempt_id': 51,
                'title': '2026년 6월 모의고사',
                'grade': '고1',
                'year': 2026,
                'month': 6,
                'score': 85,
                'correct_count': 17,
                'total_questions': 20,
                'weak_types': ['순서'],
                'submitted_at': '2026-08-04T12:00:00',
              },
            ],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('2026년 6월 모의고사'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(UnifiedLearningResultCard), findsOneWidget);
    expect(find.text('17/20'), findsOneWidget);
  });

  testWidgets('result screens distinguish no records from a zero score',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentLearningAssignmentsScreen(
          resultsMode: true,
          assignmentLoader: () async => [],
          latestAttemptLoader: (_) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('학습 기록 없음'), findsOneWidget);
    expect(find.text('첫 학습을 시작해 보세요'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: StudentVocabularyListScreen(
          resultsMode: true,
          setsLoader: () async => [],
          attemptsLoader: (_) async => [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('학습 기록 없음'), findsOneWidget);
    expect(find.text('첫 학습을 시작해 보세요'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: ProblemSetResultsScreen(resultsLoader: () async => []),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('학습 기록 없음'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: StudentMockExamReportScreen(
          reportLoader: () async => {
            'summary': const {},
            'type_stats': const [],
            'score_trend': const [],
            'recent_attempts': const [],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('학습 기록 없음'), findsOneWidget);
    expect(find.text('모의고사 시작'), findsOneWidget);
  });
}

void _noop() {}

LearningAssignment _assignment({
  required int id,
  required String title,
  required String status,
}) {
  return LearningAssignment(
    id: id,
    teacherId: 1,
    studentId: 2,
    contentType: 'workbook',
    contentId: 100 + id,
    title: title,
    status: status,
    assignedAt: '2026-08-01T00:00:00',
    sourceLabel: '교재',
    folderName: '1과',
  );
}

VocabularySet _vocabularySet(int id, String title) {
  return VocabularySet(
    id: id,
    title: title,
    status: 'published',
    itemCount: 78,
    sourceLabel: '수라(상)',
    unitLabel: '1과',
  );
}
