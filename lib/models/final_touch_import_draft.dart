class FinalTouchImportDraft {
  const FinalTouchImportDraft({
    this.index = 0,
    this.unitLabel = '',
    required this.source,
    required this.title,
    required this.topic,
    required this.gist,
    required this.outline,
    required this.passage,
    required this.passageBracketed,
    required this.sentenceDetails,
    required this.rawText,
    required this.warnings,
  });

  final int index;
  final String unitLabel;
  final String source;
  final String title;
  final String topic;
  final String gist;
  final Map<String, String> outline;
  final String passage;
  final String passageBracketed;
  final List<Map<String, dynamic>> sentenceDetails;
  final String rawText;
  final List<String> warnings;

  bool get canSave => passage.trim().isNotEmpty;
  String get displayLabel {
    if (unitLabel.trim().isNotEmpty) return unitLabel.trim();
    if (source.trim().isNotEmpty) return source.trim();
    if (title.trim().isNotEmpty) return title.trim();
    return '후보 ${index + 1}';
  }

  Map<String, dynamic> toRequestJson({int? folderId}) {
    final titleIsKorean = RegExp(r'[가-힣]').hasMatch(title);
    final topicIsKorean = RegExp(r'[가-힣]').hasMatch(topic);
    final gistIsKorean = RegExp(r'[가-힣]').hasMatch(gist);
    final translation = _combinedTranslation();
    return {
      'source': source,
      'passage': passage,
      'passage_bracketed': passageBracketed,
      'title_en': titleIsKorean ? '' : title,
      'title_ko': titleIsKorean ? title : '',
      'topic_en': topicIsKorean ? '' : topic,
      'topic_ko': topicIsKorean ? topic : '',
      'gist_en': gistIsKorean ? '' : gist,
      'gist_ko': gistIsKorean ? gist : '',
      'summary_ko': gistIsKorean ? gist : '',
      'translation_bracketed': translation,
      'outline': outline,
      'sentence_details': sentenceDetails,
      if (folderId != null) 'folder_id': folderId,
    };
  }

  String _combinedTranslation() {
    return sentenceDetails
        .map((item) {
          final translation =
              item['translation_bracketed'] ?? item['translation'] ?? '';
          return translation.toString().trim();
        })
        .where((translation) => translation.isNotEmpty)
        .join('\n\n');
  }
}

class FinalTouchImportResult {
  const FinalTouchImportResult({
    required this.rawText,
    required this.drafts,
    this.globalWarnings = const [],
  });

  final String rawText;
  final List<FinalTouchImportDraft> drafts;
  final List<String> globalWarnings;
}
