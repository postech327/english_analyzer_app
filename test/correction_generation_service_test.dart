import 'dart:convert';

import 'package:english_analyzer_app/config/auth_store.dart';
import 'package:english_analyzer_app/models/correction_generation_models.dart';
import 'package:english_analyzer_app/services/correction_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    AuthStore.saveLogin(
      accessTokenValue: 'teacher-test-token',
      roleValue: 'teacher',
    );
  });

  tearDown(AuthStore.clear);

  test('candidate request and response use the backend contract', () async {
    late http.Request captured;
    final service = HttpCorrectionGenerationService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'candidates': [_candidateJson()],
              'candidate_count': 1,
              'selected_candidate': _candidateJson(),
              'metadata': {
                'sentence_count': 2,
                'eligible_candidates': 1,
                'excluded_ambiguous': 0,
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await service.fetchCandidates(
      semantic: const {'semantic_id': 'SEM-1'},
      limit: 5,
    );

    expect(captured.url.path, '/question-generation/correction/candidates');
    expect(captured.headers['authorization'], 'Bearer teacher-test-token');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['semantic'], {'semantic_id': 'SEM-1'});
    expect(body['limit'], 5);
    expect(result.candidateCount, 1);
    expect(result.candidates.single.candidateId, 'CORR-S2-1');
    expect(result.candidates.single.corruptionFamily, 'relation_reversal');
  });

  test('semantic analysis sends exact passage and parses data', () async {
    late Map<String, dynamic> body;
    final service = HttpCorrectionGenerationService(
      client: MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'status': 'success',
            'cache': {'hit': false, 'source_hash': 'hash'},
            'data': {'semantic_id': 'SEM-1', 'normalized_text': 'Passage.'},
          }),
          200,
        );
      }),
    );

    final semantic = await service.analyzePassage('Passage.');
    expect(body['text'], 'Passage.');
    expect((body['source'] as Map)['source_type'], 'direct');
    expect(semantic['semantic_id'], 'SEM-1');
  });

  test('generate sends untouched target and parses teacher preview', () async {
    late Map<String, dynamic> body;
    final service = HttpCorrectionGenerationService(
      client: MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(_generatedResponse()),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final target = CorrectionCandidate.fromJson(_candidateJson());

    final generated = await service.generate(
      semantic: const {'semantic_id': 'SEM-1'},
      target: target,
    );

    expect(body['target'], target.raw);
    expect((body['options'] as Map)['marker_count'], 5);
    expect(generated.answer, 4);
    expect(generated.correctExpression, 'However');
    expect(generated.markers, hasLength(5));
    expect(
      generated.markedPreviewPassage,
      '①word1 ②word2 ③word3 ④Therefore ⑤word5.',
    );
  });

  test('save uses official semantic_corrections import payload', () async {
    late http.Request captured;
    final service = HttpCorrectionGenerationService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'problem_set_id': 17,
            'passage_id': 21,
            'saved_question_count': 1,
            'skipped_question_count': 0,
            'warnings': [],
          }),
          200,
        );
      }),
    );
    final generated = CorrectionGeneratedQuestion.fromJson(
      _generatedResponse(),
    );

    final saved = await service.saveProblemSet(
      name: 'Teacher set',
      passage: 'Original passage.',
      question: generated,
    );

    expect(captured.url.path, '/teacher/problem_sets/import');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['questions'], isEmpty);
    final corrections = body['semantic_corrections'] as List;
    expect(corrections, hasLength(1));
    expect((corrections.single as Map)['correction'], generated.raw);
    expect(saved.problemSetId, 17);
    expect(saved.savedQuestionCount, 1);
  });

  test('backend error code is preserved for UI mapping', () async {
    final service = HttpCorrectionGenerationService(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'status': 'error',
            'error': {
              'code': 'CORRECTION_NO_CANDIDATE',
              'message': 'No suitable correction target was found.',
            },
          }),
          422,
        ),
      ),
    );

    expect(
      () => service.fetchCandidates(semantic: const {'semantic_id': 'SEM-1'}),
      throwsA(
        isA<CorrectionGenerationException>()
            .having((error) => error.code, 'code', 'CORRECTION_NO_CANDIDATE')
            .having((error) => error.statusCode, 'status', 422),
      ),
    );
  });
}

Map<String, dynamic> _candidateJson() => {
      'candidate_id': 'CORR-S2-1',
      'target_id': 'TARGET-S2-1',
      'semantic_id': 'SEM-1',
      'target_sentence_id': 'S2',
      'target_sentence_index': 1,
      'start_char': 20,
      'end_char': 27,
      'original_text': 'because',
      'replacement_text': 'although',
      'correction_domain': 'semantic',
      'corruption_family': 'relation_reversal',
      'relation_ids': ['REL-1'],
      'reference_ids': [],
      'source_sentence_ids': ['S1', 'S2'],
      'score_breakdown': {
        'grammar_signal': 0.5,
        'semantic_importance': 0.9,
        'local_context_strength': 0.8,
        'reference_dependency': 0.0,
        'relation_dependency': 0.9,
        'corruption_feasibility': 0.9,
        'ambiguity_risk': 0.1,
      },
      'candidate_score': 0.86,
      'ambiguity_flags': [],
      'semantic_invalidity_guaranteed': true,
      'semantic_invalidity_reason': 'Reverses the supported relation.',
      'semantic_evidence_sentence_ids': ['S1', 'S2'],
      'semantic_evidence_spans': [],
      'semantic_answerability_score': 0.9,
      'difficulty_score': 0.6,
      'difficulty_label': 'MEDIUM',
    };

Map<String, dynamic> _generatedResponse() => {
      'status': 'success',
      'data': {
        'question_id': 'CORRECTION-1',
        'question_type': 'correction',
        'question_mode': 'correction',
        'target': _candidateJson(),
        'stem': {'ko': '다음 글의 밑줄 친 부분 중 어색한 것을 고치시오.'},
        'markers': [
          _marker(1, '①', 0, 5, 'word1', 'word1'),
          _marker(2, '②', 6, 11, 'word2', 'word2'),
          _marker(3, '③', 12, 17, 'word3', 'word3'),
          _marker(4, '④', 18, 25, 'However', 'Therefore', corrupted: true),
          _marker(5, '⑤', 26, 31, 'word5', 'word5'),
        ],
        'answer': 4,
        'original_passage': 'word1 word2 word3 However word5.',
        'corrupted_passage': 'word1 word2 word3 Therefore word5.',
        'corruption': {
          'target_id': 'TARGET-S2-1',
          'target_sentence_id': 'S2',
          'marker_position': 4,
          'start_char': 30,
          'end_char': 39,
          'original_text': 'However',
          'corrupted_text': 'Therefore',
          'corruption_type': 'relation_reversal',
          'explanation_ko': '대조 관계이므로 However가 알맞습니다.',
        },
        'explanation': {'ko': '대조 관계이므로 However가 알맞습니다.'},
        'validation': {
          'marker_count': 5,
          'original_marker_count': 4,
          'corrupted_marker_count': 1,
          'single_error': true,
          'exact_source_spans': true,
          'non_overlapping_spans': true,
        },
        'metadata': {
          'generator_version': '1.0',
          'generation_mode': 'deterministic',
          'semantic_id': 'SEM-1',
          'target_sentence_id': 'S2',
        },
        'judge_result': {'overall_valid': true},
        'judge_issues': [],
      },
    };

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
      'target_sentence_id': 'S$position',
      'target_sentence_index': position - 1,
      'start_char': start,
      'end_char': end,
      'original_text': original,
      'display_text': display,
      'is_corrupted': corrupted,
    };
