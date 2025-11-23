// lib/models/student_models.dart

class StudentOption {
  final int id;
  final String? label;
  final String text;

  StudentOption({
    required this.id,
    this.label,
    required this.text,
  });

  factory StudentOption.fromJson(Map<String, dynamic> json) {
    return StudentOption(
      id: json['id'] as int,
      label: json['label'] as String?,
      text: json['text'] as String,
    );
  }
}

class StudentQuestion {
  final int id;
  final String questionType;
  final String stem;
  final String? extraInfo;
  final int? orderIndex;
  final List<StudentOption> options;

  StudentQuestion({
    required this.id,
    required this.questionType,
    required this.stem,
    this.extraInfo,
    this.orderIndex,
    required this.options,
  });

  factory StudentQuestion.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List<dynamic>? ?? [])
        .map((e) => StudentOption.fromJson(e as Map<String, dynamic>))
        .toList();

    return StudentQuestion(
      id: json['id'] as int,
      questionType: json['question_type'] as String,
      stem: json['stem'] as String,
      extraInfo: json['extra_info'] as String?,
      orderIndex: json['order_index'] as int?,
      options: opts,
    );
  }
}

class StudentQuestionSet {
  final int passageId;
  final String? passageTitle;
  final String passageContent;
  final int problemSetId;
  final List<StudentQuestion> questions;

  StudentQuestionSet({
    required this.passageId,
    this.passageTitle,
    required this.passageContent,
    required this.problemSetId,
    required this.questions,
  });

  factory StudentQuestionSet.fromJson(Map<String, dynamic> json) {
    final qs = (json['questions'] as List<dynamic>? ?? [])
        .map((e) => StudentQuestion.fromJson(e as Map<String, dynamic>))
        .toList();

    return StudentQuestionSet(
      passageId: json['passage_id'] as int,
      passageTitle: json['passage_title'] as String?,
      passageContent: json['passage_content'] as String,
      problemSetId: json['problem_set_id'] as int,
      questions: qs,
    );
  }
}

/// 정답 체크 응답
class StudentAnswerCheckResult {
  final int questionId;
  final int selectedOptionId;
  final bool correct;
  final int correctOptionId;
  final String? explanation;

  StudentAnswerCheckResult({
    required this.questionId,
    required this.selectedOptionId,
    required this.correct,
    required this.correctOptionId,
    this.explanation,
  });

  factory StudentAnswerCheckResult.fromJson(Map<String, dynamic> json) {
    return StudentAnswerCheckResult(
      questionId: json['question_id'] as int,
      selectedOptionId: json['selected_option_id'] as int,
      correct: json['correct'] as bool,
      correctOptionId: json['correct_option_id'] as int,
      explanation: json['explanation'] as String?,
    );
  }
}
