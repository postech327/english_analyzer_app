import 'dart:async';

import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:english_analyzer_app/models/insertion_generation_models.dart';
import 'package:english_analyzer_app/screens/teacher/teacher_semantic_insertion_screen.dart';
import 'package:english_analyzer_app/screens/teacher_question_maker_screen.dart';
import 'package:english_analyzer_app/services/insertion_generation_service.dart';
import 'package:english_analyzer_app/widgets/special_question_interaction_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AuthStore.saveLogin(accessTokenValue: 'token', roleValue: 'teacher');
  });
  tearDown(AuthStore.clear);

  testWidgets('screen renders for a teacher', (tester) async {
    await _pump(tester, FakeInsertionGateway());
    expect(find.byType(TeacherSemanticInsertionScreen), findsOneWidget);
    expect(find.text('Semantic 문장 삽입 만들기'), findsOneWidget);
    expect(find.byKey(const Key('insertion-passage-input')), findsOneWidget);
  });

  testWidgets('empty passage disables analysis', (tester) async {
    await _pump(tester, FakeInsertionGateway());
    expect(_button(tester, 'insertion-analyze-button').onPressed, isNull);
  });

  testWidgets('passage input enables analysis', (tester) async {
    await _pump(tester, FakeInsertionGateway());
    await tester.enterText(
      find.byKey(const Key('insertion-passage-input')),
      'A sufficiently long English passage.',
    );
    await tester.pump();
    expect(_button(tester, 'insertion-analyze-button').onPressed, isNotNull);
  });

  testWidgets('analysis exposes loading state', (tester) async {
    final gateway = FakeInsertionGateway(pauseAnalysis: true);
    await _pump(tester, gateway);
    await tester.enterText(
      find.byKey(const Key('insertion-passage-input')),
      'A sufficiently long English passage.',
    );
    await tester.pump();
    _button(tester, 'insertion-analyze-button').onPressed!();
    await tester.pump();
    expect(_button(tester, 'insertion-analyze-button').onPressed, isNull);
    gateway.analysisCompleter.complete(_semanticJson());
    await tester.pumpAndSettle();
  });

  testWidgets('candidate shows sentence suitability and evidence', (
    tester,
  ) async {
    await _pump(tester, FakeInsertionGateway());
    await _analyze(tester);
    expect(
      find.byKey(const Key('insertion-candidate-INS-CAND-1')),
      findsOneWidget,
    );
    expect(find.textContaining('안전도 91%'), findsOneWidget);
    expect(find.textContaining('Target sentence.'), findsOneWidget);
    expect(find.textContaining('referential · S2 → S3'), findsOneWidget);
  });

  testWidgets('one candidate can be selected', (tester) async {
    await _pump(tester, FakeInsertionGateway());
    await _analyze(tester);
    await tester.tap(find.byKey(const Key('insertion-candidate-INS-CAND-1')));
    await tester.pump();
    final tile = tester.widget<RadioListTile<InsertionCandidate>>(
      find.byType(RadioListTile<InsertionCandidate>),
    );
    expect(tile.groupValue, same(tile.value));
  });

  testWidgets('generate button follows selection state', (tester) async {
    await _pump(tester, FakeInsertionGateway());
    await _analyze(tester);
    expect(_button(tester, 'insertion-generate-button').onPressed, isNull);
    await tester.tap(find.byKey(const Key('insertion-candidate-INS-CAND-1')));
    await tester.pump();
    expect(_button(tester, 'insertion-generate-button').onPressed, isNotNull);
  });

  testWidgets('preview shows given sentence', (tester) async {
    await _pump(tester, FakeInsertionGateway());
    await _generate(tester);
    expect(find.text('주어진 문장'), findsOneWidget);
    expect(find.text('Target sentence.'), findsWidgets);
  });

  testWidgets('preview uses product passage with each marker once', (
    tester,
  ) async {
    await _pump(tester, FakeInsertionGateway());
    await _generate(tester);
    final view = tester.widget<InsertionPassageView>(
      find.byType(InsertionPassageView),
    );
    for (final marker in const ['①', '②', '③', '④', '⑤']) {
      expect(marker.allMatches(view.passage), hasLength(1));
    }
  });

  testWidgets('preview shows correct position', (tester) async {
    await _pump(tester, FakeInsertionGateway());
    await _generate(tester);
    expect(find.text('정답 위치: 3'), findsOneWidget);
  });

  testWidgets('preview shows explanation without judge JSON', (tester) async {
    await _pump(tester, FakeInsertionGateway());
    await _generate(tester);
    expect(find.textContaining('This result가 앞 문장을 받아'), findsOneWidget);
    expect(find.textContaining('judge_result'), findsNothing);
  });

  testWidgets('no-candidate response shows safe message', (tester) async {
    await _pump(tester, FakeInsertionGateway(noCandidates: true));
    await _analyze(tester);
    expect(
      find.byKey(const Key('insertion-no-candidate-state')),
      findsOneWidget,
    );
    expect(find.textContaining('안전한 문항 후보를 찾지 못했습니다'), findsOneWidget);
    expect(find.byKey(const Key('insertion-generate-button')), findsNothing);
  });

  testWidgets('validation failure safely rejects generation', (tester) async {
    await _pump(tester, FakeInsertionGateway(failValidation: true));
    await _generate(tester);
    expect(find.byKey(const Key('insertion-error-state')), findsOneWidget);
    expect(find.textContaining('삽입 위치가 하나로 확정되지 않아'), findsOneWidget);
    expect(find.byKey(const Key('insertion-generated-preview')), findsNothing);
  });

  testWidgets('save succeeds with raw generated object and passage', (
    tester,
  ) async {
    final gateway = FakeInsertionGateway();
    await _pump(tester, gateway);
    await _generate(tester);
    final save = find.byKey(const Key('insertion-save-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(gateway.savedName, 'Semantic Insertion 문제');
    expect(gateway.savedPassage, 'A sufficiently long English passage.');
    expect(gateway.savedQuestion, same(gateway.generated));
    expect(find.text('문제세트 저장 완료: #306'), findsOneWidget);
  });

  testWidgets('question maker always shows insertion body card', (
    tester,
  ) async {
    await _pumpQuestionMaker(tester);
    expect(find.text('AI Semantic 문장 삽입'), findsOneWidget);
    expect(
      find.byKey(const Key('semantic-insertion-entry-button')),
      findsOneWidget,
    );
  });

  testWidgets('body navigation opens insertion screen', (tester) async {
    await _pumpQuestionMaker(tester);
    final entry = find.byKey(const Key('semantic-insertion-entry-button'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(TeacherSemanticInsertionScreen), findsOneWidget);
  });

  testWidgets('320px layout is visible without overflow or blank screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: TeacherQuestionMakerScreen()),
    );
    await tester.pumpAndSettle();
    final entry = find.byKey(const Key('semantic-insertion-entry-button'));
    expect(entry, findsOneWidget);
    await tester.ensureVisible(entry);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back navigation returns to question maker', (tester) async {
    await _pumpQuestionMaker(tester);
    final entry = find.byKey(const Key('semantic-insertion-entry-button'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TeacherQuestionMakerScreen), findsOneWidget);
    expect(entry, findsOneWidget);
  });

  testWidgets('non-teacher direct route is blocked', (tester) async {
    AuthStore.saveLogin(accessTokenValue: 'student', roleValue: 'student');
    await _pump(tester, FakeInsertionGateway());
    expect(find.text('교사 계정으로 로그인해 주세요.'), findsOneWidget);
    expect(find.byKey(const Key('insertion-passage-input')), findsNothing);
  });
}

