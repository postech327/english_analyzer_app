class MockExamResultReport {
  const MockExamResultReport({
    required this.examTitle,
    required this.submittedAt,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.weakTypes,
    required this.typeSummary,
    required this.questionResults,
    this.attemptId = 0,
  });

  final String examTitle;
  final String submittedAt;
  final int score;
  final int correctCount;
  final int totalCount;
  final List<String> weakTypes;
  final Map<String, TypeResultSummary> typeSummary;
  final List<QuestionResultSummary> questionResults;
  final int attemptId;

  double get percent => totalCount <= 0 ? 0 : correctCount / totalCount * 100;
  double get accuracyRate => percent;
  List<QuestionResultSummary> get wrongQuestions =>
      questionResults.where((item) => !item.correct).toList();

  String get scoreComment {
    if (score >= 90) return '매우 우수합니다. 실전 감각이 안정적입니다.';
    if (score >= 70) return '기본기는 좋지만 약점 유형 보완이 필요합니다.';
    if (score >= 50) return '핵심 유형 복습이 필요합니다.';
    return '기본 유형부터 다시 점검해 주세요.';
  }

  String get recommendation {
    if (weakTypes.isNotEmpty) {
      return '${weakTypes.take(3).join(', ')} 유형을 먼저 오답 복습해 보세요.';
    }
    if (score >= 90) {
      return '좋은 흐름입니다. 다음 모의고사로 실전 감각을 이어가세요.';
    }
    return '오답 다시보기로 틀린 문항의 근거를 확인해 보세요.';
  }

  static MockExamResultReport fromSubmit({
    required String title,
    required Map<String, dynamic> result,
  }) {
    final typeResults = _asList(result['type_results']);
    final questionResults = typeResults.map((item) {
      final data = _asMap(item);
      return QuestionResultSummary(
        number: _asInt(data['number']),
        type: _asText(data['type']),
        label: _asText(data['label'], _asText(data['type'], '문제')),
        correct: data['correct'] == true,
      );
    }).toList();

    return MockExamResultReport(
      examTitle: title,
      submittedAt: _asText(result['submitted_at']),
      score: _asInt(result['score']),
      correctCount: _asInt(result['correct_count']),
      totalCount: _asInt(result['total_questions'], 20),
      weakTypes: _stringList(result['weak_types']),
      typeSummary: TypeResultSummary.fromQuestions(questionResults),
      questionResults: questionResults,
      attemptId: _asInt(result['attempt_id']),
    );
  }

  static MockExamResultReport fromAttemptDetail(Map<String, dynamic> data) {
    final attempt = _asMap(data['attempt']);
    final summary = _asMap(data['summary']);
    final questions = _asList(data['questions']);
    final questionResults = questions.map((item) {
      final question = _asMap(item);
      return QuestionResultSummary(
        number: _asInt(question['number']),
        type: _asText(question['question_type']),
        label: _asText(
          question['type_label'],
          _asText(question['question_type'], '문제'),
        ),
        correct: question['is_correct'] == true,
      );
    }).toList();

    return MockExamResultReport(
      examTitle: _asText(attempt['title'], '모의고사'),
      submittedAt: _asText(attempt['submitted_at']),
      score: _asInt(summary['score'], _asInt(attempt['score'])),
      correctCount: _asInt(
        summary['correct_count'],
        _asInt(attempt['correct_count']),
      ),
      totalCount: _asInt(attempt['total_questions'], 20),
      weakTypes: _stringList(summary['weak_types']),
      typeSummary: TypeResultSummary.fromQuestions(questionResults),
      questionResults: questionResults,
      attemptId: _asInt(attempt['id']),
    );
  }
}

class TypeResultSummary {
  const TypeResultSummary({
    required this.type,
    required this.label,
    required this.correct,
    required this.total,
  });

  final String type;
  final String label;
  final int correct;
  final int total;

  double get rate => total <= 0 ? 0 : correct / total * 100;

  static Map<String, TypeResultSummary> fromQuestions(
    List<QuestionResultSummary> questions,
  ) {
    final labels = <String, String>{};
    final totals = <String, int>{};
    final corrects = <String, int>{};
    for (final question in questions) {
      final key = question.type.isEmpty ? question.label : question.type;
      labels[key] = question.label;
      totals[key] = (totals[key] ?? 0) + 1;
      if (question.correct) {
        corrects[key] = (corrects[key] ?? 0) + 1;
      }
    }
    return {
      for (final key in totals.keys)
        key: TypeResultSummary(
          type: key,
          label: labels[key] ?? key,
          correct: corrects[key] ?? 0,
          total: totals[key] ?? 0,
        ),
    };
  }
}

class QuestionResultSummary {
  const QuestionResultSummary({
    required this.number,
    required this.type,
    required this.label,
    required this.correct,
  });

  final int number;
  final String type;
  final String label;
  final bool correct;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

List<String> _stringList(dynamic value) {
  return _asList(value)
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _asText(dynamic value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
