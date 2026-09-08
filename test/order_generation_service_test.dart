import 'dart:convert';

import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:english_analyzer_app/models/order_generation_models.dart';
import 'package:english_analyzer_app/services/order_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    AuthStore.saveLogin(
      accessTokenValue: 'teacher-order-token',
      roleValue: 'teacher',
    );
  });
  tearDown(AuthStore.clear);

  test('semantic analysis sends the exact passage and parses data', () async {
    late http.Request captured;
    final service = HttpOrderGenerationService(
      client: MockClient((request) async {
        captured = request;
        return _response({
          'status': 'success',
          'data': {'semantic_id': 'SEM-ORDER-1', 'sentences': []},
        });
      }),
    );

    final semantic = await service.analyzePassage('Exact order passage.');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.path, '/semantic/analyze');
    expect(body['text'], 'Exact order passage.');
    expect((body['source'] as Map)['source_type'], 'direct');
    expect(semantic['semantic_id'], 'SEM-ORDER-1');
  });

  test(
    'candidate request uses backend options and parses selected target',
    () async {
      late http.Request captured;
      final service = HttpOrderGenerationService(
        client: MockClient((request) async {
          captured = request;
          return _response(_candidateResponse());
        }),
      );

      final result = await service.fetchCandidates(
        semantic: const {'semantic_id': 'SEM-ORDER-1'},
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      final options = body['options'] as Map<String, dynamic>;
      expect(captured.url.path, '/question-generation/order/candidates');
      expect(body['semantic'], {'semantic_id': 'SEM-ORDER-1'});
      expect(options['block_count'], 3);
      expect(options['question_mode'], 'three_block_order');
      expect(result.candidates.single.candidateId, 'ORDER-CAND-1');
      expect(result.candidates.single.blocks, hasLength(3));
      expect(result.selectedTarget?.candidateId, 'ORDER-CAND-1');
    },
  );

  test(
    'generate sends untouched selected_target and parses direct preview',
    () async {
      late Map<String, dynamic> body;
      final service = HttpOrderGenerationService(
        client: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return _response(_generatedResponse());
        }),
      );
      final target = OrderGenerationTarget.fromJson(_targetJson());

      final generated = await service.generate(
        semantic: const {'semantic_id': 'SEM-ORDER-1'},
        target: target,
      );

      expect(body['target'], target.raw);
      expect((body['options'] as Map)['choice_count'], 5);
      expect(generated.productBlocks.map((block) => block.label), [
        'B',
        'C',
        'D',
      ]);
      expect(generated.productAnswer, 'C-B-D');
      expect(generated.productAnswerWithArrows, 'C → B → D');
    },
  );

  test(
    'ORDER_NO_CANDIDATE metadata remains a precision-first empty result',
    () async {
      final service = HttpOrderGenerationService(
        client: MockClient(
          (request) async => _response({
            'status': 'success',
            'data': {
              'candidates': [],
              'selected_target': null,
              'metadata': {'reason_code': 'ORDER_NO_CANDIDATE'},
            },
          }),
        ),
      );

      final result = await service.fetchCandidates(semantic: const {});
      expect(result.candidates, isEmpty);
      expect(result.selectedTarget, isNull);
      expect(result.reasonCode, 'ORDER_NO_CANDIDATE');
    },
  );

  test(
    'single-answer validation code is extracted from FastAPI detail',
    () async {
      final service = HttpOrderGenerationService(
        client: MockClient(
          (request) async => _response({
            'detail':
                'ORDER_SINGLE_ANSWER_VALIDATION_FAILED: target is ambiguous',
          }, 422),
        ),
      );

      expect(
        () => service.generate(
          semantic: const {},
          target: OrderGenerationTarget.fromJson(_targetJson()),
        ),
        throwsA(
          isA<OrderGenerationException>().having(
            (error) => error.code,
            'code',
            'ORDER_SINGLE_ANSWER_VALIDATION_FAILED',
          ),
        ),
      );
    },
  );

  test(
    'save uses semantic_orders and passes generated object unchanged',
    () async {
      late http.Request captured;
      final service = HttpOrderGenerationService(
        client: MockClient((request) async {
          captured = request;
          return _response({'problem_set_id': 205, 'saved_question_count': 1});
        }),
      );
      final generated = OrderGeneratedQuestion.fromJson(_generatedResponse());

      final result = await service.saveProblemSet(
        name: 'Semantic Order Set',
        passage: 'Original passage.',
        question: generated,
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(captured.url.path, '/teacher/problem_sets/import');
      expect(body['questions'], isEmpty);
      final orders = body['semantic_orders'] as List<dynamic>;
      expect((orders.single as Map)['order'], generated.raw);
      expect(body.containsKey('special_data'), isFalse);
      expect(result.problemSetId, 205);
    },
  );
}