FilledButton _button(WidgetTester tester, String key) =>
    tester.widget<FilledButton>(find.byKey(Key(key)));

Future<void> _pump(WidgetTester tester, FakeInsertionGateway gateway) async {
  tester.view.physicalSize = const Size(1000, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherSemanticInsertionScreen(
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
    find.byKey(const Key('insertion-passage-input')),
    'A sufficiently long English passage.',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('insertion-analyze-button')));
  await tester.pumpAndSettle();
}

Future<void> _generate(WidgetTester tester) async {
  await _analyze(tester);
  await tester.tap(find.byKey(const Key('insertion-candidate-INS-CAND-1')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('insertion-generate-button')));
  await tester.pumpAndSettle();
}

class FakeInsertionGateway implements InsertionGenerationGateway {
  FakeInsertionGateway({
    this.noCandidates = false,
    this.failValidation = false,
    this.pauseAnalysis = false,
  });

  final bool noCandidates;
  final bool failValidation;
  final bool pauseAnalysis;
  final analysisCompleter = Completer<JsonMap>();
  String? savedName;
  String? savedPassage;
  InsertionGeneratedQuestion? savedQuestion;

  final candidateResult = InsertionCandidatesResult.fromJson({
    'data': {
      'candidates': [_candidateJson()],
      'selected_target': _targetJson(),
      'metadata': {'reason_code': null},
    },
  });

