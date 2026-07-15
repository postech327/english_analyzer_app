class FinalTouchSummary {
  final int id;
  final int? passageId;
  final int? folderId;
  final String folderName;
  final String source;
  final String titleEn;
  final String titleKo;
  final String topicEn;
  final String topicKo;
  final String gistEn;
  final String gistKo;
  final String summaryEn;
  final String summaryKo;
  final String translationBracketed;
  final String createdAt;

  const FinalTouchSummary({
    required this.id,
    required this.passageId,
    required this.folderId,
    required this.folderName,
    required this.source,
    required this.titleEn,
    required this.titleKo,
    required this.topicEn,
    required this.topicKo,
    required this.gistEn,
    required this.gistKo,
    required this.summaryEn,
    required this.summaryKo,
    required this.translationBracketed,
    required this.createdAt,
  });

  factory FinalTouchSummary.fromJson(Map<String, dynamic> json) {
    return FinalTouchSummary(
      id: _asInt(json['id']),
      passageId: _asNullableInt(json['passage_id']),
      folderId: _asNullableInt(json['folder_id']),
      folderName: _asString(json['folder_name']).isEmpty
          ? '미분류'
          : _asString(json['folder_name']),
      source: _asString(json['source']),
      titleEn: _asString(json['title_en']),
      titleKo: _asString(json['title_ko']),
      topicEn: _asString(json['topic_en']),
      topicKo: _asString(json['topic_ko']),
      gistEn: _asString(json['gist_en']),
      gistKo: _asString(json['gist_ko']),
      summaryEn: _asString(json['summary_en']),
      summaryKo: _asString(json['summary_ko']),
      translationBracketed: _asString(
        json['translation_bracketed'] ??
            json['korean_translation'] ??
            json['translation_ko'] ??
            json['translation'],
      ),
      createdAt: _asString(json['created_at']),
    );
  }
}

class FinalTouchDetail extends FinalTouchSummary {
  final String passage;
  final String passageBracketed;
  final Map<String, String> outline;
  final List<FinalTouchSentenceDetail> sentenceDetails;

  const FinalTouchDetail({
    required super.id,
    required super.passageId,
    required super.folderId,
    required super.folderName,
    required super.source,
    required super.titleEn,
    required super.titleKo,
    required super.topicEn,
    required super.topicKo,
    required super.gistEn,
    required super.gistKo,
    required super.summaryEn,
    required super.summaryKo,
    required super.translationBracketed,
    required super.createdAt,
    required this.passage,
    required this.passageBracketed,
    required this.outline,
    required this.sentenceDetails,
  });

  factory FinalTouchDetail.fromJson(Map<String, dynamic> json) {
    final summary = FinalTouchSummary.fromJson(json);
    final rawOutline = json['outline'];
    final outline = <String, String>{};

    if (rawOutline is Map) {
      outline['intro'] = _asString(rawOutline['intro']);
      outline['body'] = _asString(rawOutline['body']);
      outline['conclusion'] = _asString(rawOutline['conclusion']);
    }

    return FinalTouchDetail(
      id: summary.id,
      passageId: summary.passageId,
      folderId: summary.folderId,
      folderName: summary.folderName,
      source: summary.source,
      titleEn: summary.titleEn,
      titleKo: summary.titleKo,
      topicEn: summary.topicEn,
      topicKo: summary.topicKo,
      gistEn: summary.gistEn,
      gistKo: summary.gistKo,
      summaryEn: summary.summaryEn,
      summaryKo: summary.summaryKo,
      translationBracketed: summary.translationBracketed,
      createdAt: summary.createdAt,
      passage: _asString(json['passage']),
      passageBracketed: _asString(json['passage_bracketed']),
      outline: outline,
      sentenceDetails: FinalTouchSentenceDetail.listFromJson(
        json['sentence_details'],
      ),
    );
  }
}

class FinalTouchSentenceDetail {
  final int sentenceNo;
  final String original;
  final String translation;
  final String translationBracketed;
  final String bracketed;
  final List<FinalTouchStructureSpan> spans;
  final String sentenceRole;
  final String roleHighlightType;
  final bool isBlankCandidate;
  final List<FinalTouchHighlight> highlights;
  final List<FinalTouchGrammarPoint> grammarPoints;
  final String questionPoint;

  const FinalTouchSentenceDetail({
    required this.sentenceNo,
    required this.original,
    required this.translation,
    required this.translationBracketed,
    required this.bracketed,
    required this.spans,
    required this.sentenceRole,
    required this.roleHighlightType,
    required this.isBlankCandidate,
    required this.highlights,
    required this.grammarPoints,
    required this.questionPoint,
  });

