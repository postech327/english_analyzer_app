import 'package:flutter/material.dart';

import '../models/final_touch.dart';
import 'bracket_colored_text.dart';
import 'final_touch_structured_text.dart';

class FinalTouchSentenceAnalysis extends StatelessWidget {
  const FinalTouchSentenceAnalysis({
    super.key,
    required this.details,
    this.translation = '',
  });

  final List<FinalTouchSentenceDetail> details;
  final String translation;

  @override
  Widget build(BuildContext context) {
    if (details.isEmpty) return const SizedBox.shrink();
    final highlightedIndexes = _visibleHighlightIndexes(details);
    final effectiveTranslation =
        translation.trim().isNotEmpty ? translation : _translationText(details);
    final translationFallbacks = _sentenceTranslationFallbacks(
      effectiveTranslation,
      details.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '\uBB38\uC7A5\uBCC4 \uC138\uBD80 \uBD84\uC11D',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${details.length}\uAC1C \uBB38\uC7A5\uC744 \uC601\uC5B4 \uC6D0\uBB38, \uD574\uC11D, \uBB38\uBC95 \uD3EC\uC778\uD2B8, \uBB38\uC81C\uD654 \uD3EC\uC778\uD2B8 \uC21C\uC11C\uB85C \uC815\uB9AC\uD588\uC2B5\uB2C8\uB2E4.',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        const FinalTouchStructureLegend(),
        const SizedBox(height: 12),
        for (var index = 0; index < details.length; index++) ...[
          _ReadableSentenceAnalysisCard(
            detail: details[index],
            fallbackTranslation: index < translationFallbacks.length
                ? translationFallbacks[index]
                : '',
            highlightType: highlightedIndexes.contains(index)
                ? _effectiveHighlightType(details[index])
                : 'none',
          ),
          if (index != details.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

Set<int> _visibleHighlightIndexes(List<FinalTouchSentenceDetail> details) {
  final candidates = <({int index, int priority})>[];
  for (var index = 0; index < details.length; index++) {
    final type = _effectiveHighlightType(details[index]);
    final priority = _highlightPriority(type);
    if (priority < 99) {
      candidates.add((index: index, priority: priority));
    }
  }
  candidates.sort((a, b) {
    final byPriority = a.priority.compareTo(b.priority);
    if (byPriority != 0) return byPriority;
    return a.index.compareTo(b.index);
  });
  return candidates.take(3).map((item) => item.index).toSet();
}

String _effectiveHighlightType(FinalTouchSentenceDetail detail) {
  final type = detail.roleHighlightType.trim().toLowerCase();
  if (type == 'blank_hint') return 'blank_candidate';
  if (type == 'topic' ||
      type == 'gist' ||
      type == 'conclusion' ||
      type == 'blank_candidate') {
    return type;
  }
  return detail.isBlankCandidate ? 'blank_candidate' : 'none';
}

int _highlightPriority(String type) {
  switch (type) {
    case 'topic':
      return 0;
    case 'gist':
      return 1;
    case 'conclusion':
      return 2;
    case 'blank_candidate':
      return 3;
    default:
      return 99;
  }
}

class FinalTouchFullBracketedPassage extends StatefulWidget {
  const FinalTouchFullBracketedPassage({
    super.key,
    required this.body,
    this.plainBody = '',
    this.sentenceDetails = const [],
    this.topic = '',
    this.title = '',
    this.gist = '',
    this.summary = '',
    this.translation = '',
  });

  final String body;
  final String plainBody;
  final List<FinalTouchSentenceDetail> sentenceDetails;
  final String topic;
  final String title;
  final String gist;
  final String summary;
  final String translation;

  @override
  State<FinalTouchFullBracketedPassage> createState() =>
      _FinalTouchFullBracketedPassageState();
}

class _FinalTouchFullBracketedPassageState
    extends State<FinalTouchFullBracketedPassage> {
  static const double _twoColumnBreakpoint = 840;
  static const double _wideColumnBreakpoint = 1100;

  bool _showBrackets = true;
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final passageText = _passageText(
      bracketed: widget.body,
      plain: widget.plainBody,
      details: widget.sentenceDetails,
      showBrackets: _showBrackets,
    );
    final visiblePassageText =
        _expanded ? passageText : _previewText(passageText, maxCharacters: 520);
    final translationText = widget.translation.trim().isNotEmpty
        ? widget.translation.trim()
        : _translationText(widget.sentenceDetails);
    final visibleTranslationText = _expanded
        ? translationText
        : _previewText(translationText, maxCharacters: 260);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFF), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E0F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F4F46E5),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '전체 지문 한눈에 보기',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '괄호 구조를 보며 지문 전체 흐름을 먼저 확인해요.',
                        style: TextStyle(
                          color: Color(0xFF59657A),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _expanded ? '지문 접기' : '전체 지문 펼치기',
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PassageSummaryPanel(
              topic: widget.topic,
              title: widget.title,
              gist: widget.gist,
              summary: widget.summary,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const BracketLegend(),
                FilterChip(
                  key: const Key('final-touch-bracket-toggle'),
                  selected: _showBrackets,
                  showCheckmark: true,
                  avatar: Icon(
                    _showBrackets
                        ? Icons.data_object_rounded
                        : Icons.notes_rounded,
                    size: 17,
                  ),
                  label: Text(
                    _showBrackets ? '괄호 구조 보기' : '일반 지문 보기',
                  ),
                  onSelected: (selected) {
                    setState(() => _showBrackets = selected);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= _twoColumnBreakpoint;
                final englishPanel = _PassageLanguagePanel(
                  key: const Key('final-touch-english-passage-panel'),
                  icon: Icons.translate_rounded,
                  title: '영어 전체 지문',
                  backgroundColor: Colors.white.withValues(alpha: 0.62),
                  child: _PassageTextBlock(
                    text: visiblePassageText,
                    emptyMessage: '표시할 영어 지문이 없습니다.',
                  ),
                );
                final translationPanel = _PassageLanguagePanel(
                  key: const Key('final-touch-translation-panel'),
                  icon: Icons.menu_book_outlined,
                  title: '한국어 해석',
                  backgroundColor: const Color(0xFFF8FAFC),
                  child: _PassageTextBlock(
                    text: visibleTranslationText,
                    emptyMessage: '해석이 아직 준비되지 않았습니다.',
                    isTranslation: true,
                  ),
                );

                if (!isWide) {
                  return Column(
                    children: [
                      englishPanel,
                      const SizedBox(height: 14),
                      translationPanel,
                    ],
                  );
                }
                final englishFlex =
                    constraints.maxWidth >= _wideColumnBreakpoint ? 7 : 3;
                final translationFlex =
                    constraints.maxWidth >= _wideColumnBreakpoint ? 3 : 2;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: englishFlex, child: englishPanel),
                      const SizedBox(width: 16),
                      Expanded(flex: translationFlex, child: translationPanel),
                    ],
                  ),
                );
              },
            ),
            if (!_expanded &&
                (passageText != visiblePassageText ||
                    translationText != visibleTranslationText)) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = true),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('전체 지문과 해석 보기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PassageSummaryPanel extends StatelessWidget {
  const _PassageSummaryPanel({
    required this.topic,
    required this.title,
    required this.gist,
    required this.summary,
  });

  final String topic;
  final String title;
  final String gist;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _SummaryLine(label: '주제', value: topic),
          const Divider(height: 18, color: Color(0xFFE2E8F0)),
          _SummaryLine(label: '제목', value: title),
          const Divider(height: 18, color: Color(0xFFE2E8F0)),
          _SummaryLine(label: '요지', value: gist, fallback: summary),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.fallback = '',
  });

  final String label;
  final String value;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _summaryDisplayText(label, value, fallback: fallback),
            style: const TextStyle(
              color: Color(0xFF334155),
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

class _PassageLanguagePanel extends StatelessWidget {
  const _PassageLanguagePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.backgroundColor,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1E2E4F)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF25324A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PassageTextBlock extends StatelessWidget {
  const _PassageTextBlock({
    required this.text,
    required this.emptyMessage,
    this.isTranslation = false,
  });

  final String text;
  final String emptyMessage;
  final bool isTranslation;

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return Text(
        emptyMessage,
        style: const TextStyle(
          color: Color(0xFF64748B),
          height: 1.6,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: BracketColoredText(
        text: trimmed,
        style: TextStyle(
          color:
              isTranslation ? const Color(0xFF8C8C8C) : const Color(0xFF262626),
          fontSize: isTranslation ? 12.5 : 14,
          height: isTranslation ? 1.6 : 1.5,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.15,
        ),
      ),
    );
  }
}

String _summaryDisplayText(
  String label,
  String value, {
  String fallback = '',
}) {
  final cleaned = _removeFlowFromSummaryValue(value);
  if (cleaned.trim().isNotEmpty) return cleaned.trim();
  final fallbackCleaned = _removeFlowFromSummaryValue(fallback);
  return fallbackCleaned.trim().isEmpty ? '분석 준비 중' : fallbackCleaned.trim();
}

String _removeFlowFromSummaryValue(String value) {
  final lines = value
      .trim()
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return '';

  final kept = <String>[];
  for (final line in lines) {
    if (_isFlowSummaryLine(line)) break;
    kept.add(line);
  }
  return kept.join('\n').trim();
}

bool _isFlowSummaryLine(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  return normalized.contains('글의흐름') ||
      RegExp(r'^(flow|서론|본론|결론)(\d|[:：]|$)').hasMatch(normalized) ||
      RegExp(r'^\d+[\.)]?(글의흐름|flow)(\d|[:：]|$)').hasMatch(normalized);
}

String _translationText(List<FinalTouchSentenceDetail> details) {
  return details
      .map((detail) {
        final translation = detail.translationBracketed.trim().isNotEmpty
            ? detail.translationBracketed
            : detail.translation;
        return translation.trim();
      })
      .where((translation) => translation.isNotEmpty)
      .join('\n\n');
}

String _passageText({
  required String bracketed,
  required String plain,
  required List<FinalTouchSentenceDetail> details,
  required bool showBrackets,
}) {
  if (details.isNotEmpty) {
    return details
        .map((detail) => showBrackets && detail.bracketed.trim().isNotEmpty
            ? detail.bracketed.trim()
            : detail.original.trim())
        .where((sentence) => sentence.isNotEmpty)
        .join('\n\n');
  }

  final selected =
      showBrackets && bracketed.trim().isNotEmpty ? bracketed : plain;
  return selected.trim();
}

String _previewText(String text, {required int maxCharacters}) {
  final trimmed = text.trim();
  if (trimmed.length <= maxCharacters) return trimmed;
  return '${trimmed.substring(0, maxCharacters).trimRight()}…';
}

List<String> _sentenceTranslationFallbacks(String translation, int count) {
  final trimmed = translation.trim();
  if (trimmed.isEmpty || count <= 0) return const [];

  final numberedLines = trimmed
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) =>
          line.replaceFirst(RegExp(r'^[\u2460-\u2473]\s*'), '').trim())
      .map((line) => line.replaceFirst(RegExp(r'^\d+[\.)]\s*'), '').trim())
      .where((line) => line.isNotEmpty)
      .toList();

  if (numberedLines.length >= count) {
    return numberedLines.take(count).toList();
  }

  final compact = trimmed.replaceAll(RegExp(r'\s+'), ' ');
  final sentenceParts = _splitKoreanSentences(compact);
  if (sentenceParts.length >= count) {
    return sentenceParts.take(count).toList();
  }

  if (numberedLines.isNotEmpty) return numberedLines;
  if (sentenceParts.isNotEmpty) return sentenceParts;
  if (count == 1) return [trimmed];
  return const [];
}

