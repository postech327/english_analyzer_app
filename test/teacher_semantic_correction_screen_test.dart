import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:english_analyzer_app/models/correction_generation_models.dart';
import 'package:english_analyzer_app/screens/teacher/teacher_semantic_correction_screen.dart';
import 'package:english_analyzer_app/screens/teacher_question_maker_screen.dart';
import 'package:english_analyzer_app/services/correction_generation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AuthStore.saveLogin(accessTokenValue: 'token', roleValue: 'teacher');
  });
  tearDown(AuthStore.clear);

  testWidgets('passage input renders and analyze is disabled when empty', (
    tester,
  ) async {
    await _pump(tester, FakeCorrectionGateway());
    expect(find.byKey(const Key('correction-passage-input')), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('correction-analyze-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('question maker body entry opens correction screen and returns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: TeacherQuestionMakerScreen()),
    );

    final entry = find.byKey(const Key('semantic-correction-entry-button'));
    expect(entry, findsOneWidget);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(TeacherSemanticCorrectionScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TeacherQuestionMakerScreen), findsOneWidget);
    expect(entry, findsOneWidget);
  });

  testWidgets('candidates render, select, and enable generation', (
    tester,
  ) async {
    await _pump(tester, FakeCorrectionGateway());
    await _analyze(tester);
    expect(find.textContaining('관계 반전'), findsOneWidget);
    expect(find.text('Second sentence.'), findsOneWidget);
    expect(find.text('because → although'), findsOneWidget);

    var generate = tester.widget<FilledButton>(
      find.byKey(const Key('correction-generate-button')),
    );
    expect(generate.onPressed, isNull);
    await tester.tap(find.textContaining('관계 반전'));
    await tester.pump();
    generate = tester.widget<FilledButton>(
      find.byKey(const Key('correction-generate-button')),
    );
    expect(generate.onPressed, isNotNull);
  });

  testWidgets(
    'generated correction preview shows passage answer and explanation',
    (tester) async {
      await _pump(tester, FakeCorrectionGateway());
      await _analyze(tester);
      await tester.tap(find.textContaining('관계 반전'));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('correction-generate-button')),
      );
      await tester.tap(find.byKey(const Key('correction-generate-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('correction-generated-preview')),
        findsOneWidget,
      );
      expect(find.text('정답: 4:However'), findsOneWidget);
      expect(find.textContaining('대조 관계이므로'), findsOneWidget);
      expect(find.textContaining('④Therefore'), findsOneWidget);
    },
  );

  testWidgets('no-candidate state is natural and does not forge a question', (
    tester,
  ) async {
    await _pump(tester, FakeCorrectionGateway(noCandidates: true));
    await _analyze(tester);
    expect(find.textContaining('안전하게 만들 수 있는 어법·문맥 고치기 후보'), findsOneWidget);
    expect(find.byKey(const Key('correction-generated-preview')), findsNothing);
  });

  testWidgets('generation failure asks teacher to choose another candidate', (
    tester,
  ) async {
    await _pump(tester, FakeCorrectionGateway(failGeneration: true));
    await _analyze(tester);
    await tester.tap(find.textContaining('관계 반전'));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('correction-generate-button')),
    );
    await tester.tap(find.byKey(const Key('correction-generate-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('다른 후보를 선택해 주세요'), findsOneWidget);
  });

  testWidgets('save action passes backend generated object unchanged', (
    tester,
  ) async {
    final gateway = FakeCorrectionGateway();
    await _pump(tester, gateway);
    await _analyze(tester);
    await tester.tap(find.textContaining('관계 반전'));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('correction-generate-button')),
    );
    await tester.tap(find.byKey(const Key('correction-generate-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('correction-save-button')));
    await tester.tap(find.byKey(const Key('correction-save-button')));
    await tester.pumpAndSettle();

    expect(gateway.savedName, 'Semantic Correction 문제');
    expect(gateway.savedPassage, 'First sentence. Second sentence.');
    expect(gateway.savedQuestion, same(gateway.generated));
    expect(find.textContaining('문제세트 저장 완료'), findsOneWidget);
  });

  testWidgets('student role cannot access teacher generation UI', (
    tester,
  ) async {
    AuthStore.role = 'student';
    await _pump(tester, FakeCorrectionGateway());
    expect(find.text('교사 계정으로 로그인해 주세요.'), findsOneWidget);
    expect(find.byKey(const Key('correction-passage-input')), findsNothing);
  });
}

Future<void> _pump(WidgetTester tester, FakeCorrectionGateway gateway) {
  tester.view.physicalSize = const Size(1000, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return tester.pumpWidget(
    MaterialApp(
      home: TeacherSemanticCorrectionScreen(
        gateway: gateway,
        openPreviewAfterSave: false,
      ),
    ),
  );
}

Future<void> _analyze(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('correction-passage-input')),
    'First sentence. Second sentence.',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('correction-analyze-button')));
  await tester.pumpAndSettle();
}

