import 'dart:convert';

import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:english_analyzer_app/models/blank_generation_models.dart';
import 'package:english_analyzer_app/services/blank_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    AuthStore.saveLogin(
      accessTokenValue: 'teacher-blank-token',
      roleValue: 'teacher',
    );
  });
  tearDown(AuthStore.clear);

  test('semantic analysis sends the exact passage', () async {
    late http.Request captured;
    final service = HttpBlankGenerationService(
      client: MockClient((request) async {
        captured = request;
        return _response({
          'status': 'success',
          'data': {'semantic_id': 'SEM-BLANK-1'},
        });
      }),
    );
    final result = await service.analyzePassage('Exact blank passage.');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.path, '/semantic/analyze');
    expect(body['text'], 'Exact blank passage.');
    expect((body['source'] as Map)['source_type'], 'direct');
    expect(result['semantic_id'], 'SEM-BLANK-1');
  });

  test('candidate request uses backend blank inference contract', () async {
    late http.Request captured;
    final service = HttpBlankGenerationService(
      client: MockClient((request) async {
        captured = request;
        return _response(_candidateResponse());
      }),
    );
    final result = await service.fetchCandidates(
      semantic: const {'semantic_id': 'SEM-BLANK-1'},
    );
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    final options = body['options'] as Map<String, dynamic>;
    expect(captured.url.path, '/question-generation/blank/candidates');
    expect(options['question_mode'], 'blank_inference');
    expect(options['max_candidates'], 10);
    expect(result.candidates, hasLength(2));
    expect(result.selectedTarget?.candidateId, 'BLANK-CAND-2');
  });

  test(
    'generate passes raw target and requests exactly five choices',
    () async {
      late Map<String, dynamic> body;
      final service = HttpBlankGenerationService(
        client: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return _response(_generatedResponse());
        }),
      );
      final target = BlankGenerationTarget.fromJson(_targetJson());
      final result = await service.generate(
        semantic: const {'semantic_id': 'SEM-BLANK-1'},
        target: target,
      );
      expect(body['target'], target.raw);
      expect((body['options'] as Map)['choice_count'], 5);
      expect(result.choices, hasLength(5));
    },
  );

  test('generated preview fields come directly from backend response', () {
    final result = BlankGeneratedQuestion.fromJson(_generatedResponse());
    expect(result.blankedPassage, _blankedPassage);
    expect(result.answerPosition, 3);
    expect(result.displayAnswer, '③');
    expect(result.explanation, '③만 원문의 의미를 유지합니다.');
  });

  test('repeated phrase passage is not reconstructed in Flutter', () {
    final result = BlankGeneratedQuestion.fromJson(_generatedResponse());
    expect(result.blankedPassage, startsWith('the same phrase'));
    expect(result.blankedPassage, contains('________________________________'));
    expect(result.blankedPassage.indexOf('the same phrase'), 0);
  });

  test('save sends only raw semantic_blanks object', () async {
    late http.Request captured;
    final service = HttpBlankGenerationService(
      client: MockClient((request) async {
        captured = request;
        return _response({'problem_set_id': 526, 'saved_question_count': 1});
      }),
    );
    final question = BlankGeneratedQuestion.fromJson(_generatedResponse());
    final result = await service.saveProblemSet(
      name: 'Semantic Blank Set',
      passage: _sourcePassage,
      question: question,
    );
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.path, '/teacher/problem_sets/import');
    expect(body['questions'], isEmpty);
    final items = body['semantic_blanks'] as List<dynamic>;
    expect((items.single as Map)['blank'], question.raw);
    expect(body.containsKey('answer_index'), isFalse);
    expect(body.containsKey('special_data'), isFalse);
    expect(result.problemSetId, 526);
  });

  test('backend failure is surfaced without a local fallback', () async {
    final service = HttpBlankGenerationService(
      client: MockClient(
        (_) async => _response({
          'status': 'error',
          'error': {
            'code': 'BLANK_SINGLE_ANSWER_VALIDATION_FAILED',
            'message': 'BLANK_JUDGE_DISAGREEMENT',
          },
        }, 502),
      ),
    );
    expect(
      () => service.generate(
        semantic: const {},
        target: BlankGenerationTarget.fromJson(_targetJson()),
      ),
      throwsA(
        isA<BlankGenerationException>().having(
          (error) => error.code,
          'code',
          'BLANK_SINGLE_ANSWER_VALIDATION_FAILED',
        ),
      ),
    );
  });
}

http.Response _response(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

const _sourcePassage =
    'the same phrase appears first, and the same phrase appears second.';
const _blankedPassage =
    'the same phrase appears first, and ________________________________ appears second.';

Map<String, dynamic> _candidate(String id, String text, double score) => {
  'candidate_id': id,
  'semantic_id': 'SEM-BLANK-1',
  'sentence_id': id == 'BLANK-CAND-1' ? 'S1' : 'S2',
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

Map<String, dynamic> _targetJson() => {
  'target_id': 'BLANK-TARGET-1',
  'candidate_id': 'BLANK-CAND-2',
  'question_mode': 'blank_inference',
  'sentence_id': 'S2',
  'span': {'start_char': 37, 'end_char': 52, 'text': 'the same phrase'},
  'text': 'the same phrase',
  'blank_type': 'phrase',
  'semantic_role': 'main_claim',
  'selection_score': 0.94,
  'evidence_summary': const [],
};

Map<String, dynamic> _candidateResponse() => {
  'status': 'success',
  'data': {
    'candidates': [
      _candidate('BLANK-CAND-1', 'appears first', 0.82),
      _candidate('BLANK-CAND-2', 'the same phrase', 0.94),
    ],
    'selected_target': _targetJson(),
    'metadata': {
      'total_extracted': 2,
      'eligible_candidates': 2,
      'question_mode': 'blank_inference',
    },
  },
};

Map<String, dynamic> _generatedResponse() => {
  'status': 'success',
  'data': {
    'question_id': 'BLANK-Q-1',
    'question_type': 'blank',
    'question_mode': 'blank_inference',
    'stem': {'ko': '다음 빈칸에 들어갈 말로 가장 적절한 것을 고르시오.'},
    'passage': {'blanked_text': _blankedPassage},
    'blank': {
      'candidate_id': 'BLANK-CAND-2',
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
    'validation': {
      'single_answer': true,
      'correct_choice_count': 1,
      'judge_passed': true,
    },
    'judge_result': {'overall_valid': true},
    'metadata': {'generator_version': '1.1'},
  },
};
