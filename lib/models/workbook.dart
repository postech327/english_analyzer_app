class Workbook {
  const Workbook({
    required this.id,
    required this.title,
    required this.status,
    required this.questionCount,
    int? totalQuestionCount,
    this.description,
    this.sourceLabel,
    this.folderName,
    this.unitLabel,
    this.finalTouchId,
    this.createdAt,
    this.updatedAt,
    this.questions = const [],
    this.sections = const [],
  }) : totalQuestionCount = totalQuestionCount ?? questionCount;

  final int id;
  final String title;
  final String? description;
  final String? sourceLabel;
  final String? folderName;
  final String? unitLabel;
  final int? finalTouchId;
  final String status;
  final int questionCount;
  final int totalQuestionCount;
  final String? createdAt;
  final String? updatedAt;
  final List<WorkbookQuestion> questions;
  final List<WorkbookSection> sections;

  factory Workbook.fromJson(Map<String, dynamic> json) {
    final questions = WorkbookQuestion.listFromJson(json['questions']);
    return Workbook(
      id: _asInt(json['workbook_id'] ?? json['id']),
      title: _asString(json['title'], fallback: '워크북'),
      description: _nullableString(json['description']),
      sourceLabel: _nullableString(json['source_label']),
      folderName: _nullableString(json['folder_name']),
      unitLabel: _nullableString(json['unit_label']),
      finalTouchId: _nullableInt(json['final_touch_id']),
      status: _asString(json['status'], fallback: 'draft'),
      questionCount: _asInt(json['question_count'], fallback: questions.length),
      totalQuestionCount: _asInt(
        json['total_question_count'],
        fallback: _asInt(json['question_count'], fallback: questions.length),
      ),
      createdAt: _nullableString(json['created_at']),
      updatedAt: _nullableString(json['updated_at']),
      questions: questions,
      sections: WorkbookSection.listFromJson(json['sections']),
    );
  }

  static List<Workbook> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Workbook.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class WorkbookSection {
  const WorkbookSection({
    required this.id,
    required this.workbookId,
    required this.title,
    this.sourceLabel,
    this.unitLabel,
    this.sectionKey,
    this.sortOrder = 0,
    this.questionCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int workbookId;
  final String title;
  final String? sourceLabel;
  final String? unitLabel;
  final String? sectionKey;
  final int sortOrder;
  final int questionCount;
  final String? createdAt;
  final String? updatedAt;

  factory WorkbookSection.fromJson(Map<String, dynamic> json) {
    return WorkbookSection(
      id: _asInt(json['section_id'] ?? json['id']),
      workbookId: _asInt(json['workbook_id']),
      title: _asString(json['title'], fallback: '미분류'),
      sourceLabel: _nullableString(json['source_label']),
      unitLabel: _nullableString(json['unit_label']),
      sectionKey: _nullableString(json['section_key']),
      sortOrder: _asInt(json['sort_order']),
      questionCount: _asInt(json['question_count']),
      createdAt: _nullableString(json['created_at']),
      updatedAt: _nullableString(json['updated_at']),
    );
  }

  static List<WorkbookSection> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
            (item) => WorkbookSection.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class WorkbookQuestion {
  const WorkbookQuestion({
    required this.id,
    required this.questionType,
    required this.orderIndex,
    required this.prompt,
    required this.answer,
    this.content = const {},
    this.passageText,
    this.choices = const [],
    this.explanation,
    this.points = 1,
    this.sectionId,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String questionType;
  final int orderIndex;
  final String prompt;
  final String? passageText;
  final List<String> choices;
  final Map<String, dynamic> answer;
  final Map<String, dynamic> content;
  final String? explanation;
  final int points;
  final int? sectionId;
  final String? createdAt;
  final String? updatedAt;

  factory WorkbookQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'];
    return WorkbookQuestion(
      id: _asInt(json['question_id'] ?? json['id']),
      questionType: _asString(json['question_type']),
      orderIndex: _asInt(json['order_index'], fallback: 1),
      prompt: _asString(json['prompt']),
      passageText: _nullableString(json['passage_text']),
      choices: rawChoices is List
          ? rawChoices.map((item) => item.toString()).toList()
          : const [],
      answer: json['answer'] is Map
          ? Map<String, dynamic>.from(json['answer'] as Map)
          : const {},
      content: json['content'] is Map
          ? Map<String, dynamic>.from(json['content'] as Map)
          : (json['answer'] is Map
              ? Map<String, dynamic>.from(json['answer'] as Map)
              : const {}),
      explanation: _nullableString(json['explanation']),
      points: _asInt(json['points'], fallback: 1),
      sectionId: _nullableInt(json['section_id']),
      createdAt: _nullableString(json['created_at']),
      updatedAt: _nullableString(json['updated_at']),
    );
  }

  static List<WorkbookQuestion> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) =>
            WorkbookQuestion.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

String workbookStatusLabel(String status) {
  return switch (status) {
    'published' => '게시',
    'archived' => '보관',
    _ => '초안',
  };
}

String workbookQuestionTypeLabel(String type) {
  return switch (type) {
    'inline_choice' => '본문 선택형',
    'check_learning_set' => '확인학습',
    'initial_blank' => '첫 글자 빈칸',
    'sentence_insertion' => '문장 삽입',
    'paragraph_order' => '문단 배열',
    'multiple_choice' => '선택형',
    'check_learning' => '확인학습',
    'true_false' => 'T/F',
    _ => type,
  };
}

String workbookQuestionDisplayLabel(WorkbookQuestion question) {
  if (question.questionType == 'true_false') {
    final subtype = question.content['subtype'] ?? question.answer['subtype'];
    if (subtype == 'true_false_en') return '영어 T/F';
    if (subtype == 'true_false_ko') return '한글 T/F';
  }
  return workbookQuestionTypeLabel(question.questionType);
}

String workbookEditorTypeForQuestion(WorkbookQuestion question) {
  if (question.questionType == 'true_false') {
    final subtype = question.answer['subtype'] ?? question.content['subtype'];
    if (subtype == 'true_false_en') return 'true_false_en';
    if (subtype == 'true_false_ko') return 'true_false_ko';
  }
  return question.questionType;
}

String workbookAnswerSummary(WorkbookQuestion question) {
  final answer = question.answer;
  switch (question.questionType) {
    case 'inline_choice':
      final items = question.answer['items'];
      final count = items is List ? items.length : 0;
      return count > 0 ? '$count개 선택 항목' : '선택 항목 미설정';
    case 'check_learning_set':
      final sectionB = answer['section_b'];
      final wordBankCount = sectionB is Map && sectionB['word_bank'] is List
          ? (sectionB['word_bank'] as List).length
          : 0;
      final blankCount = sectionB is Map ? _asInt(sectionB['blank_count']) : 0;
      final answerCount = sectionB is Map && sectionB['answers'] is List
          ? (sectionB['answers'] as List).length
          : 0;
      return '보기 $wordBankCount개 · 빈칸 $blankCount개 · 정답 $answerCount개';
    case 'initial_blank':
      final items = answer['items'];
      final count = items is List ? items.length : 0;
      return '빈칸 $count개';
    case 'sentence_insertion':
      final positions = answer['positions'];
      final count = positions is List ? positions.length : 0;
      return '위치 $count개';
    case 'paragraph_order':
      final segments = answer['segments'];
      final count = segments is List ? segments.length : 0;
      return 'A/B/C $count개';
    case 'multiple_choice':
      final index = _asInt(answer['answer_index'], fallback: -1);
      return index >= 0 ? '${index + 1}번' : '정답 미설정';
    case 'check_learning':
      return _asString(answer['answer_text'], fallback: '모범답안 미설정');
    case 'true_false':
      final items = answer['items'];
      if (items is List && items.isNotEmpty) {
        return '${items.length}개 T/F 문항';
      }
      return answer['answer'] == true ? 'O / 맞음' : 'X / 틀림';
    default:
      return answer.toString();
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  final parsed = _asInt(value, fallback: -1);
  return parsed < 0 ? null : parsed;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') return fallback;
  return text;
}

String? _nullableString(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : text;
}