class FakeCorrectionGateway implements CorrectionGenerationGateway {
  FakeCorrectionGateway({
    this.noCandidates = false,
    this.failGeneration = false,
  });

  final bool noCandidates;
  final bool failGeneration;
  String? savedName;
  String? savedPassage;
  CorrectionGeneratedQuestion? savedQuestion;

  final candidate = CorrectionCandidate.fromJson({
    'candidate_id': 'CORR-S2-1',
    'target_sentence_id': 'S2',
    'target_sentence_index': 1,
    'original_text': 'because',
    'replacement_text': 'although',
    'corruption_family': 'relation_reversal',
    'candidate_score': 0.86,
    'semantic_invalidity_reason': '문장 간 의미 관계를 반대로 바꿉니다.',
    'difficulty_label': 'MEDIUM',
  });

  late final generated = CorrectionGeneratedQuestion.fromJson({
    'status': 'success',
    'data': {
      'question_id': 'CORRECTION-1',
      'stem': {'ko': '다음 글의 밑줄 친 부분 중 어색한 것을 고치시오.'},
      'original_passage': 'word1 word2 word3 However word5.',
      'corrupted_passage': 'word1 word2 word3 Therefore word5.',
      'markers': [
        _marker(1, '①', 0, 5, 'word1', 'word1'),
        _marker(2, '②', 6, 11, 'word2', 'word2'),
        _marker(3, '③', 12, 17, 'word3', 'word3'),
        _marker(4, '④', 18, 25, 'However', 'Therefore', corrupted: true),
        _marker(5, '⑤', 26, 31, 'word5', 'word5'),
      ],
      'answer': 4,
      'corruption': {'original_text': 'However'},
      'explanation': {'ko': '대조 관계이므로 However가 알맞습니다.'},
    },
  });

  @override
  Future<JsonMap> analyzePassage(String passage) async => {
        'semantic_id': 'SEM-1',
        'normalized_text': passage,
        'sentences': [
          {'sentence_id': 'S1', 'text': 'First sentence.'},
          {'sentence_id': 'S2', 'text': 'Second sentence.'},
        ],
      };

  @override
  Future<CorrectionCandidatesResult> fetchCandidates({
    required JsonMap semantic,
    int limit = 5,
  }) async {
    if (noCandidates) {
      throw const CorrectionGenerationException(
        code: 'CORRECTION_NO_CANDIDATE',
        message: 'none',
        statusCode: 422,
      );
    }
    return CorrectionCandidatesResult(
      candidates: [candidate],
      candidateCount: 1,
    );
  }

  @override
  Future<CorrectionGeneratedQuestion> generate({
    required JsonMap semantic,
    required CorrectionCandidate target,
  }) async {
    if (failGeneration) {
      throw const CorrectionGenerationException(
        code: 'CORRECTION_VALIDATION_FAILED',
        message: 'invalid',
        statusCode: 502,
      );
    }
    return generated;
  }

  @override
  Future<CorrectionSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required CorrectionGeneratedQuestion question,
  }) async {
    savedName = name;
    savedPassage = passage;
    savedQuestion = question;
    return const CorrectionSaveResult(problemSetId: 17, savedQuestionCount: 1);
  }
}

Map<String, dynamic> _marker(
  int position,
  String marker,
  int start,
  int end,
  String original,
  String display, {
  bool corrupted = false,
}) =>
    {
      'marker_position': position,
      'marker': marker,
      'start_char': start,
      'end_char': end,
      'display_text': display,
      'original_text': original,
      'is_corrupted': corrupted,
    };
