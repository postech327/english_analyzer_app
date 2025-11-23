import 'dart:convert';

/// 보기(선지)
class TeacherOption {
  final String label; // 'A', 'B', 'C' ...
  final String text; // 보기 문장
  final bool isCorrect; // 정답 여부

  TeacherOption({
    required this.label,
    required this.text,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'text': text,
        'is_correct': isCorrect,
      };
}

/// 객관식/주관식 등 문제 1개
class TeacherQuestion {
  final String questionType; // 예: 'mcq'
  final String stem; // 문제 질문 문장
  final List<TeacherOption> options; // 보기 리스트

  TeacherQuestion({
    required this.questionType,
    required this.stem,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
        'question_type': questionType,
        'stem': stem,
        'options': options.map((o) => o.toJson()).toList(),
      };
}
