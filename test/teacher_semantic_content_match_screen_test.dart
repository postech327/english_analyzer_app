import 'dart:async';

import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:english_analyzer_app/models/content_match_generation_models.dart';
import 'package:english_analyzer_app/screens/teacher/teacher_semantic_content_match_screen.dart';
import 'package:english_analyzer_app/screens/teacher_question_maker_screen.dart';
import 'package:english_analyzer_app/services/content_match_generation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AuthStore.saveLogin(accessTokenValue: 'token', roleValue: 'teacher');
  });
  tearDown(AuthStore.clear);

  testWidgets('screen renders for a teacher', (tester) async {
    await _pump(tester, FakeContentMatchGateway());
    expect(find.byType(TeacherSemanticContentMatchScreen), findsOneWidget);
    expect(find.text('Semantic 내용 일치 만들기'), findsOneWidget);
    expect(
      find.byKey(const Key('content-match-passage-input')),
      findsOneWidget,
    );
  });

  testWidgets('empty passage disables analysis', (tester) async {
    await _pump(tester, FakeContentMatchGateway());
    expect(_button(tester, 'content-match-analyze-button').onPressed, isNull);
  });

  testWidgets('passage input enables analysis', (tester) async {
    await _pump(tester, FakeContentMatchGateway());
    await _enterPassage(tester);
    expect(
      _button(tester, 'content-match-analyze-button').onPressed,
      isNotNull,
    );
  });

  testWidgets('mode selector exposes both backend modes', (tester) async {
    await _pump(tester, FakeContentMatchGateway());
    await tester.tap(find.byKey(const Key('content-match-mode-selector')));
    await tester.pumpAndSettle();
    expect(find.text('내용과 일치하는 것 두 개'), findsWidgets);
    expect(find.text('내용과 일치하지 않는 것 두 개'), findsOneWidget);
  });

  testWidgets('analysis exposes loading state', (tester) async {
    final gateway = FakeContentMatchGateway(pauseAnalysis: true);
    await _pump(tester, gateway);
    await _enterPassage(tester);
    _button(tester, 'content-match-analyze-button').onPressed!();
    await tester.pump();
    expect(_button(tester, 'content-match-analyze-button').onPressed, isNull);
    gateway.analysisCompleter.complete(_semanticJson());
    await tester.pumpAndSettle();
  });

  testWidgets('backend selected target is shown as a candidate', (
    tester,
  ) async {
    await _pump(tester, FakeContentMatchGateway());
    await _analyze(tester);
    expect(
      find.byKey(const Key('content-match-candidate-CM-TARGET-1')),
      findsOneWidget,
    );
    expect(find.textContaining('안전도 90%'), findsOneWidget);
  });

  testWidgets('candidate shows semantic focus and evidence summary', (
    tester,
  ) async {
    await _pump(tester, FakeContentMatchGateway());
    await _analyze(tester);
    expect(find.textContaining('Animals adapt to change.'), findsOneWidget);
    expect(find.textContaining('sentence · S1'), findsOneWidget);
  });

  testWidgets('one candidate can be selected', (tester) async {
    await _pump(tester, FakeContentMatchGateway());
    await _selectCandidate(tester);
    final tile = tester.widget<RadioListTile<ContentMatchGenerationTarget>>(
      find.byType(RadioListTile<ContentMatchGenerationTarget>),
    );
    expect(tile.groupValue, same(tile.value));
  });

  testWidgets('generate is disabled before candidate selection', (
    tester,
  ) async {
    await _pump(tester, FakeContentMatchGateway());
    await _analyze(tester);
    expect(_button(tester, 'content-match-generate-button').onPressed, isNull);
  });

  testWidgets('generate is enabled after candidate selection', (tester) async {
    await _pump(tester, FakeContentMatchGateway());
    await _selectCandidate(tester);
    expect(
      _button(tester, 'content-match-generate-button').onPressed,
      isNotNull,
    );
  });

  testWidgets('generated preview renders exactly six choices', (tester) async {
    await _pump(tester, FakeContentMatchGateway());
    await _generate(tester);
    for (var position = 1; position <= 6; position++) {
      expect(
        find.byKey(Key('content-match-preview-choice-$position')),
        findsOneWidget,
      );
    }
  });

  testWidgets('sixth product choice is visible', (tester) async {
    await _pump(tester, FakeContentMatchGateway());
    await _generate(tester);
    final sixth = find.byKey(const Key('content-match-preview-choice-6'));
    await tester.ensureVisible(sixth);
    expect(find.textContaining('⑥ Further context'), findsOneWidget);
  });

  testWidgets('preview shows the backend exact-two answer', (tester) async {
    await _pump(tester, FakeContentMatchGateway());
    await _generate(tester);
    expect(find.text('정답: ②, ⑤'), findsOneWidget);
  });

  testWidgets('preview shows backend explanation without judge JSON', (
    tester,
  ) async {
    await _pump(tester, FakeContentMatchGateway());
    await _generate(tester);
    expect(find.textContaining('②와 ⑤만 지문의 의미와 일치'), findsOneWidget);
    expect(find.textContaining('judge_result'), findsNothing);
    expect(find.textContaining('entailed'), findsNothing);
  });

  testWidgets('preview identifies the two-selection interaction', (
    tester,
  ) async {
    await _pump(tester, FakeContentMatchGateway());
    await _generate(tester);
    expect(find.text('문제 유형: 내용 일치 · 2개 선택'), findsOneWidget);
  });

  testWidgets('no target shows safe no-candidate state without fallback', (
    tester,
  ) async {
    await _pump(tester, FakeContentMatchGateway(noCandidates: true));
    await _analyze(tester);
    expect(
      find.byKey(const Key('content-match-no-candidate-state')),
      findsOneWidget,
    );
    expect(find.textContaining('정답 2개와 명확한 오답 4개'), findsOneWidget);
    expect(
      find.byKey(const Key('content-match-generate-button')),
      findsNothing,
    );
  });

  testWidgets('exact-two semantic validation failure is safe', (tester) async {
    await _pump(
      tester,
      FakeContentMatchGateway(
        failCode: 'CONTENT_MATCH_SEMANTIC_VALIDATION_FAILED',
      ),
    );
    await _generate(tester);
    expect(find.textContaining('정답이 정확히 2개로 확정되지 않아'), findsOneWidget);
    expect(
      find.byKey(const Key('content-match-generated-preview')),
      findsNothing,
    );
  });

  testWidgets('judge disagreement uses a safe product message', (tester) async {
    await _pump(
      tester,
      FakeContentMatchGateway(
        failCode: 'CONTENT_MATCH_SEMANTIC_VALIDATION_FAILED',
        failMessage: 'CONTENT_MATCH_JUDGE_DISAGREEMENT',
      ),
    );
    await _generate(tester);
    expect(find.textContaining('정답 집합을 안전하게 확정할 수 없어'), findsOneWidget);
    expect(find.textContaining('JUDGE_DISAGREEMENT'), findsNothing);
  });

  testWidgets('network failure shows a friendly message', (tester) async {
    await _pump(tester, FakeContentMatchGateway(networkFailure: true));
    await _enterPassage(tester);
    await tester.tap(find.byKey(const Key('content-match-analyze-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('네트워크 상태를 확인'), findsOneWidget);
  });

  testWidgets('save keeps the raw generated object and passage', (
    tester,
  ) async {
    final gateway = FakeContentMatchGateway();
    await _pump(tester, gateway);
    await _generate(tester);
    final save = find.byKey(const Key('content-match-save-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(gateway.savedName, 'Semantic Content Match 문제');
    expect(gateway.savedPassage, _passage);
    expect(gateway.savedQuestion, same(gateway.generated));
    expect(find.text('문제세트 저장 완료: #421'), findsOneWidget);
  });

  testWidgets('question maker always shows the body entry card', (
    tester,
  ) async {
    await _pumpQuestionMaker(tester);
    expect(find.text('AI Semantic 내용 일치'), findsOneWidget);
    expect(
      find.byKey(const Key('semantic-content-match-entry-button')),
      findsOneWidget,
    );
  });

  testWidgets('body entry navigates to the semantic screen', (tester) async {
    await _pumpQuestionMaker(tester);
    final entry = find.byKey(const Key('semantic-content-match-entry-button'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(TeacherSemanticContentMatchScreen), findsOneWidget);
  });

  testWidgets('question maker card remains visible at 320px', (tester) async {
    await _pumpQuestionMaker(tester, size: const Size(320, 1100));
    final entry = find.byKey(const Key('semantic-content-match-entry-button'));
    await tester.ensureVisible(entry);
    expect(entry, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('six-choice preview remains usable at 320px', (tester) async {
    await _pump(tester, FakeContentMatchGateway(), size: const Size(320, 900));
    await _generate(tester);
    final sixth = find.byKey(const Key('content-match-preview-choice-6'));
    await tester.ensureVisible(sixth);
    expect(sixth, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-E leading characters are preserved in preview', (
    tester,
  ) async {
    await _pump(tester, FakeContentMatchGateway());
    await _generate(tester);
    for (final beginning in const [
      'Animals',
      'Economic',
      'Digital',
      'Communities',
      'Evidence',
    ]) {
      expect(find.textContaining(beginning), findsWidgets);
    }
  });

  testWidgets('non-teacher direct route is blocked', (tester) async {
    AuthStore.saveLogin(accessTokenValue: 'student', roleValue: 'student');
    await _pump(tester, FakeContentMatchGateway());
    expect(find.text('교사 계정으로 로그인해 주세요.'), findsOneWidget);
    expect(find.byKey(const Key('content-match-passage-input')), findsNothing);
  });
}

const _passage = 'A sufficiently long English passage for content matching.';

FilledButton _button(WidgetTester tester, String key) =>
    tester.widget<FilledButton>(find.byKey(Key(key)));

Future<void> _pump(
  WidgetTester tester,
  FakeContentMatchGateway gateway, {
  Size size = const Size(1000, 1700),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherSemanticContentMatchScreen(
        gateway: gateway,
        openPreviewAfterSave: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpQuestionMaker(
  WidgetTester tester, {
  Size size = const Size(1000, 1700),
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
    find.byKey(const Key('content-match-passage-input')),
    _passage,
  );
  await tester.pump();
}

Future<void> _analyze(WidgetTester tester) async {
  await _enterPassage(tester);
  await tester.tap(find.byKey(const Key('content-match-analyze-button')));
  await tester.pumpAndSettle();
}

Future<void> _selectCandidate(WidgetTester tester) async {
  await _analyze(tester);
  final candidate = find.byKey(
    const Key('content-match-candidate-CM-TARGET-1'),
  );
  await tester.ensureVisible(candidate);
  await tester.tap(candidate);
  await tester.pump();
}

Future<void> _generate(WidgetTester tester) async {
  await _selectCandidate(tester);
  final generate = find.byKey(const Key('content-match-generate-button'));
  await tester.ensureVisible(generate);
  await tester.tap(generate);
  await tester.pumpAndSettle();
}

class FakeContentMatchGateway implements ContentMatchGenerationGateway {
  FakeContentMatchGateway({
    this.noCandidates = false,
    this.pauseAnalysis = false,
    this.networkFailure = false,
    this.failCode,
    this.failMessage = 'unsafe generated question',
  });

  final bool noCandidates;
  final bool pauseAnalysis;
  final bool networkFailure;
  final String? failCode;
  final String failMessage;
  final analysisCompleter = Completer<JsonMap>();
  String? savedName;
  String? savedPassage;
  ContentMatchGeneratedQuestion? savedQuestion;

  late final generated = ContentMatchGeneratedQuestion.fromJson(
    _generatedResponse(),
  );

  @override
  Future<JsonMap> analyzePassage(String passage) {
    if (networkFailure) throw Exception('offline');
    return pauseAnalysis
        ? analysisCompleter.future
        : Future.value(_semanticJson());
  }

  @override
  Future<ContentMatchCandidatesResult> fetchCandidates({
    required JsonMap semantic,
    required String questionMode,
  }) async {
    final response = _candidateResponse();
    if (noCandidates) {
      (response['data'] as Map<String, dynamic>)['selected_target'] = null;
    }
    return ContentMatchCandidatesResult.fromJson(response);
  }

  @override
  Future<ContentMatchGeneratedQuestion> generate({
    required JsonMap semantic,
    required ContentMatchGenerationTarget target,
  }) async {
    if (failCode != null) {
      throw ContentMatchGenerationException(
        code: failCode!,
        message: failMessage,
        statusCode: 502,
      );
    }
    return generated;
  }

  @override
  Future<ContentMatchSaveResult> saveProblemSet({
    required String name,
    required String passage,
    required ContentMatchGeneratedQuestion question,
  }) async {
    savedName = name;
    savedPassage = passage;
    savedQuestion = question;
    return const ContentMatchSaveResult(
      problemSetId: 421,
      savedQuestionCount: 1,
    );
  }
}

JsonMap _semanticJson() => {
  'semantic_id': 'SEM-CM-1',
  'sentences': List.generate(
    6,
    (index) => {
      'sentence_id': 'S${index + 1}',
      'text': 'Sentence ${index + 1}.',
    },
  ),
};

JsonMap _claimJson(int index) => {
  'claim_id': 'CM-CLAIM-$index',
  'claim_type': 'sentence_claim',
  'canonical_meaning': {
    'en': [
      'Animals adapt to change.',
      'Economic choices matter.',
      'Digital tools help.',
      'Communities cooperate.',
      'Evidence supports this claim.',
      'Further context is needed.',
    ][index - 1],
  },
  'evidence': [
    {
      'type': 'sentence',
      'sentence_ids': ['S$index'],
    },
  ],
  'suitability': {
    'score': 0.9,
    'level': 'high',
    'reasons': ['Clear claim'],
  },
};

JsonMap _targetJson() => {
  'target_id': 'CM-TARGET-1',
  'semantic_id': 'SEM-CM-1',
  'question_mode': 'content_match',
  'target_answer_mode': 'match',
  'claim_ids': List.generate(6, (index) => 'CM-CLAIM-${index + 1}'),
  'claims': List.generate(6, (index) => _claimJson(index + 1)),
  'selection_score': 0.9,
};

JsonMap _candidateResponse() => <String, dynamic>{
  'status': 'success',
  'data': <String, dynamic>{
    'claims': List.generate(6, (index) => _claimJson(index + 1)),
    'selected_target': _targetJson(),
    'metadata': {
      'total_claims': 6,
      'eligible_claims': 6,
      'selected_claim_count': 6,
      'question_mode': 'content_match',
    },
  },
};

JsonMap _generatedResponse() => {
  'status': 'success',
  'data': {
    'question_id': 'CM-Q-1',
    'question_type': 'content_match',
    'question_mode': 'content_match',
    'stem': {'ko': '다음 글의 내용과 일치하는 것을 모두 고르시오.'},
    'choices': List.generate(6, (index) {
      final no = index + 1;
      final texts = [
        'Animals adapt to change.',
        'Economic choices matter.',
        'Digital tools help.',
        'Communities cooperate.',
        'Evidence supports this claim.',
        'Further context is needed.',
      ];
      return {
        'choice_id': String.fromCharCode(65 + index),
        'choice_no': no,
        'text': texts[index],
        'source_claim_id': 'CM-CLAIM-$no',
        'mutation_type': 'equivalent_paraphrase',
        'is_correct': no == 2 || no == 5,
        'validation': {'truth': 'entailed', 'scope': 'matched'},
      };
    }),
    'answer': [2, 5],
    'answer_choice_ids': ['B', 'E'],
    'explanation': {'ko': '②와 ⑤만 지문의 의미와 일치합니다.'},
    'validation': {'correct_choice_count': 2, 'judge_passed': true},
    'judge_result': {
      'correct_choice_ids': ['B', 'E'],
    },
    'metadata': {'generator_version': '1.2'},
  },
};
