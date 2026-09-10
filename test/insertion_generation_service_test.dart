import 'dart:convert';

import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:english_analyzer_app/models/insertion_generation_models.dart';
import 'package:english_analyzer_app/services/insertion_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    AuthStore.saveLogin(
      accessTokenValue: 'teacher-insertion-token',
      roleValue: 'teacher',
    );
  });
  tearDown(AuthStore.clear);

  test('semantic analysis sends exact passage and parses data', () async {
    late http.Request captured;
    final service = HttpInsertionGenerationService(
      client: MockClient((request) async {
        captured = request;
        return _response({
          'status': 'success',
          'data': {'semantic_id': 'SEM-INS-1', 'sentences': []},
        });
      }),
    );

    final semantic = await service.analyzePassage('Exact insertion passage.');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.path, '/semantic/analyze');
    expect(body['text'], 'Exact insertion passage.');
    expect((body['source'] as Map)['source_type'], 'direct');
    expect(semantic['semantic_id'], 'SEM-INS-1');
  });

  test('candidate request uses backend options and parses target', () async {
    late http.Request captured;
    final service = HttpInsertionGenerationService(
      client: MockClient((request) async {
        captured = request;
        return _response(_candidateResponse());
      }),
    );

    final result = await service.fetchCandidates(
      semantic: const {'semantic_id': 'SEM-INS-1'},
    );
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    final options = body['options'] as Map<String, dynamic>;
    expect(captured.url.path, '/question-generation/insertion/candidates');
    expect(body['semantic'], {'semantic_id': 'SEM-INS-1'});
    expect(options['question_mode'], 'sentence_insertion');
    expect(result.candidates.single.candidateId, 'INS-CAND-1');
    expect(result.candidates.single.insertedSentence.text, 'Target sentence.');
    expect(result.selectedTarget?.candidateId, 'INS-CAND-1');
  });

  test('generate sends untouched target and parses product preview', () async {
    late Map<String, dynamic> body;
    final service = HttpInsertionGenerationService(
      client: MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _response(_generatedResponse());
      }),
    );
    final target = InsertionGenerationTarget.fromJson(_targetJson());

    final generated = await service.generate(
      semantic: const {'semantic_id': 'SEM-INS-1'},
      target: target,
    );

    expect(body['target'], target.raw);
    expect((body['options'] as Map)['position_count'], 5);
    expect((body['options'] as Map)['language'], 'ko');
    expect(generated.insertedSentence, 'Target sentence.');
    expect(generated.answer, 3);
    for (final marker in const ['①', '②', '③', '④', '⑤']) {
      expect(marker.allMatches(generated.productPassage), hasLength(1));
    }
  });

  test('INSERTION_NO_CANDIDATE remains an empty safe result', () async {
    final service = HttpInsertionGenerationService(
      client: MockClient(
        (_) async => _response({
          'status': 'success',
          'data': {
            'candidates': [],
            'selected_target': null,
            'metadata': {'reason_code': 'INSERTION_NO_CANDIDATE'},
          },
        }),
      ),
    );

    final result = await service.fetchCandidates(semantic: const {});
    expect(result.candidates, isEmpty);
    expect(result.selectedTarget, isNull);
    expect(result.reasonCode, 'INSERTION_NO_CANDIDATE');
  });

  test('validation failure code is extracted from FastAPI detail', () async {
    final service = HttpInsertionGenerationService(
      client: MockClient(
        (_) async => _response({
          'detail':
              'INSERTION_SINGLE_ANSWER_VALIDATION_FAILED: target is ambiguous',
        }, 422),
      ),
    );

    expect(
      () => service.generate(
        semantic: const {},
        target: InsertionGenerationTarget.fromJson(_targetJson()),
      ),
      throwsA(
        isA<InsertionGenerationException>().having(
          (error) => error.code,
          'code',
          'INSERTION_SINGLE_ANSWER_VALIDATION_FAILED',
        ),
      ),
    );
  });

  test('save uses semantic_insertions and raw generated object', () async {
    late http.Request captured;
    final service = HttpInsertionGenerationService(
      client: MockClient((request) async {
        captured = request;
        return _response({'problem_set_id': 306, 'saved_question_count': 1});
      }),
    );
    final generated = InsertionGeneratedQuestion.fromJson(_generatedResponse());

    final result = await service.saveProblemSet(
      name: 'Semantic Insertion Set',
      passage: 'Original passage.',
      question: generated,
    );

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.path, '/teacher/problem_sets/import');
    expect(body['source'], 'Semantic Insertion');
    expect(body['questions'], isEmpty);
    final insertions = body['semantic_insertions'] as List<dynamic>;
    expect((insertions.single as Map)['insertion'], generated.raw);
    expect(body.containsKey('special_data'), isFalse);
    expect(result.problemSetId, 306);
  });

  test('non-teacher is rejected before an HTTP request', () async {
    AuthStore.saveLogin(accessTokenValue: 'student', roleValue: 'student');
    var called = false;
    final service = HttpInsertionGenerationService(
      client: MockClient((_) async {
        called = true;
        return _response({});
      }),
    );

    expect(
      () => service.analyzePassage('Passage.'),
      throwsA(
        isA<InsertionGenerationException>().having(
          (error) => error.code,
          'code',
          'TEACHER_REQUIRED',
        ),
      ),
    );
    expect(called, isFalse);
  });
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
        'metadata': {'reason_code': null},
      },
    };

Map<String, dynamic> _candidateJson() => {
      'candidate_id': 'INS-CAND-1',
      'semantic_id': 'SEM-INS-1',
      'target_sentence_id': 'S3',
      'inserted_sentence': {
        'sentence_id': 'S3',
        'index': 2,
        'text': 'Target sentence.',
      },
      'remaining_sentence_ids': ['S1', 'S2', 'S4', 'S5'],
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

Map<String, dynamic> _targetJson() => {
      'target_id': 'INS-TARGET-1',
      'candidate_id': 'INS-CAND-1',
      'question_mode': 'sentence_insertion',
      'inserted_sentence': {
        'sentence_id': 'S3',
        'index': 2,
        'text': 'Target sentence.',
      },
      'remaining_sentence_ids': ['S1', 'S2', 'S4', 'S5'],
      'gaps': List.generate(5, (index) => {'gap_id': 'G${index + 1}'}),
      'correct_gap_id': 'G3',
      'selection_score': 0.91,
      'difficulty': 'medium',
      'evidence_summary': [
        {
          'evidence_type': 'referential',
          'sentence_ids': ['S2', 'S3'],
          'cue': 'This result',
          'confidence': 0.94,
        },
      ],
    };

Map<String, dynamic> _generatedResponse() => {
      'status': 'success',
      'data': {
        'question_id': 'INS-1',
        'question_type': 'insertion',
        'question_mode': 'sentence_insertion',
        'inserted_sentence': {'sentence_id': 'S3', 'text': 'Target sentence.'},
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
        'positions': List.generate(
          5,
          (index) => {
            'display_no': index + 1,
            'marker': String.fromCharCode(0x2460 + index),
            'gap_id': 'G${index + 1}',
            'position_index': index,
            'is_correct': index == 2,
          },
        ),
        'answer': 3,
        'correct_gap_id': 'G3',
        'explanation': {'ko': 'This result가 앞 문장을 받아 세 번째 위치가 적절합니다.'},
        'validation': {'single_answer': true},
        'judge_result': {'overall_valid': true},
      },
    };
