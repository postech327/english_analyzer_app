// lib/models/passage_analysis.dart
class PassageAnalysisResult {
  final int passageId;
  final PassageAnalysis analysis;

  PassageAnalysisResult({
    required this.passageId,
    required this.analysis,
  });

  factory PassageAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PassageAnalysisResult(
      passageId: json['passage_id'] as int,
      analysis:
          PassageAnalysis.fromJson(json['analysis'] as Map<String, dynamic>),
    );
  }
}

class PassageAnalysis {
  final String? topicEn;
  final String? topicKo;
  final String? titleEn;
  final String? titleKo;
  final String? gistEn;
  final String? gistKo;
  final String? summaryEn;
  final String? summaryKo;
  final List<StructureItem> structure;
  final FlowSummary? flow;
  final List<VocabItem> vocab;

  PassageAnalysis({
    this.topicEn,
    this.topicKo,
    this.titleEn,
    this.titleKo,
    this.gistEn,
    this.gistKo,
    this.summaryEn,
    this.summaryKo,
    required this.structure,
    this.flow,
    required this.vocab,
  });

  factory PassageAnalysis.fromJson(Map<String, dynamic> json) {
    final structureJson = json['structure'] as List<dynamic>? ?? [];
    final vocabJson = json['vocab'] as List<dynamic>? ?? [];

    return PassageAnalysis(
      topicEn: json['topic_en'] as String?,
      topicKo: json['topic_ko'] as String?,
      titleEn: json['title_en'] as String?,
      titleKo: json['title_ko'] as String?,
      gistEn: json['gist_en'] as String?,
      gistKo: json['gist_ko'] as String?,
      summaryEn: json['summary_en'] as String?,
      summaryKo: json['summary_ko'] as String?,
      structure: structureJson
          .map((e) => StructureItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      flow: json['flow'] != null
          ? FlowSummary.fromJson(json['flow'] as Map<String, dynamic>)
          : null,
      vocab: vocabJson
          .map((e) => VocabItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StructureItem {
  final String sentence;
  final String bracketed;
  final String? note;

  StructureItem({
    required this.sentence,
    required this.bracketed,
    this.note,
  });

  factory StructureItem.fromJson(Map<String, dynamic> json) {
    return StructureItem(
      sentence: json['sentence'] as String? ?? '',
      bracketed: json['bracketed'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}

class FlowSummary {
  final Map<String, dynamic>? intro;
  final List<dynamic> body;
  final Map<String, dynamic>? conclusion;

  FlowSummary({
    this.intro,
    required this.body,
    this.conclusion,
  });

  factory FlowSummary.fromJson(Map<String, dynamic> json) {
    return FlowSummary(
      intro: json['intro'] as Map<String, dynamic>?,
      body: (json['body'] as List<dynamic>? ?? []),
      conclusion: json['conclusion'] as Map<String, dynamic>?,
    );
  }
}

class VocabItem {
  final String word;
  final String meaningKo;
  final List<String> synonyms;

  VocabItem({
    required this.word,
    required this.meaningKo,
    required this.synonyms,
  });

  factory VocabItem.fromJson(Map<String, dynamic> json) {
    final syn = json['synonyms'] as List<dynamic>? ?? [];
    return VocabItem(
      word: json['word'] as String? ?? '',
      meaningKo: json['meaning_ko'] as String? ?? '',
      synonyms: syn.map((e) => e.toString()).toList(),
    );
  }
}