List<String> _splitKoreanSentences(String text) {
  final compact = text.trim();
  if (compact.isEmpty) return const [];
  final matches = RegExp(
    r'.+?(?:[.!?\u3002\uff01\uff1f]|(?:\uB2E4|\uC694|\uC8E0|\uB2C8\uB2E4|\uAE4C\uC694|\uC138\uC694|\uD574\uC694|\uD569\uB2C8\uB2E4|\uB429\uB2C8\uB2E4|\uC788\uC2B5\uB2C8\uB2E4|\uC5C6\uC2B5\uB2C8\uB2E4)(?=\s|$))',
  ).allMatches(compact);
  final parts = matches
      .map((match) => match.group(0)?.trim() ?? '')
      .where((part) => part.isNotEmpty)
      .toList();
  final consumed = parts.join(' ').length;
  if (parts.isNotEmpty && consumed >= compact.length * 0.6) return parts;
  return RegExp(r'[^.!?\u3002\uff01\uff1f]+[.!?\u3002\uff01\uff1f]?')
      .allMatches(compact)
      .map((match) => match.group(0)?.trim() ?? '')
      .where((part) => part.isNotEmpty)
      .toList();
}

String _firstNonEmpty(Iterable<String> values) {
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

bool _looksLikeWholePassageTranslation(String translation, String original) {
  final trimmed = translation.trim();
  if (trimmed.isEmpty) return false;
  final split = _sentenceTranslationFallbacks(trimmed, 999);
  if (split.length < 2) return false;
  final originalWords =
      RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)?").allMatches(original).length;
  return trimmed.length > 140 || split.length > originalWords.clamp(1, 4);
}

