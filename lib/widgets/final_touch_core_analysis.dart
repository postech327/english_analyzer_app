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
    this.summaryEn = '',
    this.summaryKo = '',
  });

  final String topicEn;
  final String topicKo;
  final String titleEn;
  final String titleKo;
  final String gistEn;
  final String gistKo;
  final String summaryEn;
  final String summaryKo;

  @override
  Widget build(BuildContext context) {
    final sections = [
      (label: '주제', english: topicEn, korean: topicKo),
      (label: '제목', english: titleEn, korean: titleKo),
      (label: '요지', english: gistEn, korean: gistKo),
      if (summaryEn.trim().isNotEmpty || summaryKo.trim().isNotEmpty)
        (label: '요약', english: summaryEn, korean: summaryKo),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '핵심 분석',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '주제, 제목, 요지와 요약을 영어와 한국어로 함께 확인합니다.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < sections.length; index++) ...[
            _CoreSection(
              label: sections[index].label,
              english: sections[index].english,
              korean: sections[index].korean,
            ),
            if (index < sections.length - 1)
              const Divider(height: 22, color: Color(0xFFBFDBFE)),
          ],
        ],
      ),
    );
  }
}

class _CoreSection extends StatelessWidget {
  const _CoreSection({
    required this.label,
    required this.english,
    required this.korean,
  });

  final String label;
  final String english;
  final String korean;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        _LanguageRow(
          language: '영어',
          value: english,
          color: const Color(0xFF172033),
        ),
        const SizedBox(height: 5),
        _LanguageRow(
          language: '한국어',
          value: korean,
          color: const Color(0xFF334155),
        ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.value,
    required this.color,
  });

  final String language;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$language:',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.trim().isEmpty ? '-' : value,
          softWrap: true,
          style: TextStyle(
            color: color,
            fontSize: 14,
            height: 1.55,
            fontWeight: language == '영어' ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
