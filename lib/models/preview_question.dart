class PreviewQuestion {
  final int order;
  final String questionType;
  final String text;
  final List<String> options;
  final int answerIndex;

  PreviewQuestion({
    required this.order,
    required this.questionType,
    required this.text,
    required this.options,
    required this.answerIndex,
  });

  factory PreviewQuestion.fromJson(Map<String, dynamic> json) {
    return PreviewQuestion(
      order: json['order'],
      questionType: json['question_type'],
      text: json['text'],
      options: List<String>.from(json['options']),
      answerIndex: json['answer_index'],
    );
  }
}