class _ReadableSentenceAnalysisCard extends StatelessWidget {
  const _ReadableSentenceAnalysisCard({
    required this.detail,
    required this.fallbackTranslation,
    required this.highlightType,
  });

  final FinalTouchSentenceDetail detail;
  final String fallbackTranslation;
  final String highlightType;

  @override
  Widget build(BuildContext context) {
    final bracketed =
        detail.bracketed.trim().isEmpty ? detail.original : detail.bracketed;
    final directTranslation = _firstNonEmpty([
      detail.translationBracketed,
      detail.translation,
    ]);
    final translationText =
        _looksLikeWholePassageTranslation(directTranslation, detail.original)
            ? fallbackTranslation
            : _firstNonEmpty([directTranslation, fallbackTranslation]);
    final roleStyle = _RoleHighlightStyle.fromType(highlightType);
    final roleLabel = detail.sentenceRole.trim().isEmpty
        ? '\uBB38\uC7A5 \uC5ED\uD560'
        : detail.sentenceRole.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SentenceNumberBadge(number: detail.sentenceNo),
              const SizedBox(width: 9),
              Expanded(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _RoleChip(label: roleLabel),
                    if (roleStyle.label != null)
                      _RoleHighlightChip(
                        label: roleStyle.label!,
                        color: roleStyle.accent,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AnalysisInfoBox(
            label: '\uC601\uC5B4 \uC6D0\uBB38',
            icon: Icons.subject_rounded,
            accentColor: const Color(0xFF1E2E4F),
            backgroundColor: const Color(0xFFFBFCFF),
            dense: true,
            child: FinalTouchStructuredText(
              original: detail.original,
              bracketed: bracketed,
              spans: detail.spans,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.15,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _AnalysisInfoBox(
            label: '\uD574\uC11D',
            icon: Icons.translate_rounded,
            accentColor: const Color(0xFF64748B),
            backgroundColor: const Color(0xFFF8FAFC),
            dense: true,
            child: BracketColoredText(
              text: translationText.trim().isEmpty
                  ? '\uD574\uC11D \uC900\uBE44 \uC911'
                  : translationText,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12.5,
                height: 1.6,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.1,
              ),
            ),
          ),
          if (detail.grammarPoints.isNotEmpty) ...[
            const SizedBox(height: 7),
            _GrammarPointsSection(points: detail.grammarPoints),
          ],
          if (detail.questionPoint.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            _AnalysisInfoBox(
              label: '\uBB38\uC81C\uD654 \uD3EC\uC778\uD2B8',
              icon: Icons.lightbulb_outline_rounded,
              accentColor: const Color(0xFF1E2E4F),
              backgroundColor: const Color(0xFFF8FAFC),
              dense: true,
              child: Text(
                detail.questionPoint,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SentenceNumberBadge extends StatelessWidget {
  const _SentenceNumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2E4F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AnalysisInfoBox extends StatelessWidget {
  const _AnalysisInfoBox({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.child,
    this.dense = false,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final Widget child;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 13, color: const Color(0xFFA0A0A0)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: dense ? 5 : 8),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideAccentBlock extends StatelessWidget {
  const _SideAccentBlock({
    required this.accentColor,
    required this.backgroundColor,
    required this.child,
  });

  final Color accentColor;
  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _SentenceAnalysisCard extends StatelessWidget {
  const _SentenceAnalysisCard({
    required this.detail,
    required this.highlightType,
  });

  final FinalTouchSentenceDetail detail;
  final String highlightType;

  @override
  Widget build(BuildContext context) {
    final bracketed =
        detail.bracketed.trim().isEmpty ? detail.original : detail.bracketed;
    final translationBracketed = detail.translationBracketed.trim().isEmpty
        ? detail.translation
        : detail.translationBracketed;
    final roleStyle = _RoleHighlightStyle.fromType(highlightType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: roleStyle.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: roleStyle.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${detail.sentenceNo}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _RoleChip(
                label: detail.sentenceRole.trim().isEmpty
                    ? '문장 역할'
                    : detail.sentenceRole,
              ),
              if (roleStyle.label != null)
                _RoleHighlightChip(
                  label: roleStyle.label!,
                  color: roleStyle.accent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          const _SmallLabel('\uBB38\uBC95 \uD3EC\uC778\uD2B8'),
          const SizedBox(height: 5),
          FinalTouchStructuredText(
            original: detail.original,
            bracketed: bracketed,
            spans: detail.spans,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 16,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 14),
          const _SmallLabel('해석'),
          const SizedBox(height: 5),
          // TODO: Refine Korean segment alignment with backend span metadata.
          BracketColoredText(
            text: translationBracketed.trim().isEmpty
                ? '이 문장의 해석은 준비 중입니다.'
                : translationBracketed,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (detail.grammarPoints.isNotEmpty) ...[
            const SizedBox(height: 12),
            _GrammarPointsSection(points: detail.grammarPoints),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SmallLabel('문제화 포인트'),
                const SizedBox(height: 5),
                Text(
                  detail.questionPoint.trim().isEmpty
                      ? '문제화 포인트를 정리하고 있습니다.'
                      : detail.questionPoint,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarPointsSection extends StatelessWidget {
  const _GrammarPointsSection({required this.points});

  final List<FinalTouchGrammarPoint> points;

  @override
  Widget build(BuildContext context) {
    return _SideAccentBlock(
      accentColor: const Color(0xFFE08A3B),
      backgroundColor: const Color(0xFFFAFAFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SmallLabel('문법 포인트'),
          const SizedBox(height: 6),
          for (final point in points) ...[
            _GrammarPointItem(point: point),
            if (point != points.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _GrammarPointItem extends StatelessWidget {
  const _GrammarPointItem({required this.point});

  final FinalTouchGrammarPoint point;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Text(
                point.label,
                style: const TextStyle(
                  color: Color(0xFF9A3412),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            Text(
              point.target,
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          point.explanation,
          style: const TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 12.5,
            height: 1.45,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _RoleHighlightChip extends StatelessWidget {
  const _RoleHighlightChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _RoleHighlightStyle {
  const _RoleHighlightStyle({
    required this.background,
    required this.border,
    required this.accent,
    this.label,
  });

  final Color background;
  final Color border;
  final Color accent;
  final String? label;

  factory _RoleHighlightStyle.fromType(String type) {
    switch (type) {
      case 'topic':
        return const _RoleHighlightStyle(
          background: Color(0xFFF0F7FF),
          border: Color(0xFFBFDBFE),
          accent: Color(0xFF2563EB),
          label: '주제문 후보',
        );
      case 'gist':
        return const _RoleHighlightStyle(
          background: Color(0xFFF0F7FF),
          border: Color(0xFFBFDBFE),
          accent: Color(0xFF2563EB),
          label: '요지문 후보',
        );
      case 'conclusion':
        return const _RoleHighlightStyle(
          background: Color(0xFFF0F7FF),
          border: Color(0xFFBFDBFE),
          accent: Color(0xFF2563EB),
          label: '결론 및 정리',
        );
      case 'blank_candidate':
      case 'blank_hint':
        return const _RoleHighlightStyle(
          background: Color(0xFFF0F7FF),
          border: Color(0xFFBFDBFE),
          accent: Color(0xFF2563EB),
          label: '빈칸 후보',
        );
      default:
        return const _RoleHighlightStyle(
          background: Colors.white,
          border: Color(0xFFDCE4EE),
          accent: Color(0xFF64748B),
        );
    }
  }
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