http.Response _response(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _candidateResponse() => {
  'status': 'success',
  'data': {
    'candidates': [_candidateJson()],
    'selected_target': _targetJson(),
    'metadata': {
      'sentence_count': 4,
      'eligible_candidates': 1,
      'question_mode': 'three_block_order',
      'reason_code': null,
    },
  },
};

Map<String, dynamic> _candidateJson() => {
  'candidate_id': 'ORDER-CAND-1',
  'semantic_id': 'SEM-ORDER-1',
  'fixed_intro_sentence_ids': ['S1'],
  'blocks': _candidateBlocks(),
  'correct_order': ['B2', 'B1', 'B3'],
  'evidence': [
    {
      'before': 'B2',
      'after': 'B1',
      'evidence_type': 'connector',
      'cue': 'Therefore',
      'confidence': 0.91,
    },
  ],
  'constraints': [],
  'permutation_evaluations': [],
  'single_answer_validation': {
    'passed': true,
    'evaluated_permutations': 6,
    'expected_order': ['B2', 'B1', 'B3'],
    'valid_orders': [
      ['B2', 'B1', 'B3'],
    ],
    'uncertain_orders': [],
  },
  'suitability': {
    'score': 0.88,
    'level': 'high',
    'ambiguity_score': 0.1,
    'reasons': ['Strong connector evidence'],
  },
};

Map<String, dynamic> _targetJson() => {
  'target_id': 'ORDER-TARGET-1',
  'candidate_id': 'ORDER-CAND-1',
  'question_mode': 'three_block_order',
  'fixed_intro_sentence_ids': ['S1'],
  'blocks': _candidateBlocks(),
  'correct_order': ['B2', 'B1', 'B3'],
  'selection_score': 0.88,
  'difficulty': 'medium',
  'evidence_summary': [],
  'constraints': [],
  'permutation_evaluations': [],
  'single_answer_validation': {
    'passed': true,
    'evaluated_permutations': 6,
    'expected_order': ['B2', 'B1', 'B3'],
    'valid_orders': [
      ['B2', 'B1', 'B3'],
    ],
    'uncertain_orders': [],
  },
};

List<Map<String, dynamic>> _candidateBlocks() => [
  {
    'block_id': 'B1',
    'sentence_ids': ['S2'],
    'text_preview': 'Canonical first block.',
  },
  {
    'block_id': 'B2',
    'sentence_ids': ['S3'],
    'text_preview': 'Canonical second block.',
  },
  {
    'block_id': 'B3',
    'sentence_ids': ['S4'],
    'text_preview': 'Canonical third block.',
  },
];

Map<String, dynamic> _generatedResponse() => {
  'status': 'success',
  'data': {
    'question_id': 'ORDER-1',
    'question_type': 'order',
    'question_mode': 'three_block_order',
    'fixed_intro': {
      'sentence_ids': ['S1'],
      'text': 'Intro fixed passage.',
    },
    'blocks': [
      {
        'display_label': 'C',
        'block_id': 'B1',
        'sentence_ids': ['S2'],
        'text': 'Canonical first block.',
      },
      {
        'display_label': 'A',
        'block_id': 'B2',
        'sentence_ids': ['S3'],
        'text': 'Canonical second block.',
      },
      {
        'display_label': 'B',
        'block_id': 'B3',
        'sentence_ids': ['S4'],
        'text': 'Canonical third block.',
      },
    ],
    'stem': {'ko': '주어진 글 다음에 이어질 글의 순서를 정하세요.'},
    'choices': List.generate(5, (index) => {'choice_no': index + 1}),
    'answer': 1,
    'correct_sequence': ['A', 'C', 'B'],
    'explanation': {'ko': 'B2가 B1보다 먼저 오고 B3가 마지막입니다.'},
    'semantic_constraints': [],
    'validation': {
      'single_answer': true,
      'semantic_single_answer': true,
      'valid_orders': [
        ['B2', 'B1', 'B3'],
      ],
      'uncertain_orders': [],
      'judge_overall_valid': true,
    },
    'judge_result': {
      'overall_valid': true,
      'expected_order': ['B2', 'B1', 'B3'],
    },
    'metadata': {'semantic_id': 'SEM-ORDER-1'},
  },
};
