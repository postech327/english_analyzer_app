// lib/models/analyzer_models.dart

/// 단일 스팬(하이라이트) 정보
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

/// 주제/제목/요지 응답
class TopicTitleSummary {
  final String topic;
  final String title;
  final String gistEn;
  final String gistKo;

  const TopicTitleSummary({
    required this.topic,
    required this.title,
    required this.gistEn,
    required this.gistKo,
  });

  factory TopicTitleSummary.fromJson(Map<String, dynamic> j) =>
      TopicTitleSummary(
        topic: (j['topic'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        gistEn: (j['gist_en'] ?? '').toString(),
        gistKo: (j['gist_ko'] ?? '').toString(),
      );
}

/// 단어 유의어 응답(백엔드가 텍스트로 반환)
class WordSynonymsResult {
  final String text;
  const WordSynonymsResult(this.text);

  factory WordSynonymsResult.fromJson(Map<String, dynamic> j) =>
      WordSynonymsResult((j['단어 분석 결과'] ?? '').toString());
}

class McqItem {
  final String stem;
  final List<String> choices;
  final int answerIndex; // 0~4
  final String explanation;

  McqItem({
    required this.stem,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
  });

  factory McqItem.fromJson(Map<String, dynamic> j) => McqItem(
        stem: (j['stem'] ?? '') as String,
        choices:
            (j['choices'] as List? ?? []).map((e) => e.toString()).toList(),
        answerIndex: (j['answer_index'] ?? j['answerIndex'] ?? 0) as int,
        explanation: (j['explanation'] ?? '') as String,
      );
}
