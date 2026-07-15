import 'package:flutter/material.dart';

class FinalTouchCoreAnalysis extends StatelessWidget {
  const FinalTouchCoreAnalysis({
    super.key,
    required this.topicEn,
    required this.topicKo,
    required this.titleEn,
    required this.titleKo,
    required this.gistEn,
    required this.gistKo,
    this.topicFallback = '',
    this.titleFallback = '',
    this.gistFallback = '',
    this.summaryEn = '',
    this.summaryKo = '',
  });

  final String topicEn;
  final String topicKo;
  final String titleEn;
  final String titleKo;
  final String gistEn;
  final String gistKo;
  final String topicFallback;
  final String titleFallback;
  final String gistFallback;
  final String summaryEn;
  final String summaryKo;

  @override
  Widget build(BuildContext context) {
    final points = [
      _CorePoint(
        number: '01',
        title: '핵심 주제',
        hint: '지문이 다루는 중심 소재와 핵심 메시지',
        english: _englishOnly(topicEn, fallback: topicFallback),
        korean: _koreanOnly(topicKo, fallback: topicFallback),
      ),
      _CorePoint(
        number: '02',
        title: '제목',
        hint: '학생이 기억해야 할 대표 제목과 핵심 표현',
        english: _englishOnly(titleEn, fallback: titleFallback),
        korean: _koreanOnly(titleKo, fallback: titleFallback),
      ),
      _CorePoint(
        number: '03',
        title: '요지',
        hint: '문제 풀이에서 잡아야 할 글쓴이의 방향',
        english: _englishOnly(gistEn, fallback: gistFallback),
        korean: _koreanOnly(gistKo, fallback: gistFallback),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFF), Color(0xFFF6F8FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E0F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final useThreeColumns = constraints.maxWidth >= 980;
              final useTwoColumns = constraints.maxWidth >= 680;
              if (!useTwoColumns) {
                return Column(
                  children: [
                    for (var i = 0; i < points.length; i++) ...[
                      _CorePointCard(point: points[i]),
                      if (i != points.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              final columns = useThreeColumns ? 3 : 2;
              const spacing = 10.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final point in points)
                    SizedBox(width: width, child: _CorePointCard(point: point)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: Color(0xFF1E2E4F),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '핵심 분석',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '주제 · 제목 · 요지를 EN/KO로 분리해 수업용 핵심만 정리합니다.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CorePoint {
  const _CorePoint({
    required this.number,
    required this.title,
    required this.hint,
    required this.english,
    required this.korean,
  });

  final String number;
  final String title;
  final String hint;
  final String english;
  final String korean;
}

class _CorePointCard extends StatelessWidget {
  const _CorePointCard({required this.point});

  final _CorePoint point;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 158),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2E4F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  point.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  point.title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _BulletText(point.hint),
          const SizedBox(height: 9),
          _ValueBlock(label: 'EN', value: point.english),
          const SizedBox(height: 7),
          _ValueBlock(label: 'KO', value: point.korean),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '•',
          style: TextStyle(
            color: Color(0xFF1E2E4F),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isEnglish = label == 'EN';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          padding: const EdgeInsets.symmetric(vertical: 3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1E2E4F),
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _displayText(value),
            style: TextStyle(
              color:
                  isEnglish ? const Color(0xFF262626) : const Color(0xFF8C8C8C),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

String _englishOnly(String value, {String fallback = ''}) {
  final parts = _languageParts(value);
  if (parts.english.isNotEmpty) return parts.english.join('\n').trim();
  final fallbackParts = _languageParts(fallback);
  return fallbackParts.english.join('\n').trim();
}

String _koreanOnly(String value, {String fallback = ''}) {
  final parts = _languageParts(value);
  if (parts.korean.isNotEmpty) return parts.korean.join('\n').trim();
  final fallbackParts = _languageParts(fallback);
  return fallbackParts.korean.join('\n').trim();
}

({List<String> english, List<String> korean}) _languageParts(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return (english: const [], korean: const []);

  final english = <String>[];
  final korean = <String>[];
  final lines = trimmed
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .where((line) => !_isFlowLabel(line))
      .toList();

  for (final line in lines) {
    final chunks = _splitMixedLanguageLine(line);
    for (final chunk in chunks) {
      if (_isFlowLabel(chunk)) continue;
      if (_isEnglishChunk(chunk)) {
        english.add(chunk);
      } else if (_isKoreanChunk(chunk)) {
        korean.add(_removeLatinFragments(chunk));
      }
    }
  }

  return (
    english: english.where((item) => item.trim().isNotEmpty).toList(),
    korean: korean.where((item) => item.trim().isNotEmpty).toList(),
  );
}

List<String> _splitMixedLanguageLine(String value) {
  final normalized = value
      .replaceAll(RegExp(r'\s+[\/|]\s+'), '\n')
      .replaceAll(RegExp(r'\s+[–—]\s+'), '\n')
      .replaceAll(RegExp(r'\s{2,}'), '\n');
  final chunks = normalized
      .split('\n')
      .map((chunk) => chunk.trim())
      .where((chunk) => chunk.isNotEmpty)
      .toList();

  final result = <String>[];
  for (final chunk in chunks) {
    final labelSplit = _splitLanguageLabelChunk(chunk);
    if (labelSplit != null) {
      result.addAll(labelSplit);
      continue;
    }
    if (_hasLatin(chunk) && _hasHangul(chunk)) {
      final firstHangul = RegExp(r'[\uAC00-\uD7A3]').firstMatch(chunk)?.start;
      if (firstHangul != null && firstHangul > 0) {
        final before = _trimLanguageSeparator(chunk.substring(0, firstHangul));
        final after = _trimLanguageSeparator(chunk.substring(firstHangul));
        if (_isMeaningfulEnglish(before) && !_hasHangul(before)) {
          if (before.isNotEmpty) result.add(before);
          if (after.isNotEmpty) result.add(after);
        } else {
          result.add(chunk);
        }
        continue;
      }
    }
    result.add(chunk);
  }
  return result;
}

List<String>? _splitLanguageLabelChunk(String value) {
  final match = RegExp(
    r'^\s*(?:EN|영어|주제|제목|요지|핵심\s*주제)\s*[:：]\s*(.+)$',
    caseSensitive: false,
  ).firstMatch(value);
  if (match == null) return null;
  final content = _trimLanguageSeparator(match.group(1) ?? '');
  if (content.isEmpty) return const [];
  return _splitMixedLanguageLine(content);
}

String _trimLanguageSeparator(String value) {
  return value
      .replaceAll(RegExp(r'^[\s:：\-–—\/|]+'), '')
      .replaceAll(RegExp(r'[\s:：\-–—\/|]+$'), '')
      .trim();
}

bool _isEnglishChunk(String value) {
  final trimmed = _trimLanguageSeparator(value);
  return _isMeaningfulEnglish(trimmed) && !_hasHangul(trimmed);
}

bool _isKoreanChunk(String value) {
  final trimmed = _trimLanguageSeparator(value);
  return _hasHangul(trimmed);
}

String _removeLatinFragments(String value) {
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
  return _trimLanguageSeparator(text.replaceAll(RegExp(r'\s+'), ' '));
}

bool _isFlowLabel(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  return normalized.contains('글의흐름') ||
      RegExp(r'^(flow|서론|본론|결론)(\d|[:：]|$)').hasMatch(normalized);
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

String _displayText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '분석 준비 중' : trimmed;
}
