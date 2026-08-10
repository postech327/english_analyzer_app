import 'package:english_analyzer_app/screens/student_dashboard_screen.dart';
import 'package:english_analyzer_app/screens/student/mock_exam_report_screen.dart';
import 'package:english_analyzer_app/screens/student/problem_set_results_screen.dart';
import 'package:english_analyzer_app/screens/student_learning_assignments_screen.dart';
import 'package:english_analyzer_app/screens/student_vocabulary_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _dashboard({required bool withRecords}) {
  Map<String, dynamic> domain(double latest, double average, int count) => {
        'latest_score': withRecords ? latest : null,
        'average_score': withRecords ? average : null,
        'attempt_count': withRecords ? count : 0,
        'has_records': withRecords,
      };

  return {
    'total_attempts': withRecords ? 2 : 0,
    'total_questions_solved': withRecords ? 10 : 0,
    'latest_attempt_score': withRecords ? 80 : null,
    'average_score': withRecords ? 75 : null,
    'weakest_type': null,
    'trend_direction': 'stable',
    'recent_results': const [],
    'recommendations': const [],
    'learning_status': {
      'workbook': domain(80, 76.5, 4),
      'vocabulary': domain(90, 84.2, 7),
      'problem_set': domain(70, 68, 9),
      'mock_exam': domain(95, 88, 3),
    },
  };
}

void main() {
  testWidgets('shows four learning domains and completed metrics',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentDashboardScreen(
          dashboardLoader: () async => _dashboard(withRecords: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('학습 상태 요약'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('워크북'), findsWidgets);
    expect(find.text('단어장'), findsWidgets);
    expect(find.text('내신 변형문제'), findsWidgets);
    expect(find.text('모의고사'), findsWidgets);
    expect(find.text('80점'), findsWidgets);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('평균 76.5점 · 완료 4회'), findsOneWidget);
    expect(find.text('평균 84.2% · 완료 7회'), findsOneWidget);
    expect(find.text('오늘의 학습'), findsWidgets);
  });

  testWidgets('shows records and empty domains independently', (tester) async {
    final data = _dashboard(withRecords: false);
    (data['learning_status'] as Map<String, dynamic>)['workbook'] = {
      'latest_score': 72,
      'average_score': 68.5,
      'attempt_count': 2,
      'has_records': true,
    };
    await tester.pumpWidget(
      MaterialApp(
        home: StudentDashboardScreen(dashboardLoader: () async => data),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('학습 상태 요약'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('72점'), findsOneWidget);
    expect(find.text('평균 68.5점 · 완료 2회'), findsOneWidget);
    expect(find.text('학습 기록 없음'), findsNWidgets(3));
  });

  testWidgets('distinguishes no records from zero score at 260px',
      (tester) async {
    tester.view.physicalSize = const Size(260, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: StudentDashboardScreen(
          dashboardLoader: () async => _dashboard(withRecords: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('학습 상태 요약'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('학습 기록 없음'), findsNWidgets(4));
    expect(find.text('첫 학습을 시작해 보세요'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows retry UI when dashboard API fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentDashboardScreen(
          dashboardLoader: () async => throw Exception('network'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('학습 현황을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.text('학습 기록 없음'), findsNothing);
  });

  testWidgets('each status card dispatches its result destination',
      (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: StudentDashboardScreen(
          dashboardLoader: () async => _dashboard(withRecords: true),
          onLearningDomainTap: opened.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('학습 상태 요약'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    for (final entry in const {
      '워크북': 'workbook',
      '단어장': 'vocabulary',
      '내신 변형문제': 'problem_set',
      '모의고사': 'mock_exam',
    }.entries) {
      final card = find.ancestor(
        of: find.text(entry.key).last,
        matching: find.byType(InkWell),
      );
      await tester.tap(card.first);
      await tester.pump();
      expect(opened.last, entry.value);
    }
  });

  testWidgets('dashboard status cards open result screens, not study lists',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentDashboardScreen(
          dashboardLoader: () async => _dashboard(withRecords: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('학습 상태 요약'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    Future<void> verifyRoute(
      String label,
      Finder destination,
    ) async {
      final card = find.byKey(ValueKey('learning-domain-$label'));
      await tester.scrollUntilVisible(
        card,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(card);
      await tester.pump(const Duration(milliseconds: 500));
      expect(destination, findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pump(const Duration(milliseconds: 500));
    }

    await verifyRoute(
      '워크북',
      find.byWidgetPredicate(
        (widget) =>
            widget is StudentLearningAssignmentsScreen && widget.resultsMode,
        skipOffstage: false,
      ),
    );
    await verifyRoute(
      '단어장',
      find.byWidgetPredicate(
        (widget) => widget is StudentVocabularyListScreen && widget.resultsMode,
        skipOffstage: false,
      ),
    );
    await verifyRoute(
      '내신 변형문제',
      find.byType(ProblemSetResultsScreen, skipOffstage: false),
    );
    await verifyRoute(
      '모의고사',
      find.byType(StudentMockExamReportScreen, skipOffstage: false),
    );
  });
}
