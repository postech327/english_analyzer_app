import 'package:flutter/material.dart';

class UnifiedLearningResultCard extends StatelessWidget {
  const UnifiedLearningResultCard({
    super.key,
    required this.title,
    required this.score,
    required this.correctCount,
    required this.totalCount,
    required this.leadingIcon,
    required this.accentColor,
    this.subtitle,
    this.dateLabel,
    this.scoreUnit = '점',
    this.badges = const [],
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? dateLabel;
  final num score;
  final String scoreUnit;
  final int correctCount;
  final int totalCount;
  final List<String> badges;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onTap;
  final IconData leadingIcon;
  final Color accentColor;

  double get _progress =>
      totalCount <= 0 ? 0 : (correctCount / totalCount).clamp(0.0, 1.0);

  String get _scoreText {
    final value = score.toDouble();
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 330;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compact) ...[
                    _TitleBlock(
                      title: title,
                      subtitle: subtitle,
                      dateLabel: dateLabel,
                      icon: leadingIcon,
                      color: accentColor,
                    ),
                    const SizedBox(height: 14),
                    _ScoreBlock(
                      score: _scoreText,
                      unit: scoreUnit,
                      correct: correctCount,
                      total: totalCount,
                      color: accentColor,
                      horizontal: true,
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TitleBlock(
                            title: title,
                            subtitle: subtitle,
                            dateLabel: dateLabel,
                            icon: leadingIcon,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ScoreBlock(
                          score: _scoreText,
                          unit: scoreUnit,
                          correct: correctCount,
                          total: totalCount,
                          color: accentColor,
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final badge in badges.take(4))
                          _ResultBadge(label: badge, color: accentColor),
                      ],
                    ),
                  ],
                  if (onPrimaryAction != null || onSecondaryAction != null) ...[
                    const SizedBox(height: 16),
                    _ResultActions(
                      compact: compact,
                      accentColor: accentColor,
                      primaryLabel: primaryActionLabel ?? '결과 보기',
                      secondaryLabel: secondaryActionLabel ?? '다시 풀기',
                      onPrimary: onPrimaryAction,
                      onSecondary: onSecondaryAction,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.compact,
    required this.accentColor,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final bool compact;
  final Color accentColor;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (onPrimary != null)
        if (compact)
          FilledButton(
            onPressed: onPrimary,
            style: _primaryStyle(compact: true),
            child: Text(primaryLabel),
          )
        else
          FilledButton.icon(
            onPressed: onPrimary,
            icon: const Icon(Icons.rate_review_rounded, size: 18),
            label: Text(primaryLabel),
            style: _primaryStyle(compact: false),
          ),
      if (onSecondary != null)
        if (compact)
          OutlinedButton(
            onPressed: onSecondary,
            style: _secondaryStyle(compact: true),
            child: Text(secondaryLabel),
          )
        else
          OutlinedButton.icon(
            onPressed: onSecondary,
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: Text(secondaryLabel),
            style: _secondaryStyle(compact: false),
          ),
    ];
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < buttons.length; index++) ...[
            buttons[index],
            if (index < buttons.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }

  ButtonStyle _primaryStyle({required bool compact}) => FilledButton.styleFrom(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      );

  ButtonStyle _secondaryStyle({required bool compact}) =>
      OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        side: BorderSide(color: accentColor),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      );
}

class UnifiedLearningResultsEmptyState extends StatelessWidget {
  const UnifiedLearningResultsEmptyState({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.onStart,
    this.title = '학습 기록 없음',
    this.message = '첫 학습을 시작해 보세요',
    this.actionLabel = '학습 시작',
  });

  final IconData icon;
  final Color accentColor;
  final VoidCallback onStart;
  final String title;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: accentColor),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(backgroundColor: accentColor),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.icon,
    required this.color,
  });

  final String title;
  final String? subtitle;
  final String? dateLabel;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 17,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if ((subtitle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if ((dateLabel ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  dateLabel!,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({
    required this.score,
    required this.unit,
    required this.correct,
    required this.total,
    required this.color,
    this.horizontal = false,
  });

  final String score;
  final String unit;
  final int correct;
  final int total;
  final Color color;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final scoreWidget = Text(
      '$score$unit',
      style: TextStyle(
        color: color,
        fontSize: 26,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    );
    final countWidget = Text(
      '$correct/$total',
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w800,
      ),
    );
    if (horizontal) {
      return Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: scoreWidget,
            ),
          ),
          const SizedBox(width: 12),
          countWidget,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        scoreWidget,
        const SizedBox(height: 6),
        countWidget,
      ],
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
