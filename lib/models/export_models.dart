// lib/models/export_models.dart

class OutlineItem {
  final String label;
  final List<String> bullets;
  const OutlineItem({required this.label, this.bullets = const []});

  Map<String, dynamic> toJson() => {
        'label': label,
        'bullets': bullets,
      };
}

class ExportPptRequest {
  final String passage;
  final String? dateStr;
  final int maxWords;

  // (옵션) 화면에서 이미 구한 값들
  final String? topicEn, topicKo;
  final String? titleEn, titleKo;
  final String? gistEn, gistKo;
  final List<OutlineItem>? outline;
  final List<Map<String, dynamic>>? synonyms;

  const ExportPptRequest({
    required this.passage,
    this.dateStr,
    this.maxWords = 12,
    this.topicEn,
    this.topicKo,
    this.titleEn,
    this.titleKo,
    this.gistEn,
    this.gistKo,
    this.outline,
    this.synonyms,
  });

  Map<String, dynamic> toJson() => {
        'passage': passage,
        'date_str': dateStr,
        'max_words': maxWords,
        if (topicEn != null) 'topic_en': topicEn,
        if (topicKo != null) 'topic_ko': topicKo,
        if (titleEn != null) 'title_en': titleEn,
        if (titleKo != null) 'title_ko': titleKo,
        if (gistEn != null) 'gist_en': gistEn,
        if (gistKo != null) 'gist_ko': gistKo,
        if (outline != null)
          'outline': outline!.map((e) => e.toJson()).toList(),
        if (synonyms != null) 'synonyms': synonyms,
      };
}