  factory FinalTouchSentenceDetail.fromJson(Map<String, dynamic> json) {
    return FinalTouchSentenceDetail(
      sentenceNo: _asInt(json['sentence_no']),
      original: _asString(json['original']),
      translation: _asString(
        json['translation'] ??
            json['translation_ko'] ??
            json['translationKo'] ??
            json['korean_translation'] ??
            json['koreanTranslation'] ??
            json['meaning_ko'],
      ),
      translationBracketed: _asString(
        json['translation_bracketed'] ??
            json['translationBracketed'] ??
            json['translation'] ??
            json['translation_ko'] ??
            json['translationKo'] ??
            json['korean_translation'],
      ),
      bracketed: _asString(json['bracketed']),
      spans: FinalTouchStructureSpan.listFromJson(json['spans']),
      sentenceRole: _asString(json['sentence_role']),
      roleHighlightType: _asString(json['role_highlight_type']).isEmpty
          ? 'none'
          : _asString(json['role_highlight_type']),
      isBlankCandidate: _asBool(json['is_blank_candidate']),
      highlights: FinalTouchHighlight.listFromJson(json['highlights']),
      grammarPoints: FinalTouchGrammarPoint.listFromJson(
        json['grammar_points'],
      ),
      questionPoint: _asString(json['question_point']),
    );
  }

  static List<FinalTouchSentenceDetail> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => FinalTouchSentenceDetail.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'y';
  }
  return false;
}

class FinalTouchStructureSpan {
  final int start;
  final int end;
  final String type;
  final String role;

  const FinalTouchStructureSpan({
    required this.start,
    required this.end,
    required this.type,
    required this.role,
  });

  factory FinalTouchStructureSpan.fromJson(Map<String, dynamic> json) {
    return FinalTouchStructureSpan(
      start: _asInt(json['start']),
      end: _asInt(json['end']),
      type: _asString(json['type']),
      role: _asString(json['role']),
    );
  }

  static List<FinalTouchStructureSpan> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => FinalTouchStructureSpan.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}

class FinalTouchGrammarPoint {
  final String target;
  final String label;
  final String explanation;
  final int? referenceNo;

  const FinalTouchGrammarPoint({
    required this.target,
    required this.label,
    required this.explanation,
    required this.referenceNo,
  });

  factory FinalTouchGrammarPoint.fromJson(Map<String, dynamic> json) {
    return FinalTouchGrammarPoint(
      target: _asString(json['target']),
      label: _asString(json['label']),
      explanation: _asString(json['explanation']),
      referenceNo: _asNullableInt(json['reference_no']),
    );
  }

  static List<FinalTouchGrammarPoint> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => FinalTouchGrammarPoint.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where(
          (item) =>
              item.target.trim().isNotEmpty &&
              item.label.trim().isNotEmpty &&
              item.explanation.trim().isNotEmpty,
        )
        .toList();
  }
}

class FinalTouchHighlight {
  final String text;
  final String type;
  final String memo;

  const FinalTouchHighlight({
    required this.text,
    required this.type,
    required this.memo,
  });

  factory FinalTouchHighlight.fromJson(Map<String, dynamic> json) {
    return FinalTouchHighlight(
      text: _asString(json['text']),
      type: _asString(json['type']),
      memo: _asString(json['memo']),
    );
  }

  static List<FinalTouchHighlight> listFromJson(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => FinalTouchHighlight.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}

class FinalTouchFolder {
  final int? id;
  final int? parentId;
  final String name;
  final int count;
  final bool hasChildren;
  final bool isUnfiled;
  final bool isDirectBucket;

  const FinalTouchFolder({
    required this.id,
    required this.parentId,
    required this.name,
    required this.count,
    required this.hasChildren,
    required this.isUnfiled,
    required this.isDirectBucket,
  });

  factory FinalTouchFolder.fromJson(Map<String, dynamic> json) {
    final name = _asString(json['folder_name'] ?? json['name']);
    return FinalTouchFolder(
      id: _asNullableInt(json['folder_id'] ?? json['id']),
      parentId: _asNullableInt(json['parent_id']),
      name: name.isEmpty ? '미분류' : name,
      count: _asInt(json['count']),
      hasChildren: json['has_children'] == true,
      isUnfiled: json['is_unfiled'] == true,
      isDirectBucket: json['is_direct_bucket'] == true,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

String _asString(dynamic value) => value?.toString() ?? '';
