// lib/models/student_exam/retry_models.dart

class RetryOption {
  final int index;
  final String text;

  RetryOption({
    required this.index,
    required this.text,
  });

  factory RetryOption.fromJson(Map<String, dynamic> json) {
    return RetryOption(
      index: json['index'],
      text: json['text'],
    );
  }
}

class RetryQuestion {
  final int questionId;
  final int order;
  final String text;
  final List<RetryOption> options;

  RetryQuestion({
    required this.questionId,
    required this.order,
    required this.text,
    required this.options,
  });

  factory RetryQuestion.fromJson(Map<String, dynamic> json) {
    return RetryQuestion(
      questionId: json['question_id'],
      order: json['order'],
      text: json['text'],
      options: (json['options'] as List)
          .map((e) => RetryOption.fromJson(e))
          .toList(),
    );
  }
}

class RetryQuestionsResponse {
  final String retryType;
  final int count;
  final List<RetryQuestion> questions;

  RetryQuestionsResponse({
    required this.retryType,
    required this.count,
    required this.questions,
  });

  factory RetryQuestionsResponse.fromJson(Map<String, dynamic> json) {
    return RetryQuestionsResponse(
      retryType: json['retry_type'],
      count: json['count'],
      questions: (json['questions'] as List)
          .map((e) => RetryQuestion.fromJson(e))
          .toList(),
    );
  }
}

// ===== 제출 =====

class RetryAnswerIn {
  final int questionId;
  final int selectedIndex;

  RetryAnswerIn({
    required this.questionId,
    required this.selectedIndex,
  });

  Map<String, dynamic> toJson() => {
        "question_id": questionId,
        "selected_index": selectedIndex,
      };
}

class RetrySubmitRequest {
  final List<RetryAnswerIn> answers;

  RetrySubmitRequest({required this.answers});

  Map<String, dynamic> toJson() => {
        "answers": answers.map((e) => e.toJson()).toList(),
      };
}

class RetrySubmitResponse {
  final int total;
  final int correct;
  final double accuracy;

  RetrySubmitResponse({
    required this.total,
    required this.correct,
    required this.accuracy,
  });

  factory RetrySubmitResponse.fromJson(Map<String, dynamic> json) {
    return RetrySubmitResponse(
      total: json['total'],
      correct: json['correct'],
      accuracy: (json['accuracy'] as num).toDouble(),
    );
  }
}
