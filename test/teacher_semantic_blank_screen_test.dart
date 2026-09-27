import 'dart:async';

import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:english_analyzer_app/models/blank_generation_models.dart';
import 'package:english_analyzer_app/screens/teacher/teacher_semantic_blank_screen.dart';
import 'package:english_analyzer_app/screens/teacher_question_maker_screen.dart';
import 'package:english_analyzer_app/services/blank_generation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AuthStore.saveLogin(
      accessTokenValue: 'teacher-blank-token',
      roleValue: 'teacher',
    );
  });
  tearDown(AuthStore.clear);

  testWidgets('shows product title and empty analysis is disabled', (
    tester,
  ) async {
    await _pump(tester, FakeBlankGateway());
    expect(find.text('Semantic 빈칸 만들기'), findsOneWidget);
    expect(find.byKey(const Key('blank-passage-input')), findsOneWidget);
    expect(_button(tester, 'blank-analyze-button').onPressed, isNull);
  });

  testWidgets('passage input enables analysis', (tester) async {
    await _pump(tester, FakeBlankGateway());
    await _enterPassage(tester);
    expect(_button(tester, 'blank-analyze-button').onPressed, isNotNull);
  });

  testWidgets(
    'analysis displays candidate summaries without span coordinates',
    (tester) async {
      await _pump(tester, FakeBlankGateway());
      await _analyze(tester);
      expect(
        find.byKey(const Key('blank-candidate-summary-CAND-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('blank-candidate-summary-CAND-2')),
        findsOneWidget,
      );
      expect(find.textContaining('Clear semantic target'), findsWidgets);
      expect(find.textContaining('start_char'), findsNothing);
      expect(find.textContaining('end_char'), findsNothing);
    },
  );

  testWidgets('safe backend target can be selected for generation', (
    tester,
  ) async {
    await _pump(tester, FakeBlankGateway());
    await _selectCandidate(tester);
    expect(_button(tester, 'blank-generate-button').onPressed, isNotNull);
  });

  testWidgets('generated preview has exactly five product choices', (
    tester,
  ) async {
    await _pump(tester, FakeBlankGateway());
    await _generate(tester);
    for (var position = 1; position <= 5; position++) {
      expect(find.byKey(Key('blank-preview-choice-$position')), findsOneWidget);
    }
    expect(find.byKey(const Key('blank-preview-choice-6')), findsNothing);
  });

  testWidgets('answer and backend explanation are shown unchanged', (
    tester,
  ) async {
    await _pump(tester, FakeBlankGateway());
    await _generate(tester);
    expect(find.text('정답: ③'), findsOneWidget);
    expect(find.text('해설: ③만 원문의 의미를 유지합니다.'), findsOneWidget);
  });

  testWidgets('teacher preview preserves exact backend blanked text', (
    tester,
  ) async {
    await _pump(tester, FakeBlankGateway());
    await _generate(tester);
    expect(find.text(_blankedPassage), findsOneWidget);
    expect(find.text(_firstOccurrenceBlanked), findsNothing);
  });

  testWidgets('save uses analyzed source and raw generated question', (
    tester,
  ) async {
    final gateway = FakeBlankGateway();
    await _pump(tester, gateway);
    await _generate(tester);
    final save = find.byKey(const Key('blank-save-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(gateway.savedPassage, _sourcePassage);
    expect(gateway.savedQuestion?.raw, gateway.generated.raw);
    expect(find.textContaining('문제세트 저장 완료'), findsOneWidget);
  });

  testWidgets('no-candidate state never invents a fallback', (tester) async {
    await _pump(tester, FakeBlankGateway(noCandidate: true));
    await _analyze(tester);
    expect(find.text('안전한 빈칸 문제 후보를 찾지 못했습니다.'), findsOneWidget);
    expect(find.byKey(const Key('blank-generate-button')), findsNothing);
  });

  testWidgets('backend rejection stops without legacy local generation', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeBlankGateway(failCode: 'BLANK_SINGLE_ANSWER_VALIDATION_FAILED'),
    );
    await _selectCandidate(tester);
    final generate = find.byKey(const Key('blank-generate-button'));
    await tester.ensureVisible(generate);
    await tester.tap(generate);
    await tester.pumpAndSettle();
    expect(find.textContaining('생성을 중단했습니다'), findsOneWidget);
    expect(find.byKey(const Key('blank-generated-preview')), findsNothing);
  });

  testWidgets('network failure shows safe error and no generated preview', (
    tester,
  ) async {
    await _pump(tester, FakeBlankGateway(networkFailure: true));
    await _analyze(tester);
    expect(find.textContaining('네트워크 상태를 확인'), findsOneWidget);
    expect(find.byKey(const Key('blank-generated-preview')), findsNothing);
  });

  testWidgets('busy analysis preserves the entered passage', (tester) async {
    final gateway = FakeBlankGateway(pauseAnalysis: true);
    await _pump(tester, gateway);
    await _enterPassage(tester);
    await tester.tap(find.byKey(const Key('blank-analyze-button')));
    await tester.pump();
    expect(_passageText(tester), _sourcePassage);
    gateway.analysisCompleter.complete(_semanticJson());
    await tester.pumpAndSettle();
    expect(_passageText(tester), _sourcePassage);
  });

  testWidgets('question maker always shows semantic blank body card', (
    tester,
  ) async {
    await _pumpQuestionMaker(tester);
    expect(find.text('AI Semantic 빈칸'), findsOneWidget);
    expect(
      find.byKey(const Key('semantic-blank-entry-button')),
      findsOneWidget,
    );
  });

  testWidgets('question maker card navigates to semantic blank screen', (
    tester,
  ) async {
    await _pumpQuestionMaker(tester);
    final entry = find.byKey(const Key('semantic-blank-entry-button'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(TeacherSemanticBlankScreen), findsOneWidget);
  });

  testWidgets('question maker blank card remains visible at 320px', (
    tester,
  ) async {
    await _pumpQuestionMaker(tester, size: const Size(320, 1100));
    final entry = find.byKey(const Key('semantic-blank-entry-button'));
    await tester.ensureVisible(entry);
    expect(entry, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('five-choice preview remains usable at 320px', (tester) async {
    await _pump(tester, FakeBlankGateway(), size: const Size(320, 900));
    await _generate(tester);
    final fifth = find.byKey(const Key('blank-preview-choice-5'));
    await tester.ensureVisible(fifth);
    expect(fifth, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-teacher direct route is blocked', (tester) async {
    AuthStore.saveLogin(accessTokenValue: 'student', roleValue: 'student');
    await _pump(tester, FakeBlankGateway());
    expect(find.text('교사 계정으로 로그인해 주세요.'), findsOneWidget);
    expect(find.byKey(const Key('blank-passage-input')), findsNothing);
  });
}

const _sourcePassage =
    'the same phrase appears first, and the same phrase appears second.';
const _blankedPassage =
    'the same phrase appears first, and ________________________________ appears second.';
const _firstOccurrenceBlanked =
    '________________________________ appears first, and the same phrase appears second.';

FilledButton _button(WidgetTester tester, String key) =>
    tester.widget<FilledButton>(find.byKey(Key(key)));

String _passageText(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(const Key('blank-passage-input')))
    .controller!
    .text;

Future<void> _pump(
  WidgetTester tester,
  FakeBlankGateway gateway, {
  Size size = const Size(1000, 1800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherSemanticBlankScreen(
        gateway: gateway,
        openPreviewAfterSave: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpQuestionMaker(
  WidgetTester tester, {
  Size size = const Size(1000, 1800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    const MaterialApp(home: TeacherQuestionMakerScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterPassage(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('blank-passage-input')),
    _sourcePassage,
  );
  await tester.pump();
}

Future<void> _analyze(WidgetTester tester) async {
  await _enterPassage(tester);
  await tester.tap(find.byKey(const Key('blank-analyze-button')));
  await tester.pumpAndSettle();
}

Future<void> _selectCandidate(WidgetTester tester) async {
  await _analyze(tester);
  final candidate = find.byKey(const Key('blank-candidate-CAND-2'));
  await tester.ensureVisible(candidate);
  await tester.tap(candidate);
  await tester.pump();
}

Future<void> _generate(WidgetTester tester) async {
  await _selectCandidate(tester);
  final generate = find.byKey(const Key('blank-generate-button'));
  await tester.ensureVisible(generate);
  await tester.tap(generate);
  await tester.pumpAndSettle();
}

class FakeBlankGateway implements BlankGenerationGateway {
  FakeBlankGateway({
    this.noCandidate = false,
    this.pauseAnalysis = false,
    this.networkFailure = false,
    this.failCode,
  });

  final bool noCandidate;
  final bool pauseAnalysis;
  final bool networkFailure;
  final String? failCode;
  final analysisCompleter = Completer<JsonMap>();
  String? savedPassage;
  BlankGeneratedQuestion? savedQuestion;

  late final generated = BlankGeneratedQuestion.fromJson(_generatedResponse());

  @override
  Future<JsonMap> analyzePassage(String passage) {
    if (networkFailure) throw Exception('offline');
    return pauseAnalysis
        ? analysisCompleter.future
        : Future.value(_semanticJson());
  }

  @override
  Future<BlankCandidatesResult> fetchCandidates({
    required JsonMap semantic,
  }) async {
    final response = _candidateResponse();
    if (noCandidate) {
      (response['data'] as Map<String, dynamic>)['selected_target'] = null;
    }
    return BlankCandidatesResult.fromJson(response);
  }

  @override
  Future<BlankGeneratedQuestion> generate({
    required JsonMap semantic,
    required BlankGenerationTarget target,
  }) async {
    if (failCode != null) {
      throw BlankGenerationException(
        code: failCode!,
        message: 'unsafe generated question',
        statusCode: 502,
      );
    }
    return generated;
  }

  @override
  Future<BlankSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required BlankGeneratedQuestion question,
  }) async {
    savedPassage = passage;
    savedQuestion = question;
    return const BlankSaveResult(problemSetId: 526, savedQuestionCount: 1);
  }
}

JsonMap _semanticJson() => {
  'semantic_id': 'SEM-BLANK-1',
  'sentences': const [
    {'sentence_id': 'S1', 'text': 'First sentence.'},
    {'sentence_id': 'S2', 'text': 'Second sentence.'},
  ],
};

JsonMap _candidate(String id, String text, double score) => {
  'candidate_id': id,
  'semantic_id': 'SEM-BLANK-1',
  'sentence_id': id == 'CAND-1' ? 'S1' : 'S2',
  'span': {'start_char': 10, 'end_char': 20, 'text': text},
  'text': text,
  'blank_type': 'phrase',
  'semantic_role': 'main_claim',
  'evidence': const [],
  'suitability': {
    'score': score,
    'level': 'high',
    'reasons': ['Clear semantic target'],
  },
};

JsonMap _targetJson() => {
  'target_id': 'TARGET-1',
  'candidate_id': 'CAND-2',
  'question_mode': 'blank_inference',
  'sentence_id': 'S2',
  'span': {'start_char': 37, 'end_char': 52, 'text': 'the same phrase'},
  'text': 'the same phrase',
  'blank_type': 'phrase',
  'semantic_role': 'main_claim',
  'selection_score': 0.94,
  'evidence_summary': const [],
};

JsonMap _candidateResponse() => <String, dynamic>{
  'status': 'success',
  'data': <String, dynamic>{
    'candidates': [
      _candidate('CAND-1', 'appears first', 0.82),
      _candidate('CAND-2', 'the same phrase', 0.94),
    ],
    'selected_target': _targetJson(),
    'metadata': {
      'total_extracted': 2,
      'eligible_candidates': 2,
      'question_mode': 'blank_inference',
    },
  },
};

JsonMap _generatedResponse() => {
  'status': 'success',
  'data': {
    'question_id': 'BLANK-Q-1',
    'question_type': 'blank',
    'question_mode': 'blank_inference',
    'stem': {'ko': '다음 빈칸에 들어갈 말로 가장 적절한 것을 고르시오.'},
    'passage': {'blanked_text': _blankedPassage},
    'blank': {
      'candidate_id': 'CAND-2',
      'sentence_id': 'S2',
      'original_text': 'the same phrase',
      'span': {'start_char': 37, 'end_char': 52, 'text': 'the same phrase'},
    },
    'choices': List.generate(5, (index) {
      final no = index + 1;
      return {
        'choice_no': no,
        'text': 'Choice $no',
        'is_correct': no == 3,
        'mutation_type': no == 3 ? 'equivalent_paraphrase' : 'scope_change',
        'validation': {
          'truth': no == 3 ? 'entailed' : 'unsupported',
          'scope': no == 3 ? 'matched' : 'too_broad',
          'context_fit': no == 3 ? 'strong' : 'weak',
        },
      };
    }),
    'answer': 3,
    'explanation': {'ko': '③만 원문의 의미를 유지합니다.'},
    'validation': {'single_answer': true, 'judge_passed': true},
    'judge_result': {'overall_valid': true},
    'metadata': {'generator_version': '1.1'},
  },
};
