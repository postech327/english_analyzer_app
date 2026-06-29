// lib/models/student_exam/exam_submit_models.dart

class StudentAnswerIn {
  final int questionId;
  final int selectedIndex;

  StudentAnswerIn({
    required this.questionId,
    required this.selectedIndex,
  });

  Map<String, dynamic> toJson() => {
        "question_id": questionId,
        "selected_index": selectedIndex,
      };
}

class StudentExamSubmitRequest {
  final List<StudentAnswerIn> answers;

  StudentExamSubmitRequest({required this.answers});

  Map<String, dynamic> toJson() => {
        "answers": answers.map((e) => e.toJson()).toList(),
      };
}

class QuestionResult {
  final int questionId;
  final int selectedIndex;
  final int correctIndex;
  final bool isCorrect;

  QuestionResult({
    required this.questionId,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['question_id'],
      selectedIndex: json['selected_index'],
      correctIndex: json['correct_index'],
      isCorrect: json['is_correct'],
    );
  }
}

class StudentExamSubmitResponse {
  final int totalQuestions;
  final int correctCount;
  final double accuracy;
  final List<QuestionResult> results;

  StudentExamSubmitResponse({
    required this.totalQuestions,
    required this.correctCount,
    required this.accuracy,
    required this.results,
  });

  factory StudentExamSubmitResponse.fromJson(Map<String, dynamic> json) {
    return StudentExamSubmitResponse(
      totalQuestions: json['total_questions'],
      correctCount: json['correct_count'],
      accuracy: (json['accuracy'] as num).toDouble(),
      results: (json['results'] as List)
          .map((e) => QuestionResult.fromJson(e))
          .toList(),
    );
  }
}
