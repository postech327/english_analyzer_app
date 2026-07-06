class FinalTouchImportDraft {
  const FinalTouchImportDraft({
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

  Map<String, dynamic> toRequestJson({int? folderId}) {
    final titleIsKorean = RegExp(r'[가-힣]').hasMatch(title);
    final topicIsKorean = RegExp(r'[가-힣]').hasMatch(topic);
    final gistIsKorean = RegExp(r'[가-힣]').hasMatch(gist);
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
      'outline': outline,
      'sentence_details': sentenceDetails,
      if (folderId != null) 'folder_id': folderId,
    };
  }
}
