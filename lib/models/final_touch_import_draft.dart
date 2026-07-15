class FinalTouchImportDraft {
  const FinalTouchImportDraft({
    this.index = 0,
    this.unitLabel = '',
    required this.source,
    required this.title,
    this.titleEn = '',
    this.titleKo = '',
    required this.topic,
    this.topicEn = '',
    this.topicKo = '',
    required this.gist,
    this.gistEn = '',
    this.gistKo = '',
    required this.outline,
    required this.passage,
    required this.passageBracketed,
    this.translationText = '',
    required this.sentenceDetails,
    required this.rawText,
    required this.warnings,
  });

  final int index;
  final String unitLabel;
  final String source;
  final String title;
  final String titleEn;
  final String titleKo;
  final String topic;
  final String topicEn;
  final String topicKo;
  final String gist;
  final String gistEn;
  final String gistKo;
  final Map<String, String> outline;
  final String passage;
  final String passageBracketed;
  final String translationText;
  final List<Map<String, dynamic>> sentenceDetails;
  final String rawText;
  final List<String> warnings;

  bool get canSave => passage.trim().isNotEmpty;

  int get englishSentenceCount => sentenceDetails.length;

  int get translationSentenceCount {
    final perSentenceCount = sentenceDetails
        .where((item) => _itemTranslation(item).isNotEmpty)
        .length;
    if (perSentenceCount > 0) return perSentenceCount;
    return _splitTranslation(translationText).length;
  }

  String get combinedTranslation {
    final sentenceTranslation = _combinedSentenceTranslation();
    if (sentenceTranslation.trim().isNotEmpty) return sentenceTranslation;
    return translationText.trim();
  }

  String get displayLabel {
    if (unitLabel.trim().isNotEmpty) return unitLabel.trim();
    if (source.trim().isNotEmpty) return source.trim();
    if (title.trim().isNotEmpty) return title.trim();
    if (titleEn.trim().isNotEmpty) return titleEn.trim();
    if (titleKo.trim().isNotEmpty) return titleKo.trim();
    return '후보 ${index + 1}';
  }

  FinalTouchImportDraft copyWith({
    String? source,
    String? title,
    String? titleEn,
    String? titleKo,
    String? topic,
    String? topicEn,
    String? topicKo,
    String? gist,
    String? gistEn,
    String? gistKo,
    Map<String, String>? outline,
    String? passage,
    String? passageBracketed,
    String? translationText,
    List<Map<String, dynamic>>? sentenceDetails,
    String? rawText,
    List<String>? warnings,
  }) {
    return FinalTouchImportDraft(
      index: index,
      unitLabel: unitLabel,
      source: source ?? this.source,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      titleKo: titleKo ?? this.titleKo,
      topic: topic ?? this.topic,
      topicEn: topicEn ?? this.topicEn,
      topicKo: topicKo ?? this.topicKo,
      gist: gist ?? this.gist,
      gistEn: gistEn ?? this.gistEn,
      gistKo: gistKo ?? this.gistKo,
      outline: outline ?? this.outline,
      passage: passage ?? this.passage,
      passageBracketed: passageBracketed ?? this.passageBracketed,
      translationText: translationText ?? this.translationText,
      sentenceDetails: sentenceDetails ?? this.sentenceDetails,
      rawText: rawText ?? this.rawText,
      warnings: warnings ?? this.warnings,
    );
  }

  Map<String, dynamic> toRequestJson({
    int? folderId,
    String? textbookFolderName,
    String? unitFolderName,
    String? folderName,
  }) {
    final effectiveTitleEn = _englishValue(titleEn, title);
    final effectiveTitleKo = _koreanValue(titleKo, title);
    final effectiveTopicEn = _englishValue(topicEn, topic);
    final effectiveTopicKo = _koreanValue(topicKo, topic);
    final effectiveGistEn = _englishValue(gistEn, gist);
    final effectiveGistKo = _koreanValue(gistKo, gist);
    final translation = combinedTranslation;
    final normalizedSentenceDetails =
        _sentenceDetailsWithFallbackTranslations(sentenceDetails, translation);
    return {
      'source': source,
      'passage': passage,
      'passage_bracketed': passageBracketed,
      'title_en': effectiveTitleEn,
      'title_ko': effectiveTitleKo,
      'topic_en': effectiveTopicEn,
      'topic_ko': effectiveTopicKo,
      'gist_en': effectiveGistEn,
      'gist_ko': effectiveGistKo,
      'summary_en': effectiveGistEn,
      'summary_ko': effectiveGistKo,
      'translation_bracketed': translation,
      'outline': outline,
      'sentence_details': normalizedSentenceDetails,
      if (folderId != null) 'folder_id': folderId,
      if (textbookFolderName?.trim().isNotEmpty == true)
        'textbook_folder_name': textbookFolderName!.trim(),
      if (unitFolderName?.trim().isNotEmpty == true)
        'unit_folder_name': unitFolderName!.trim(),
      if (folderName?.trim().isNotEmpty == true)
        'folder_name': folderName!.trim(),
    };
  }

  String _combinedSentenceTranslation() {
    return sentenceDetails
        .map(_itemTranslation)
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

List<Map<String, dynamic>> _sentenceDetailsWithFallbackTranslations(
  List<Map<String, dynamic>> details,
  String translation,
) {
  if (details.isEmpty) return const [];
  final parts = _splitTranslation(translation);
  final shouldRedistribute = parts.length > 1 &&
      (details.where((item) => _itemTranslation(item).isNotEmpty).length <
          details.length);
  return [
    for (var index = 0; index < details.length; index++)
      {
        ...details[index],
        if (_itemTranslation(details[index]).isEmpty &&
            index < parts.length &&
            parts[index].trim().isNotEmpty)
          'translation': parts[index].trim(),
        if (_itemTranslation(details[index]).isEmpty &&
            index < parts.length &&
            parts[index].trim().isNotEmpty)
          'translation_bracketed': parts[index].trim(),
        if (shouldRedistribute && index < parts.length)
          'translation': parts[index].trim(),
        if (shouldRedistribute && index < parts.length)
          'translation_bracketed': parts[index].trim(),
      },
  ];
}

String _itemTranslation(Map<String, dynamic> item) {
  return (item['translation_bracketed'] ?? item['translation'] ?? '')
      .toString()
      .trim();
}

List<String> _splitTranslation(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];
  final lines = trimmed
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) =>
          line.replaceFirst(RegExp(r'^[\u2460-\u2473]\s*'), '').trim())
      .map((line) => line.replaceFirst(RegExp(r'^\d+[\.)]\s*'), '').trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.length > 1) return lines;
  final compact = trimmed.replaceAll(RegExp(r'\s+'), ' ');
  final matches = RegExp(
    r'.+?(?:[.!?\u3002\uff01\uff1f]|(?:\uB2E4|\uC694|\uC8E0|\uB2C8\uB2E4|\uAE4C\uC694|\uC138\uC694|\uD574\uC694|\uD569\uB2C8\uB2E4|\uB429\uB2C8\uB2E4|\uC788\uC2B5\uB2C8\uB2E4|\uC5C6\uC2B5\uB2C8\uB2E4)(?=\s|$))',
  ).allMatches(compact);
  final parts = matches
      .map((match) => match.group(0)?.trim() ?? '')
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isNotEmpty) return parts;
  return [trimmed];
}

