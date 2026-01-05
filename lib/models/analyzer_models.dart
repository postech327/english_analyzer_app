class Span {
  final int start;
  final int end;
  final String type;

  const Span({
    required this.start,
    required this.end,
    required this.type,
  });

  factory Span.fromJson(Map<String, dynamic> j) => Span(
        start: (j['start'] ?? 0) as int,
        end: (j['end'] ?? 0) as int,
        type: (j['type'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'type': type,
      };

  @override
  String toString() => 'Span($start,$end,$type)';
}

/// 한 문장 분석 결과
class SentenceResult {
  final int index;
  final String text;
  final String analyzedText;
  final List<Span> spans;

  const SentenceResult({
    required this.index,
    required this.text,
    required this.analyzedText,
    required this.spans,
  });

  factory SentenceResult.fromJson(Map<String, dynamic> j) => SentenceResult(
        index: (j['index'] ?? 0) as int,
        text: (j['text'] ?? '') as String,
        analyzedText: (j['analyzed_text'] ?? '') as String,
        spans: (j['spans'] as List? ?? const [])
            .map((e) => Span.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'index': index,
        'text': text,
        'analyzed_text': analyzedText,
        'spans': spans.map((e) => e.toJson()).toList(),
      };
}

/// 문단 분석 응답
class ParagraphResponse {
  final bool ok;
  final List<SentenceResult> sentences;
  final String fullText;
  final String fullAnalyzed;

  const ParagraphResponse({
    required this.ok,
    required this.sentences,
    required this.fullText,
    required this.fullAnalyzed,
  });

  factory ParagraphResponse.fromJson(Map<String, dynamic> j) =>
      ParagraphResponse(
        ok: (j['ok'] ?? false) as bool,
        sentences: (j['sentences'] as List? ?? const [])
            .map((e) => SentenceResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        fullText: ((j['full'] ?? const {}) as Map)['text']?.toString() ?? '',
        fullAnalyzed:
            ((j['full'] ?? const {}) as Map)['analyzed_text']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'sentences': sentences.map((e) => e.toJson()).toList(),
        'full': {
          'text': fullText,
          'analyzed_text': fullAnalyzed,
        }
      };
}

/// 🔥 주제/제목/요지/요약 + 서론/본론/결론 통합 응답
class TopicTitleSummary {
  // 기존에 쓰던 필드들 (그대로 유지)
  final String topic; // 영어 주제
  final String title; // 영어 제목
  final String gistEn; // 요지(영어)
  final String gistKo; // 요지(한글)

  // 새로 확장된 필드들
  final String topicKo; // 주제(한글)
  final String titleKo; // 제목(한글)
  final String summaryEn; // 요약(영어)
  final String summaryKo; // 요약(한글)
  final String intro; // 서론
  final String body; // 본론
  final String conclusion; // 결론

  const TopicTitleSummary({
    required this.topic,
    required this.title,
    required this.gistEn,
    required this.gistKo,
    required this.topicKo,
    required this.titleKo,
    required this.summaryEn,
    required this.summaryKo,
    required this.intro,
    required this.body,
    required this.conclusion,
  });

  String get topicEn => topic;
  String get titleEn => title;

  factory TopicTitleSummary.fromJson(Map<String, dynamic> j) =>
      TopicTitleSummary(
        // 주제/제목: 백엔드 키가 바뀌어도 최대한 대응
        topic: (j['topic_en'] ?? j['topic'] ?? '').toString(),
        topicKo: (j['topic_ko'] ?? j['topicKo'] ?? '').toString(),
        title: (j['title_en'] ?? j['title'] ?? '').toString(),
        titleKo: (j['title_ko'] ?? j['titleKo'] ?? '').toString(),

        // 요지
        gistEn: (j['gist_en'] ?? '').toString(),
        gistKo: (j['gist_ko'] ?? '').toString(),

        // 요약
        summaryEn: (j['summary_en'] ?? '').toString(),
        summaryKo: (j['summary_ko'] ?? '').toString(),

        // 서론 / 본론 / 결론
        intro: (j['intro'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        conclusion: (j['conclusion'] ?? '').toString(),
      );
}

/// 단어 유의어 응답(백엔드가 텍스트로 반환)
class WordSynonymsResult {
  final String text;
  const WordSynonymsResult(this.text);

  factory WordSynonymsResult.fromJson(Map<String, dynamic> j) =>
      WordSynonymsResult((j['단어 분석 결과'] ?? '').toString());
}

class AnalyzerMcqItem {
  final String stem;
  final List<String> choices;
  final int answerIndex; // 0~4
  final String explanation;

  AnalyzerMcqItem({
    required this.stem,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
  });

  factory AnalyzerMcqItem.fromJson(Map<String, dynamic> j) => AnalyzerMcqItem(
        stem: (j['stem'] ?? '') as String,
        choices:
            (j['choices'] as List? ?? []).map((e) => e.toString()).toList(),
        answerIndex: (j['answer_index'] ?? j['answerIndex'] ?? 0) as int,
        explanation: (j['explanation'] ?? '') as String,
      );
}

class PassageAnalysisResult {
  final int passageId;
  final PassageAnalysis analysis;

  PassageAnalysisResult({
    required this.passageId,
    required this.analysis,
  });

  factory PassageAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PassageAnalysisResult(
      passageId: (json['passage_id'] ?? 0) as int,
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
      sentence: (json['sentence'] ?? '') as String,
      bracketed: (json['bracketed'] ?? '') as String,
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
      word: (json['word'] ?? '') as String,
      meaningKo: (json['meaning_ko'] ?? '') as String,
      synonyms: syn.map((e) => e.toString()).toList(),
    );
  }
}

// ==============================
// 🔥 통합 지문 분석 허브 모델
// ==============================
class TextAnalysisHubResult {
  final int id; // ✅ 새로 추가된 필드
  final String structure; // 괄호 포함 문장 구조
  final String topic; // 주제
  final String title; // 제목
  final String gistEn; // 요지 EN
  final String gistKo; // 요지 KO
  final String summaryEn; // 요약 EN
  final String summaryKo; // 요약 KO
  final String vocab; // 단어/유의어 텍스트

  TextAnalysisHubResult({
    required this.id,
    required this.structure,
    required this.topic,
    required this.title,
    required this.gistEn,
    required this.gistKo,
    required this.summaryEn,
    required this.summaryKo,
    required this.vocab,
  });

  factory TextAnalysisHubResult.fromJson(Map<String, dynamic> json) {
    return TextAnalysisHubResult(
      id: (json['id'] ?? 0) as int, // ✅ 백엔드 id 받아오기
      structure: (json['structure'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      gistEn: (json['gist_en'] ?? '').toString(),
      gistKo: (json['gist_ko'] ?? '').toString(),
      summaryEn: (json['summary_en'] ?? '').toString(),
      summaryKo: (json['summary_ko'] ?? '').toString(),
      vocab: (json['vocab'] ?? '').toString(),
    );
  }

  /// ✅ /analyses 로 보낼 때 쓸 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'structure': structure,
        'topic': topic,
        'title': title,
        'gist_en': gistEn,
        'gist_ko': gistKo,
        'summary_en': summaryEn,
        'summary_ko': summaryKo,
        'vocab': vocab,
      };
}
