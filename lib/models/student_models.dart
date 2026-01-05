// =====================================================
// 학생용 문제 세트 요약 (목록 화면)
// =====================================================
class StudentProblemSetSummary {
  final int id;
  final String title;
  final String? questionType;
  final int numQuestions;

  StudentProblemSetSummary({
    required this.id,
    required this.title,
    required this.numQuestions,
    this.questionType,
  });

  factory StudentProblemSetSummary.fromJson(Map<String, dynamic> json) {
    return StudentProblemSetSummary(
      id: json['id'] as int,
      title: json['title'] as String,
      questionType: json['question_type'] as String?,
      numQuestions: json['numQuestions'] as int? ?? 0,
    );
  }
}

// =====================================================
// 학생용 전체 문제 세트 (퀴즈 화면)
// =====================================================
class StudentQuestionSet {
  final int problemSetId;
  final String title;
  final String? passageTitle;
  final String? passageContent;
  final List<StudentQuestion> questions;

  StudentQuestionSet({
    required this.problemSetId,
    required this.title,
    required this.questions,
    this.passageTitle,
    this.passageContent,
  });

  factory StudentQuestionSet.fromJson(Map<String, dynamic> json) {
    return StudentQuestionSet(
      problemSetId: json['problem_set_id'] as int,
      title: json['title'] as String,
      passageTitle: json['passage_title'] as String?,
      passageContent: json['passage_content'] as String?,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => StudentQuestion.fromJson(e))
          .toList(),
    );
  }
}

// =====================================================
// 학생용 문제
// =====================================================
class StudentQuestion {
  final int id;
  final int? order;
  final String? questionType;
  final String text;
  final List<StudentOption> options;

  StudentQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.order,
    this.questionType,
  });

  factory StudentQuestion.fromJson(Map<String, dynamic> json) {
    return StudentQuestion(
      id: json['id'] as int,
      order: json['order'] as int?,
      questionType: json['question_type'] as String?,
      text: json['text'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => StudentOption.fromJson(e))
          .toList(),
    );
  }
}

// =====================================================
// 학생용 선택지
// =====================================================
class StudentOption {
  final int? id;
  final String? label;
  final String? text;

  StudentOption({
    this.id,
    this.label,
    this.text,
  });

  factory StudentOption.fromJson(Map<String, dynamic> json) {
    return StudentOption(
      id: json['id'] as int?,
      label: json['label'] as String?,
      text: json['text'] as String?,
    );
  }
}

// =====================================================
// 정답 체크 결과
// =====================================================
class StudentAnswerCheckResult {
  final int questionId;
  final bool correct;
  final int correctOptionId;

  StudentAnswerCheckResult({
    required this.questionId,
    required this.correct,
    required this.correctOptionId,
  });

  factory StudentAnswerCheckResult.fromJson(Map<String, dynamic> json) {
    return StudentAnswerCheckResult(
      questionId: json['question_id'] as int,
      correct: json['correct'] as bool,
      correctOptionId: json['correct_option_id'] as int,
    );
  }
}