String _englishValue(String explicitValue, String fallback) {
  final explicit = explicitValue.trim();
  final explicitEnglish = _languageParts(explicit).english;
  if (explicitEnglish.isNotEmpty) return explicitEnglish.first;
  final fallbackEnglish = _languageParts(fallback).english;
  return fallbackEnglish.isNotEmpty ? fallbackEnglish.first : '';
}

String _koreanValue(String explicitValue, String fallback) {
  final explicit = explicitValue.trim();
  final explicitKorean = _languageParts(explicit).korean;
  if (explicitKorean.isNotEmpty) return explicitKorean.join('\n');
  final fallbackKorean = _languageParts(fallback).korean;
  return fallbackKorean.join('\n');
}

({List<String> english, List<String> korean}) _languageParts(String value) {
  final trimmed = _removeFlowTail(value.trim());
  if (trimmed.isEmpty) return (english: const [], korean: const []);
  final english = <String>[];
  final korean = <String>[];
  final chunks = trimmed
      .split(RegExp(r'\r?\n|\s+[|/]\s+|\s+[–—]\s+|\s{2,}'))
      .map((chunk) => chunk.trim())
      .where((chunk) => chunk.isNotEmpty)
      .toList();

  for (final rawChunk in chunks) {
    final chunk = rawChunk
        .replaceFirst(
          RegExp(
            r'^(EN|KO|영어|한국어|주제|제목|요지|요약|Summary|Main\s*Idea)\s*[:：]\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    if (chunk.isEmpty || _isFlowLine(chunk)) continue;

    if (_hasLatin(chunk) && _hasHangul(chunk)) {
      final firstHangul = RegExp(r'[\uAC00-\uD7A3]').firstMatch(chunk)?.start;
      if (firstHangul != null && firstHangul > 0) {
        final before = _trimSeparator(chunk.substring(0, firstHangul));
        final after = _trimSeparator(chunk.substring(firstHangul));
        if (before.isNotEmpty &&
            _isMeaningfulEnglish(before) &&
            !_hasHangul(before)) {
          english.add(before);
          if (after.isNotEmpty && _hasHangul(after)) {
            korean.add(_stripLeadingLatin(after));
          }
        } else if (_hasHangul(chunk)) {
          korean.add(_stripLeadingLatin(chunk));
        }
        continue;
      }
    }

    if (_isMeaningfulEnglish(chunk) && !_hasHangul(chunk)) {
      english.add(_trimSeparator(chunk));
    } else if (_hasHangul(chunk)) {
      korean.add(_stripLeadingLatin(chunk));
    }
  }

  return (
    english: english.where((item) => item.trim().isNotEmpty).toList(),
    korean: korean.where((item) => item.trim().isNotEmpty).toList(),
  );
}

String _removeFlowTail(String value) {
  final lines = value
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  final kept = <String>[];
  for (final line in lines) {
    if (_isFlowLine(line)) break;
    kept.add(line);
  }
  return kept.join('\n').trim();
}

bool _isFlowLine(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  return normalized.contains('글의흐름') ||
      RegExp(r'^(flow|서론|본론|결론)(\d|[:：]|$)').hasMatch(normalized);
}

String _trimSeparator(String value) {
  return value
      .replaceAll(RegExp(r'^[\s:：\-–—/|]+'), '')
      .replaceAll(RegExp(r'[\s:：\-–—/|]+$'), '')
      .trim();
}

String _stripLeadingLatin(String value) {
  var text = value.trim();
  while (true) {
    if (RegExp(r'^[A-Za-z]+[\uAC00-\uD7A3]').hasMatch(text)) break;
    final match =
        RegExp(r"^[A-Za-z][A-Za-z0-9\s,.'’\-:;!?()]+").firstMatch(text);
    if (match == null) break;
    if (!_isMeaningfulEnglish(match.group(0) ?? '')) break;
    final remainder = text.substring(match.end).trim();
    if (!_hasHangul(remainder)) break;
    text = remainder;
  }
  return _trimSeparator(text);
}

bool _hasLatin(String value) => RegExp(r'[A-Za-z]').hasMatch(value);

bool _hasHangul(String value) => RegExp(r'[\uAC00-\uD7A3]').hasMatch(value);

bool _isMeaningfulEnglish(String value) {
  final words = RegExp(r"[A-Za-z]+(?:['’\-][A-Za-z]+)?")
      .allMatches(value)
      .map((match) => match.group(0) ?? '')
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.length >= 4) return true;
  final hasSentencePunctuation = RegExp(r'[.!?]').hasMatch(value);
  return words.length >= 3 && hasSentencePunctuation;
}
