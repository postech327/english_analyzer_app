import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:english_analyzer_app/models/order_generation_models.dart';
import 'package:english_analyzer_app/screens/teacher/teacher_semantic_order_screen.dart';
import 'package:english_analyzer_app/screens/teacher_question_maker_screen.dart';
import 'package:english_analyzer_app/services/order_generation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AuthStore.saveLogin(accessTokenValue: 'token', roleValue: 'teacher');
  });
  tearDown(AuthStore.clear);

  testWidgets('screen renders for a teacher', (tester) async {
    await _pump(tester, FakeOrderGateway());
    expect(find.byType(TeacherSemanticOrderScreen), findsOneWidget);
    expect(find.text('Semantic 순서 문제 만들기'), findsOneWidget);
    expect(find.byKey(const Key('order-passage-input')), findsOneWidget);
  });

  testWidgets('empty passage disables analysis', (tester) async {
    await _pump(tester, FakeOrderGateway());
    expect(_button(tester, 'order-analyze-button').onPressed, isNull);
  });

  testWidgets('passage input enables analysis', (tester) async {
    await _pump(tester, FakeOrderGateway());
    await tester.enterText(
      find.byKey(const Key('order-passage-input')),
      'A sufficiently long English passage.',
    );
    await tester.pump();
    expect(_button(tester, 'order-analyze-button').onPressed, isNotNull);
  });

  testWidgets('candidate list renders fixed intro blocks score and evidence', (
    tester,
  ) async {
    await _pump(tester, FakeOrderGateway());
    await _analyze(tester);
    expect(
      find.byKey(const Key('order-candidate-ORDER-CAND-1')),
      findsOneWidget,
    );
    expect(find.textContaining('안전도 88%'), findsOneWidget);
    expect(find.textContaining('Intro fixed passage.'), findsOneWidget);
    expect(find.textContaining('B1: Canonical first block.'), findsOneWidget);
    expect(find.textContaining('connector · B2 → B1'), findsOneWidget);
  });

  testWidgets('one candidate can be selected', (tester) async {
    await _pump(tester, FakeOrderGateway());
    await _analyze(tester);
    await tester.tap(find.byKey(const Key('order-candidate-ORDER-CAND-1')));
    await tester.pump();
    final tile = tester.widget<RadioListTile<OrderCandidate>>(
      find.byType(RadioListTile<OrderCandidate>),
    );
    expect(tile.groupValue, same(tile.value));
  });

  testWidgets('generate button follows candidate selection state', (
    tester,
  ) async {
    await _pump(tester, FakeOrderGateway());
    await _analyze(tester);
    expect(_button(tester, 'order-generate-button').onPressed, isNull);
    await tester.tap(find.byKey(const Key('order-candidate-ORDER-CAND-1')));
    await tester.pump();
    expect(_button(tester, 'order-generate-button').onPressed, isNotNull);
  });

  testWidgets('generated preview uses direct A plus B C D product blocks', (
    tester,
  ) async {
    await _pump(tester, FakeOrderGateway());
    await _generate(tester);
    expect(find.byKey(const Key('order-generated-preview')), findsOneWidget);
    expect(find.text('(A) Intro fixed passage.'), findsOneWidget);
    expect(find.text('(B) Canonical first block.'), findsOneWidget);
    expect(find.text('(C) Canonical second block.'), findsOneWidget);
    expect(find.text('(D) Canonical third block.'), findsOneWidget);
    expect(find.textContaining('①'), findsNothing);
  });

  testWidgets('generated preview shows persistence-label answer sequence', (
    tester,
  ) async {
    await _pump(tester, FakeOrderGateway());
    await _generate(tester);
    expect(find.text('정답 순서: C → B → D'), findsOneWidget);
  });

  testWidgets('generated preview shows explanation', (tester) async {
    await _pump(tester, FakeOrderGateway());
    await _generate(tester);
    expect(find.text('해설: B2가 B1보다 먼저 오고 B3가 마지막입니다.'), findsOneWidget);
  });

  testWidgets('no-candidate response shows precision-first message', (
    tester,
  ) async {
    await _pump(tester, FakeOrderGateway(noCandidates: true));
    await _analyze(tester);
    expect(find.byKey(const Key('order-no-candidate-state')), findsOneWidget);
    expect(
      find.text('이 지문에서는 의미상 순서가 하나로 확정되는 안전한 순서 문제 후보를 찾지 못했습니다.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('order-generate-button')), findsNothing);
  });

  testWidgets('single-answer validation failure shows safe rejection', (
    tester,
  ) async {
    await _pump(tester, FakeOrderGateway(failValidation: true));
    await _generate(tester);
    expect(find.byKey(const Key('order-error-state')), findsOneWidget);
    expect(find.textContaining('순서가 하나로 확정되지 않아'), findsOneWidget);
    expect(find.byKey(const Key('order-generated-preview')), findsNothing);
  });

  testWidgets('save succeeds with generated object and entered passage', (
    tester,
  ) async {
    final gateway = FakeOrderGateway();
    await _pump(tester, gateway);
    await _generate(tester);
    final save = find.byKey(const Key('order-save-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(gateway.savedName, 'Semantic Order 문제');
    expect(gateway.savedPassage, 'A sufficiently long English passage.');
    expect(gateway.savedQuestion, same(gateway.generated));
    expect(find.text('문제세트 저장 완료: #205'), findsOneWidget);
  });

  testWidgets('question maker always shows body navigation card', (
    tester,
  ) async {
    await _pumpQuestionMaker(tester);
    expect(find.text('AI Semantic 순서'), findsOneWidget);
    expect(
      find.byKey(const Key('semantic-order-entry-button')),
      findsOneWidget,
    );
  });

  testWidgets('question maker stacked layout renders without exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: TeacherQuestionMakerScreen()),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('semantic-order-entry-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('body navigation opens Semantic Order screen', (tester) async {
    await _pumpQuestionMaker(tester);
    final entry = find.byKey(const Key('semantic-order-entry-button'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(TeacherSemanticOrderScreen), findsOneWidget);
  });

  testWidgets('back navigation returns to question maker', (tester) async {
    await _pumpQuestionMaker(tester);
    final entry = find.byKey(const Key('semantic-order-entry-button'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TeacherQuestionMakerScreen), findsOneWidget);
    expect(
      find.byKey(const Key('semantic-order-entry-button')),
      findsOneWidget,
    );
  });

  testWidgets('non-teacher direct route is blocked', (tester) async {
    AuthStore.saveLogin(accessTokenValue: 'student', roleValue: 'student');
    await _pump(tester, FakeOrderGateway());
    expect(find.text('교사 계정으로 로그인해 주세요.'), findsOneWidget);
    expect(find.byKey(const Key('order-passage-input')), findsNothing);
  });
}

FilledButton _button(WidgetTester tester, String key) =>
    tester.widget<FilledButton>(find.byKey(Key(key)));

Future<void> _pump(WidgetTester tester, FakeOrderGateway gateway) async {
  tester.view.physicalSize = const Size(1000, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherSemanticOrderScreen(
        gateway: gateway,
        openPreviewAfterSave: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpQuestionMaker(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    const MaterialApp(home: TeacherQuestionMakerScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> _analyze(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('order-passage-input')),
    'A sufficiently long English passage.',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('order-analyze-button')));
  await tester.pumpAndSettle();
}

Future<void> _generate(WidgetTester tester) async {
  await _analyze(tester);
  await tester.tap(find.byKey(const Key('order-candidate-ORDER-CAND-1')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('order-generate-button')));
  await tester.pumpAndSettle();
}

class FakeOrderGateway implements OrderGenerationGateway {
  FakeOrderGateway({this.noCandidates = false, this.failValidation = false});

  final bool noCandidates;
  final bool failValidation;
  String? savedName;
  String? savedPassage;
  OrderGeneratedQuestion? savedQuestion;

  final candidateResult = OrderCandidatesResult.fromJson({
    'data': {
      'candidates': [_candidateJson()],
      'selected_target': _targetJson(),
      'metadata': {'reason_code': null},
    },
  });

  late final generated = OrderGeneratedQuestion.fromJson(_generatedResponse());

  @override
  Future<JsonMap> analyzePassage(String passage) async => {
        'semantic_id': 'SEM-ORDER-1',
        'sentences': [
          {'sentence_id': 'S1', 'text': 'Intro fixed passage.'},
          {'sentence_id': 'S2', 'text': 'Canonical first block.'},
          {'sentence_id': 'S3', 'text': 'Canonical second block.'},
          {'sentence_id': 'S4', 'text': 'Canonical third block.'},
        ],
      };

  @override
  Future<OrderCandidatesResult> fetchCandidates({
    required JsonMap semantic,
  }) async {
    if (noCandidates) {
      return const OrderCandidatesResult(
        candidates: [],
        selectedTarget: null,
        reasonCode: 'ORDER_NO_CANDIDATE',
      );
    }
    return candidateResult;
  }

  @override
  Future<OrderGeneratedQuestion> generate({
    required JsonMap semantic,
    required OrderGenerationTarget target,
  }) async {
    if (failValidation) {
      throw const OrderGenerationException(
        code: 'ORDER_SINGLE_ANSWER_VALIDATION_FAILED',
        message: 'ambiguous',
        statusCode: 422,
      );
    }
    return generated;
  }

  @override
  Future<OrderSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required OrderGeneratedQuestion question,
  }) async {
    savedName = name;
    savedPassage = passage;
    savedQuestion = question;
    return const OrderSaveResult(problemSetId: 205, savedQuestionCount: 1);
  }
}

Map<String, dynamic> _candidateJson() => {
      'candidate_id': 'ORDER-CAND-1',
      'fixed_intro_sentence_ids': ['S1'],
      'blocks': [
        _candidateBlock('B1', 'S2', 'Canonical first block.'),
        _candidateBlock('B2', 'S3', 'Canonical second block.'),
        _candidateBlock('B3', 'S4', 'Canonical third block.'),
      ],
      'correct_order': ['B2', 'B1', 'B3'],
      'evidence': [
        {
          'before': 'B2',
          'after': 'B1',
          'evidence_type': 'connector',
          'cue': 'Therefore',
        },
      ],
      'suitability': {
        'score': 0.88,
        'level': 'high',
        'reasons': ['Strong connector evidence'],
      },
    };

Map<String, dynamic> _targetJson() => {
      'target_id': 'ORDER-TARGET-1',
      'candidate_id': 'ORDER-CAND-1',
      'question_mode': 'three_block_order',
      'fixed_intro_sentence_ids': ['S1'],
      'blocks': [
        _candidateBlock('B1', 'S2', 'Canonical first block.'),
        _candidateBlock('B2', 'S3', 'Canonical second block.'),
        _candidateBlock('B3', 'S4', 'Canonical third block.'),
      ],
      'correct_order': ['B2', 'B1', 'B3'],
      'selection_score': 0.88,
      'difficulty': 'medium',
    };

Map<String, dynamic> _candidateBlock(
  String id,
  String sentenceId,
  String text,
) =>
    {
      'block_id': id,
      'sentence_ids': [sentenceId],
      'text_preview': text,
    };

Map<String, dynamic> _generatedResponse() => {
      'data': {
        'question_id': 'ORDER-1',
        'fixed_intro': {'text': 'Intro fixed passage.'},
        'blocks': [
          _generatedBlock('B1', 'C', 'Canonical first block.'),
          _generatedBlock('B2', 'A', 'Canonical second block.'),
          _generatedBlock('B3', 'B', 'Canonical third block.'),
        ],
        'stem': {'ko': '주어진 글 다음에 이어질 글의 순서를 정하세요.'},
        'correct_sequence': ['A', 'C', 'B'],
        'explanation': {'ko': 'B2가 B1보다 먼저 오고 B3가 마지막입니다.'},
        'validation': {
          'valid_orders': [
            ['B2', 'B1', 'B3'],
          ],
        },
      },
    };

Map<String, dynamic> _generatedBlock(String id, String label, String text) => {
      'block_id': id,
      'display_label': label,
      'sentence_ids': ['S2'],
      'text': text,
    };
