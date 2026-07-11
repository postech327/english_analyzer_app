import 'final_touch.dart';

class FinalTouchReport {
  const FinalTouchReport({
    required this.passageId,
    required this.source,
    required this.textbookFolder,
    required this.unitFolder,
    required this.createdAt,
    required this.passage,
    required this.passageBracketed,
    required this.outline,
    required this.topicEn,
    required this.topicKo,
    required this.titleEn,
    required this.titleKo,
    required this.gistEn,
    required this.gistKo,
    required this.summaryEn,
    required this.summaryKo,
    required this.translationBracketed,
    required this.sentenceDetails,
  });

  final int? passageId;
  final String source;
  final String textbookFolder;
  final String unitFolder;
  final String createdAt;
  final String passage;
  final String passageBracketed;
  final Map<String, String> outline;
  final String topicEn;
  final String topicKo;
  final String titleEn;
  final String titleKo;
  final String gistEn;
  final String gistKo;
  final String summaryEn;
  final String summaryKo;
  final String translationBracketed;
  final List<FinalTouchSentenceDetail> sentenceDetails;

  factory FinalTouchReport.fromAnalysisResult({
    required int? passageId,
    required String source,
    required String textbookFolder,
    required String unitFolder,
    required String passage,
    required Map<String, dynamic> result,
  }) {
    return FinalTouchReport(
      passageId: passageId,
      source: source,
      textbookFolder: textbookFolder,
      unitFolder: unitFolder,
      createdAt: DateTime.now().toIso8601String(),
      passage: passage,
      passageBracketed: _string(result['passage_bracketed']),
      outline: _outline(result['outline']),
      topicEn: _string(result['topic_en']),
      topicKo: _string(result['topic_ko']),
      titleEn: _string(result['title_en']),
      titleKo: _string(result['title_ko']),
      gistEn: _string(result['gist_en']),
      gistKo: _string(result['gist_ko']),
      summaryEn: _string(result['summary_en']),
      summaryKo: _string(result['summary_ko']),
      translationBracketed: _string(
        result['translation_bracketed'] ??
            result['korean_translation_text'] ??
            result['korean_translation'] ??
            result['translation_ko'] ??
            result['translation'],
      ),
      sentenceDetails: FinalTouchSentenceDetail.listFromJson(
        result['sentence_details'],
      ),
    );
  }

  factory FinalTouchReport.fromDetail(FinalTouchDetail detail) {
    return FinalTouchReport(
      passageId: detail.passageId,
      source: detail.source,
      textbookFolder: '',
      unitFolder: detail.folderName,
      createdAt: detail.createdAt,
      passage: detail.passage,
      passageBracketed: detail.passageBracketed,
      outline: detail.outline,
      topicEn: detail.topicEn,
      topicKo: detail.topicKo,
      titleEn: detail.titleEn,
      titleKo: detail.titleKo,
      gistEn: detail.gistEn,
      gistKo: detail.gistKo,
      summaryEn: detail.summaryEn,
      summaryKo: detail.summaryKo,
      translationBracketed: detail.translationBracketed,
      sentenceDetails: detail.sentenceDetails,
    );
  }
}

Map<String, String> _outline(dynamic value) {
  if (value is! Map) return const {};
  return {
    'intro': _string(value['intro'] ?? value['introduction']),
    'body': _string(value['body']),
    'conclusion': _string(value['conclusion']),
  };
}

String _string(dynamic value) => value?.toString() ?? '';
