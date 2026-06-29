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

class FinalTouchFullBracketedPassage extends StatelessWidget {
  const FinalTouchFullBracketedPassage({
    super.key,
    required this.body,
  });

  final String body;

  @override
  Widget build(BuildContext context) {
    final formatted = body.trim().replaceAllMapped(
          RegExp(r'([.!?])\s+'),
          (match) => '${match.group(1)}\n\n',
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE4EE)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
        childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
        iconColor: const Color(0xFF2563EB),
        collapsedIconColor: const Color(0xFF64748B),
        shape: const Border(),
        collapsedShape: const Border(),
        title: const Text(
          '전체 괄호 구조 보기',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text(
          '문장별 분석을 한 번에 이어서 확인합니다.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: BracketLegend(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: BracketColoredText(
              text: formatted.isEmpty ? '-' : formatted,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 16,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
