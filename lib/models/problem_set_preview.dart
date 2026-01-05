class ProblemSetPreviewResponse {
  final ProblemSetInfo problemSet;
  final PassageInfo passage;
  final List<QuestionInfo> questions;

  ProblemSetPreviewResponse({
    required this.problemSet,
    required this.passage,
    required this.questions,
  });

  factory ProblemSetPreviewResponse.fromJson(Map<String, dynamic> json) {
    return ProblemSetPreviewResponse(
      problemSet: ProblemSetInfo.fromJson(json['problem_set'] ?? {}),
      passage: PassageInfo.fromJson(json['passage'] ?? {}),
      questions: (json['questions'] as List? ?? [])
          .map((e) => QuestionInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProblemSetInfo {
  final int id;
  final String name;
  final String? description;
  final String? createdBy;
  final List<dynamic> typesJson;
  final String? mode;
  final bool isPublished;
  final String? createdAt;

  ProblemSetInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.typesJson,
    required this.mode,
    required this.isPublished,
    required this.createdAt,
  });

  factory ProblemSetInfo.fromJson(Map<String, dynamic> json) {
    return ProblemSetInfo(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String?,
      typesJson: (json['types_json'] as List? ?? []),
      mode: json['mode'] as String?,
      isPublished: (json['is_published'] ?? false) as bool,
      createdAt: json['created_at'] as String?,
    );
  }
}

class PassageInfo {
  final int id;
  final String title;
  final String content;
  final String? createdAt;

  PassageInfo({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory PassageInfo.fromJson(Map<String, dynamic> json) {
    return PassageInfo(
      id: (json['id'] ?? 0) as int,
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      createdAt: json['created_at'] as String?,
    );
  }
}

class QuestionInfo {
  final int id;
  final String questionType;
  final String text;
  final String? explanation;
  final int order;
  final List<OptionInfo> options;

  QuestionInfo({
    required this.id,
    required this.questionType,
    required this.text,
    required this.explanation,
    required this.order,
    required this.options,
  });

  factory QuestionInfo.fromJson(Map<String, dynamic> json) {
    return QuestionInfo(
      id: (json['id'] ?? 0) as int,
      questionType: (json['question_type'] ?? '') as String,
      text: (json['text'] ?? '') as String,
      explanation: json['explanation'] as String?,
      order: (json['order'] ?? 0) as int,
      options: (json['options'] as List? ?? [])
          .map((e) => OptionInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OptionInfo {
  final int id;
  final String label;
  final String text;
  final bool isCorrect;

  OptionInfo({
    required this.id,
    required this.label,
    required this.text,
    required this.isCorrect,
  });

  factory OptionInfo.fromJson(Map<String, dynamic> json) {
    return OptionInfo(
      id: (json['id'] ?? 0) as int,
      label: (json['label'] ?? '') as String,
      text: (json['text'] ?? '') as String,
      isCorrect: (json['is_correct'] ?? false) as bool,
    );
  }
}
