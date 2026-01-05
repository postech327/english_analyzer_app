import 'dart:convert';
import 'package:flutter/material.dart';

class GptExplanationCard extends StatelessWidget {
  final String explanationJson;

  const GptExplanationCard({
    super.key,
    required this.explanationJson,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(explanationJson);
    } catch (_) {
      data = null;
    }

    if (data == null) {
      return const SizedBox();
    }

    return Card(
      color: cs.surfaceContainerHighest.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Row(
              children: [
                Icon(Icons.lightbulb, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'GPT 오답 해설',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 설명
            Text(
              data['explanation'] ?? '',
              style: const TextStyle(height: 1.5),
            ),

            const SizedBox(height: 12),

            // 핵심 문장
            if ((data['key_sentence'] ?? '').toString().isNotEmpty) ...[
              Divider(color: cs.outline.withOpacity(0.3)),
              const SizedBox(height: 8),
              Text(
                '🔑 핵심 문장',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(data['key_sentence']),
            ],

            // 학습 팁
            if ((data['tip'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '📌 학습 팁',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(data['tip']),
            ],
          ],
        ),
      ),
    );
  }
}
