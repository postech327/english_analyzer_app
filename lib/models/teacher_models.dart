// lib/models/teacher_models.dart
import 'dart:convert';

/// 보기(선지) - 미리보기/DB용
class TeacherOption {
  final String label; // '①', '②' or 'A','B' 등
  final String text; // 보기 문장
  final bool isCorrect;

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

  factory TeacherOption.fromJson(Map<String, dynamic> j) => TeacherOption(
        label: (j['label'] ?? '').toString(),
        text: (j['text'] ?? '').toString(),
        isCorrect: j['is_correct'] == true,
      );

  @override
  String toString() => jsonEncode(toJson());
}

/// 문제 1개 - 미리보기/DB용
class TeacherQuestion {
  final String questionType; // 예: 'mcq'
  final String stem; // 문제 질문 문장
  final List<TeacherOption> options;

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

  factory TeacherQuestion.fromJson(Map<String, dynamic> j) => TeacherQuestion(
        questionType: (j['question_type'] ?? 'mcq').toString(),
        stem: (j['stem'] ?? j['text'] ?? '').toString(),
        options: ((j['options'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => TeacherOption.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );

  @override
  String toString() => jsonEncode(toJson());
}

/// ✅ Question Maker(7개 페이지 + home)에서 공통으로 쓰는 모델
/// - UI에서: stem/options/answerIndex 사용
/// - 저장할 때: toSaveJson() 사용
class McqItem {
  final String stem;
  final List<String> options;
  final int answerIndex;

  /// 부가 정보(선택)
  final Map<String, dynamic> meta;
  final String? explanation;
  final int? order;

  McqItem({
    required this.stem,
    required this.options,
    required this.answerIndex,
    this.meta = const {},
    this.explanation,
    this.order,
  });

  /// ✅ 백엔드 SaveItem 스키마에 맞게 변환
  /// SaveItem: stem/options/answer_index/meta/explanation/order
  Map<String, dynamic> toSaveJson() => {
        'stem': stem,
        'options': options,
        'answer_index': answerIndex,
        'meta': meta,
        'explanation': explanation,
        'order': order,
      };

  factory McqItem.fromJson(Map<String, dynamic> j) {
    final optsRaw = j['options'] ?? j['choices'];
    final options = (optsRaw is List)
        ? optsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final ai = j['answer_index'] ?? j['answerIndex'] ?? 0;

    return McqItem(
      stem: (j['stem'] ?? j['question'] ?? j['text'] ?? '').toString(),
      options: options,
      answerIndex: (ai is num) ? ai.toInt() : int.tryParse(ai.toString()) ?? 0,
      meta: (j['meta'] is Map)
          ? (j['meta'] as Map).map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{},
      explanation: j['explanation']?.toString(),
      order: (j['order'] is num) ? (j['order'] as num).toInt() : null,
    );
  }

  @override
  String toString() => jsonEncode(toSaveJson());
}
