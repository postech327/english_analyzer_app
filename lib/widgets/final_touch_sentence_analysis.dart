import 'package:flutter/material.dart';

import '../models/final_touch.dart';
import 'bracket_colored_text.dart';
import 'final_touch_structured_text.dart';

class FinalTouchSentenceAnalysis extends StatelessWidget {
  const FinalTouchSentenceAnalysis({
    super.key,
    required this.details,
  });

  final List<FinalTouchSentenceDetail> details;

  @override
  Widget build(BuildContext context) {
    if (details.isEmpty) return const SizedBox.shrink();
    final highlightedIndexes = _visibleHighlightIndexes(details);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '문장별 세부 분석',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${details.length}개 문장을 원문, 해석, 역할, 문제화 포인트 순서로 정리했습니다.',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        const FinalTouchStructureLegend(),
        const SizedBox(height: 12),
        for (var index = 0; index < details.length; index++) ...[
          _SentenceAnalysisCard(
            detail: details[index],
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
  });

  final String body;
  final String plainBody;
  final List<FinalTouchSentenceDetail> sentenceDetails;

  @override
  State<FinalTouchFullBracketedPassage> createState() =>
      _FinalTouchFullBracketedPassageState();
}

class _FinalTouchFullBracketedPassageState
    extends State<FinalTouchFullBracketedPassage> {
  bool _showBrackets = true;
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final rows = _passageRows(
      bracketed: widget.body,
      plain: widget.plainBody,
      details: widget.sentenceDetails,
      showBrackets: _showBrackets,
    );
    final visibleRows = _expanded ? rows : rows.take(3).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFF), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC7D2FE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F4F46E5),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                          color: Color(0xFF172033),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '괄호 구조를 보며 지문 전체 흐름을 먼저 확인해요.',
                        style: TextStyle(
                          color: Color(0xFF59657A),
                          fontSize: 13,
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
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: Column(
                children: [
                  for (var index = 0; index < visibleRows.length; index++) ...[
                    _FullPassageSentenceRow(row: visibleRows[index]),
                    if (index != visibleRows.length - 1)
                      const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            if (!_expanded && rows.length > visibleRows.length) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = true),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: Text('나머지 ${rows.length - visibleRows.length}문장 보기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FullPassageSentenceRow extends StatelessWidget {
  const _FullPassageSentenceRow({required this.row});

  final ({int? number, String text}) row;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE4F2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (row.number != null) ...[
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${row.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: BracketColoredText(
              text: row.text.trim().isEmpty ? '-' : row.text.trim(),
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 16,
                height: 1.75,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<({int? number, String text})> _passageRows({
  required String bracketed,
  required String plain,
  required List<FinalTouchSentenceDetail> details,
  required bool showBrackets,
}) {
  if (details.isNotEmpty) {
    return details.map((detail) {
      final selected = showBrackets && detail.bracketed.trim().isNotEmpty
          ? detail.bracketed
          : detail.original;
      return (
        number: detail.sentenceNo > 0 ? detail.sentenceNo : null,
        text: selected,
      );
    }).toList();
  }

  final selected =
      showBrackets && bracketed.trim().isNotEmpty ? bracketed : plain;
  final sentences = selected
      .trim()
      .split(RegExp(r'(?<=[.!?])\s+|\n+'))
      .map((sentence) => sentence.trim())
      .where((sentence) => sentence.isNotEmpty)
      .toList();
  if (sentences.length > 1) {
    return [
      for (var index = 0; index < sentences.length; index++)
        (number: index + 1, text: sentences[index]),
    ];
  }
  return [(number: null, text: selected.trim().isEmpty ? '-' : selected)];
}

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
          const _SmallLabel('영문 분석'),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SmallLabel('문법 포인트'),
          const SizedBox(height: 8),
          for (final point in points) ...[
            _GrammarPointItem(point: point),
            if (point != points.last) const SizedBox(height: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(
                point.label,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              point.target,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          point.explanation,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 13,
            height: 1.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontSize: 12,
          fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
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
        color: Color(0xFF2563EB),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
