import 'package:flutter/material.dart';
import '../models/analyzer_models.dart';

class McqQuickPage extends StatefulWidget {
  const McqQuickPage({super.key, required this.mcq, required this.word});

  final McqItem mcq;
  final String word;

  @override
  State<McqQuickPage> createState() => _McqQuickPageState();
}

class _McqQuickPageState extends State<McqQuickPage> {
  int? _selected;
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final mcq = widget.mcq;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('객관식(구조화) 미리보기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Pill(text: '단어: ${widget.word}'),
            const SizedBox(height: 12),
            Text(
              mcq.stem,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: mcq.choices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final isCorrect = i == mcq.answerIndex;
                  final isSelected = _selected == i;
                  final showState = _checked && (isSelected || isCorrect);

                  Color? bg;
                  if (showState && isCorrect) {
                    bg = cs.tertiaryContainer;
                  } else if (showState && isSelected && !isCorrect) {
                    bg = cs.errorContainer;
                  }

                  return Material(
                    color: bg ?? cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap:
                          _checked ? null : () => setState(() => _selected = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: i,
                              groupValue: _selected,
                              onChanged: _checked
                                  ? null
                                  : (v) => setState(() => _selected = v),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                mcq.choices[i],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (_checked) ...[
              Text(
                '정답: ${mcq.answerIndex + 1}. ${mcq.choices[mcq.answerIndex]}',
                style: TextStyle(
                  color: cs.tertiary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mcq.explanation,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _selected == null || _checked
                        ? null
                        : () => setState(() => _checked = true),
                    child: const Text('정답 확인'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
    );
  }
}
