import 'dart:convert';

import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:english_analyzer_app/models/content_match_generation_models.dart';
import 'package:english_analyzer_app/services/content_match_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    AuthStore.saveLogin(
      accessTokenValue: 'teacher-content-match-token',
      roleValue: 'teacher',
    );
  });
  tearDown(AuthStore.clear);

  test('semantic analysis sends the exact passage', () async {
    late http.Request captured;
    final service = HttpContentMatchGenerationService(
      client: MockClient((request) async {
        captured = request;
        return _response({
          'status': 'success',
          'data': {'semantic_id': 'SEM-CM-1'},
        });
      }),
    );
    final result = await service.analyzePassage('Exact content passage.');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.path, '/semantic/analyze');
    expect(body['text'], 'Exact content passage.');
    expect((body['source'] as Map)['source_type'], 'direct');
    expect(result['semantic_id'], 'SEM-CM-1');
  });

  test(
    'candidate request uses backend mode and parses selected target',
    () async {
      late http.Request captured;
      final service = HttpContentMatchGenerationService(
        client: MockClient((request) async {
          captured = request;
          return _response(_candidateResponse());
        }),
      );
      final result = await service.fetchCandidates(
        semantic: const {'semantic_id': 'SEM-CM-1'},
        questionMode: 'content_mismatch',
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      final options = body['options'] as Map<String, dynamic>;
      expect(
        captured.url.path,
        '/question-generation/content-match/candidates',
      );
      expect(options['question_mode'], 'content_mismatch');
      expect(options['target_claim_count'], 6);
      expect(result.claims, hasLength(6));
      expect(result.selectedTarget?.targetId, 'CM-TARGET-1');
      expect(result.selectedTarget?.claims, hasLength(6));
    },
  );

  test('generate passes target unchanged and parses six choices', () async {
    late Map<String, dynamic> body;
    final service = HttpContentMatchGenerationService(
      client: MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _response(_generatedResponse());
      }),
    );
    final target = ContentMatchGenerationTarget.fromJson(_targetJson());
    final result = await service.generate(
      semantic: const {'semantic_id': 'SEM-CM-1'},
      target: target,
    );
    expect(body['target'], target.raw);
    expect((body['options'] as Map)['choice_count'], 6);
    expect(result.choices, hasLength(6));
    expect(result.choices.last.choiceId, 'F');
  });

  test('generated answer remains the backend exact-two set', () {
    final result = ContentMatchGeneratedQuestion.fromJson(_generatedResponse());
    expect(result.answerPositions, [2, 5]);
    expect(result.displayAnswer, '②, ⑤');
    expect(result.raw['answer_choice_ids'], ['B', 'E']);
  });

  test('empty selected target remains a no-candidate result', () {
    final response = _candidateResponse();
    (response['data'] as Map<String, dynamic>)['selected_target'] = null;
    final result = ContentMatchCandidatesResult.fromJson(response);
    expect(result.selectedTarget, isNull);
    expect(result.claims, hasLength(6));
  });

  test('semantic validation and judge failure code is preserved', () async {
    final service = HttpContentMatchGenerationService(
      client: MockClient(
        (_) async => _response({
          'status': 'error',
          'error': {
            'code': 'CONTENT_MATCH_SEMANTIC_VALIDATION_FAILED',
            'message': 'CONTENT_MATCH_JUDGE_DISAGREEMENT',
          },
        }, 502),
      ),
    );
    expect(
      () => service.generate(
        semantic: const {},
        target: ContentMatchGenerationTarget.fromJson(_targetJson()),
      ),
      throwsA(
        isA<ContentMatchGenerationException>()
            .having(
              (error) => error.code,
              'code',
              'CONTENT_MATCH_SEMANTIC_VALIDATION_FAILED',
            )
            .having(
              (error) => error.message,
              'message',
              contains('JUDGE_DISAGREEMENT'),
            ),
      ),
    );
  });

  test('save sends raw semantic_content_matches payload', () async {
    late http.Request captured;
    final service = HttpContentMatchGenerationService(
      client: MockClient((request) async {
        captured = request;
        return _response({'problem_set_id': 421, 'saved_question_count': 1});
      }),
    );
    final question = ContentMatchGeneratedQuestion.fromJson(
      _generatedResponse(),
    );
    final result = await service.saveProblemSet(
      name: 'Semantic Content Match Set',
      passage: 'Original passage.',
      question: question,
    );
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.path, '/teacher/problem_sets/import');
    expect(body['questions'], isEmpty);
    final items = body['semantic_content_matches'] as List<dynamic>;
    final item = items.single as Map<String, dynamic>;
    expect(item['content_match'], question.raw);
    expect(item['passage'], 'Original passage.');
    expect(body.containsKey('special_data'), isFalse);
    expect(result.problemSetId, 421);
  });
}

http.Response _response(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _claimJson(int index) => {
  'claim_id': 'CM-CLAIM-$index',
  'claim_type': index == 6 ? 'global_claim' : 'sentence_claim',
  'canonical_meaning': {'en': 'Claim $index'},
  'evidence': [
    {
      'type': 'sentence',
      'sentence_ids': ['S$index'],
      'confidence': 0.9,
    },
  ],
  'suitability': {
    'score': 0.9,
    'level': 'high',
    'reasons': ['Clear claim'],
  },
};

Map<String, dynamic> _targetJson() => {
  'target_id': 'CM-TARGET-1',
  'semantic_id': 'SEM-CM-1',
  'question_mode': 'content_match',
  'target_answer_mode': 'match',
  'claim_ids': List.generate(6, (index) => 'CM-CLAIM-${index + 1}'),
  'claims': List.generate(6, (index) => _claimJson(index + 1)),
  'selection_score': 0.9,
};

Map<String, dynamic> _candidateResponse() => <String, dynamic>{
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

Map<String, dynamic> _generatedResponse() => {
  'status': 'success',
  'data': {
    'question_id': 'CM-Q-1',
    'question_type': 'content_match',
    'question_mode': 'content_match',
    'stem': {'ko': '다음 글의 내용과 일치하는 것을 모두 고르시오.'},
    'choices': [
      _choice('A', 1, 'Animals adapt to change.'),
      _choice('B', 2, 'Economic choices matter.'),
      _choice('C', 3, 'Digital tools help.'),
      _choice('D', 4, 'Communities cooperate.'),
      _choice('E', 5, 'Evidence supports this claim.'),
      _choice('F', 6, 'Further context is needed.'),
    ],
    'answer': [2, 5],
    'answer_choice_ids': ['B', 'E'],
    'explanation': {'ko': '②와 ⑤만 지문의 의미와 일치합니다.'},
    'validation': {
      'multi_answer': true,
      'correct_choice_count': 2,
      'incorrect_choice_count': 4,
      'uncertain_choice_count': 0,
      'judge_passed': true,
    },
    'judge_result': {
      'correct_choice_ids': ['B', 'E'],
    },
    'metadata': {'generator_version': '1.2'},
  },
};

Map<String, dynamic> _choice(String id, int no, String text) => {
  'choice_id': id,
  'choice_no': no,
  'text': text,
  'source_claim_id': 'CM-CLAIM-$no',
  'mutation_type': 'equivalent_paraphrase',
  'is_correct': no == 2 || no == 5,
  'validation': {'truth': 'entailed', 'scope': 'matched'},
};
