import 'package:english_analyzer_app/models/learning_assignment.dart';
import 'package:english_analyzer_app/models/workbook.dart';
import 'package:english_analyzer_app/screens/student_workbook_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Korean T/F uses the existing selectable Student renderer',
      (tester) async {
    tester.view.physicalSize = const Size(260, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const items = <Map<String, dynamic>>[
      <String, dynamic>{
        'number': 1,
        'statement': '첫 번째 한글 진술문은 본문과 일치한다.',
        'answer': true,
      },
      <String, dynamic>{
        'number': 2,
        'statement': '두 번째 한글 진술문은 본문과 일치하지 않는다.',
        'answer': false,
      },
    ];
    const content = <String, dynamic>{
      'subtype': 'true_false_ko',
      'passage_text': '학생에게 제시되는 영어 본문입니다.',
      'items': items,
    };
    const question = WorkbookQuestion(
      id: 71,
      questionType: 'true_false',
      orderIndex: 1,
      prompt: '한글 진술문이 본문과 일치하면 T, 일치하지 않으면 F를 고르세요.',
      passageText: '학생에게 제시되는 영어 본문입니다.',
      answer: content,
      content: content,
    );
    const workbook = Workbook(
      id: 7,
      title: '한글 T/F 워크북',
      status: 'published',
      questionCount: 1,
      questions: <WorkbookQuestion>[question],
    );
    const assignment = LearningAssignment(
      id: 7,
      teacherId: 1,
      studentId: 2,
      contentType: 'workbook',
      contentId: 7,
      title: '한글 T/F 학습',
      status: 'in_progress',
      assignedAt: '2026-08-05T00:00:00',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: StudentWorkbookViewScreen(
          assignment: assignment,
          initialWorkbook: workbook,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('첫 번째 한글 진술문'), findsOneWidget);
    expect(find.textContaining('두 번째 한글 진술문'), findsOneWidget);
    expect(find.text('T'), findsNWidgets(2));
    expect(find.text('F'), findsNWidgets(2));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('T').first);
    await tester.pump();
    final firstControl = tester.widget<SegmentedButton<bool>>(
      find.byType(SegmentedButton<bool>).first,
    );
    expect(firstControl.selected, <bool>{true});
    expect(tester.takeException(), isNull);
  });
}