  late final generated = InsertionGeneratedQuestion.fromJson(
    _generatedResponse(),
  );

  @override
  Future<JsonMap> analyzePassage(String passage) =>
      pauseAnalysis ? analysisCompleter.future : Future.value(_semanticJson());

  @override
  Future<InsertionCandidatesResult> fetchCandidates({
    required JsonMap semantic,
  }) async {
    if (noCandidates) {
      return const InsertionCandidatesResult(
        candidates: [],
        selectedTarget: null,
        reasonCode: 'INSERTION_NO_CANDIDATE',
      );
    }
    return candidateResult;
  }

  @override
  Future<InsertionGeneratedQuestion> generate({
    required JsonMap semantic,
    required InsertionGenerationTarget target,
  }) async {
    if (failValidation) {
      throw const InsertionGenerationException(
        code: 'INSERTION_SINGLE_ANSWER_VALIDATION_FAILED',
        message: 'ambiguous',
        statusCode: 422,
      );
    }
    return generated;
  }

  @override
  Future<InsertionSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required InsertionGeneratedQuestion question,
  }) async {
    savedName = name;
    savedPassage = passage;
    savedQuestion = question;
    return const InsertionSaveResult(problemSetId: 306, savedQuestionCount: 1);
  }
}

JsonMap _semanticJson() => {
      'semantic_id': 'SEM-INS-1',
      'sentences': [
        {'sentence_id': 'S1', 'text': 'First sentence.'},
        {'sentence_id': 'S2', 'text': 'Second sentence.'},
        {'sentence_id': 'S3', 'text': 'Target sentence.'},
        {'sentence_id': 'S4', 'text': 'Fourth sentence.'},
        {'sentence_id': 'S5', 'text': 'Fifth sentence.'},
      ],
    };

JsonMap _candidateJson() => {
      'candidate_id': 'INS-CAND-1',
      'inserted_sentence': {
        'sentence_id': 'S3',
        'index': 2,
        'text': 'Target sentence.',
      },
      'correct_gap_id': 'G3',
      'gap_scores': [
        {
          'gap_id': 'G3',
          'evidence': [
            {
              'evidence_type': 'referential',
              'sentence_ids': ['S2', 'S3'],
              'cue': 'This result',
            },
          ],
        },
      ],
      'suitability': {
        'score': 0.91,
        'level': 'high',
        'reasons': ['Unique reference chain'],
      },
    };

JsonMap _targetJson() => {
      'target_id': 'INS-TARGET-1',
      'candidate_id': 'INS-CAND-1',
      'question_mode': 'sentence_insertion',
      'inserted_sentence': {
        'sentence_id': 'S3',
        'index': 2,
        'text': 'Target sentence.',
      },
      'remaining_sentence_ids': ['S1', 'S2', 'S4', 'S5'],
      'correct_gap_id': 'G3',
      'selection_score': 0.91,
      'difficulty': 'medium',
      'evidence_summary': [
        {
          'evidence_type': 'referential',
          'sentence_ids': ['S2', 'S3'],
          'cue': 'This result',
        },
      ],
    };

JsonMap _generatedResponse() => {
      'data': {
        'question_id': 'INS-1',
        'inserted_sentence': {'text': 'Target sentence.'},
        'stem': {'ko': '주어진 문장이 들어가기에 가장 적절한 곳을 고르시오.'},
        'display_passage': {
          'segments': [
            {
              'sentence_id': 'S1',
              'text': 'First sentence.',
              'marker_before': 1
            },
            {
              'sentence_id': 'S2',
              'text': 'Second sentence.',
              'marker_before': 2
            },
            {
              'sentence_id': 'S4',
              'text': 'Fourth sentence.',
              'marker_before': 3
            },
            {
              'sentence_id': 'S5',
              'text': 'Fifth sentence.',
              'marker_before': 4
            },
          ],
          'trailing_marker': 5,
        },
        'answer': 3,
        'explanation': {'ko': 'This result가 앞 문장을 받아 세 번째 위치가 적절합니다.'},
        'judge_result': {'overall_valid': true},
      },
    };
