import 'dart:math';

import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';
import '../utils/vocabulary_learning_utils.dart';

const _studentVocabPurple = Color(0xFF6D5CE7);
const _studentVocabSurface = Color(0xFFF7F6FC);

class StudentVocabularyListScreen extends StatefulWidget {
  const StudentVocabularyListScreen({super.key});

  @override
  State<StudentVocabularyListScreen> createState() =>
      _StudentVocabularyListScreenState();
}

class _StudentVocabularyListScreenState
    extends State<StudentVocabularyListScreen> {
  final _service = const VocabularyService();
  late Future<List<VocabularySet>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchStudentSets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _studentVocabSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          '단어장 학습',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<List<VocabularySet>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 52,
                      color: _studentVocabPurple,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '배포된 단어장이 없습니다.',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '선생님이 배포한 단어장이 여기에 표시됩니다.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D5CE7), Color(0xFF8B7CF6)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.translate_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '오늘의 단어 학습',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '선생님이 배포한 단어장 ${items.length}개가 준비되어 있어요.',
                            style: const TextStyle(
                              color: Color(0xFFEDE9FE),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                '내 단어장',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < items.length; index++) ...[
                _StudentVocabularySetCard(
                  vocabularySet: items[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StudentVocabularyDetailScreen(setId: items[index].id),
                    ),
                  ),
                ),
                if (index < items.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StudentVocabularySetCard extends StatelessWidget {
  const _StudentVocabularySetCard({
    required this.vocabularySet,
    required this.onTap,
  });

  final VocabularySet vocabularySet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE3E0F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _studentVocabPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: _studentVocabPurple,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vocabularySet.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if ((vocabularySet.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            vocabularySet.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF526077),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  if ((vocabularySet.sourceLabel ?? '').isNotEmpty)
                    _StudentInfoPill(
                      icon: Icons.library_books_outlined,
                      text: vocabularySet.sourceLabel!,
                    ),
                  if ((vocabularySet.unitLabel ?? '').isNotEmpty)
                    _StudentInfoPill(
                      icon: Icons.bookmark_outline_rounded,
                      text: vocabularySet.unitLabel!,
                    ),
                  if ((vocabularySet.gradeLabel ?? '').isNotEmpty)
                    _StudentInfoPill(
                      icon: Icons.school_outlined,
                      text: vocabularySet.gradeLabel!,
                    ),
                  _StudentInfoPill(
                    icon: Icons.format_list_numbered_rounded,
                    text: '${vocabularySet.itemCount}개 단어',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: _studentVocabPurple,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('학습하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentInfoPill extends StatelessWidget {
  const _StudentInfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _studentVocabPurple),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentVocabularyDetailScreen extends StatelessWidget {
  const StudentVocabularyDetailScreen({super.key, required this.setId});

  final int setId;

  Future<List<VocabularyItem>?> _selectLearningItems(
    BuildContext context,
    List<VocabularyItem> items,
  ) async {
    if (items.length <= 30 && !hasVocabularyGroups(items)) return items;
    return showModalBottomSheet<List<VocabularyItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VocabularyRangeSheet(items: items),
    );
  }

  Future<void> _startCardStudy(
    BuildContext context,
    VocabularySet vocabularySet,
  ) async {
    final items = await _selectLearningItems(context, vocabularySet.items);
    if (items == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentVocabularyCardStudyScreen(
          vocabularySet: vocabularySet,
          items: items,
        ),
      ),
    );
  }

  Future<void> _startMeaningQuiz(
    BuildContext context,
    VocabularySet vocabularySet,
  ) async {
    final items = await _selectLearningItems(context, vocabularySet.items);
    if (items == null || !context.mounted) return;
    final selection = _describeSelection(vocabularySet.items, items);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentVocabularyMeaningQuizScreen(
          vocabularySet: vocabularySet,
          items: items,
          rangeLabel: selection.$1,
          rangeType: selection.$2,
        ),
      ),
    );
  }

  (String, String) _describeSelection(
    List<VocabularyItem> all,
    List<VocabularyItem> selected,
  ) {
    if (selected.length == all.length) return ('전체', 'all');
    final labels = selected
        .map((item) => (item.groupLabel ?? '').trim())
        .where((label) => label.isNotEmpty)
        .toSet();
    if (labels.length == 1 &&
        selected
            .every((item) => (item.groupLabel ?? '').trim() == labels.first)) {
      return (labels.first, 'group');
    }
    final start = all.indexOf(selected.first);
    return (
      start >= 0
          ? '${start + 1}~${start + selected.length}'
          : '${selected.length}단어',
      'chunk',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _studentVocabSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          '단어장',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<VocabularySet>(
        future: const VocabularyService().fetchStudentSet(setId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final vocabularySet = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6D5CE7), Color(0xFF8B7CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x336D5CE7),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.translate_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      vocabularySet.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final text in [
                          vocabularySet.sourceLabel,
                          vocabularySet.unitLabel,
                          '${vocabularySet.items.length}개 단어',
                        ].whereType<String>())
                          _SummaryPill(text: text),
                      ],
                    ),
                    if ((vocabularySet.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        vocabularySet.description!,
                        style: const TextStyle(
                          color: Color(0xFFEDE9FE),
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<VocabularyAttempt>>(
                future: const VocabularyService()
                    .fetchStudentAttempts(vocabularySet.id),
                builder: (context, attemptSnapshot) {
                  final attempts = attemptSnapshot.data ?? const [];
                  final latest = attempts.isEmpty ? null : attempts.first;
                  return _RecentVocabularyResultCard(
                    latest: latest,
                    loading: attemptSnapshot.connectionState ==
                        ConnectionState.waiting,
                    onViewAll: attempts.isEmpty
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentVocabularyAttemptsScreen(
                                  vocabularySet: vocabularySet,
                                ),
                              ),
                            ),
                    onReview: latest == null || latest.wrongCount == 0
                        ? null
                        : () async {
                            final detail = await const VocabularyService()
                                .fetchStudentAttempt(latest.id);
                            if (!context.mounted) return;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentVocabularyResultScreen(
                                  attempt: detail,
                                  vocabularySet: vocabularySet,
                                ),
                              ),
                            );
                          },
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                '학습 모드',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _ModeCard(
                icon: Icons.style_rounded,
                title: '카드 학습',
                subtitle: '단어를 한 장씩 넘기며 뜻을 확인해요.',
                color: const Color(0xFF2563EB),
                onTap: vocabularySet.items.isEmpty
                    ? null
                    : () => _startCardStudy(context, vocabularySet),
              ),
              const SizedBox(height: 12),
              _ModeCard(
                icon: Icons.quiz_rounded,
                title: '뜻 맞히기',
                subtitle: '보기에서 알맞은 우리말 뜻을 선택해요.',
                color: _studentVocabPurple,
                onTap: vocabularySet.items.length < 2
                    ? null
                    : () => _startMeaningQuiz(context, vocabularySet),
              ),
              if (vocabularySet.items.length < 2) ...[
                const SizedBox(height: 8),
                const Text('뜻 맞히기는 단어가 2개 이상 필요합니다.'),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _VocabularyRangeSheet extends StatefulWidget {
  const _VocabularyRangeSheet({required this.items});

  final List<VocabularyItem> items;

  @override
  State<_VocabularyRangeSheet> createState() => _VocabularyRangeSheetState();
}

class _VocabularyRangeSheetState extends State<_VocabularyRangeSheet> {
  var _showGroups = false;
  var _chunkSize = 20;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final hasGroups = hasVocabularyGroups(items);
    final ranges = buildVocabularyLearningRanges(
      items.length,
      chunkSize: _chunkSize,
    );
    final groups = buildVocabularyLearningGroups(items);
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 680),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8D5E8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '학습할 범위를 선택하세요',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              '많은 단어는 나누어 학습할 수 있어요.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            if (hasGroups)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.numbers_rounded),
                    label: Text('단어 수 기준'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.menu_book_rounded),
                    label: Text('강/챕터 기준'),
                  ),
                ],
                selected: {_showGroups},
                onSelectionChanged: (value) =>
                    setState(() => _showGroups = value.first),
              ),
            if (hasGroups) const SizedBox(height: 12),
            if (!_showGroups && items.length > 30) ...[
              const Text(
                '세트 단위',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final size in const [20, 30, 40, 50])
                    ChoiceChip(
                      label: Text('$size개씩'),
                      selected: _chunkSize == size,
                      onSelected: (_) => setState(() => _chunkSize = size),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: ListView.separated(
                itemCount: _showGroups ? groups.length + 1 : ranges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  if (_showGroups) {
                    if (index == 0) {
                      return _LearningOptionCard(
                        icon: Icons.auto_awesome_rounded,
                        title: '전체',
                        subtitle: '${items.length}단어',
                        emphasized: true,
                        onTap: () => Navigator.pop(context, items),
                      );
                    }
                    final group = groups[index - 1];
                    return _LearningOptionCard(
                      icon: group.label == '미분류'
                          ? Icons.help_outline_rounded
                          : Icons.bookmark_outline_rounded,
                      title: group.label,
                      subtitle: '${group.count}단어',
                      onTap: () => Navigator.pop(context, group.items),
                    );
                  }
                  final range = ranges[index];
                  return _LearningOptionCard(
                    icon: range.isAll
                        ? Icons.auto_awesome_rounded
                        : Icons.layers_rounded,
                    title: range.label,
                    subtitle: '${range.rangeLabel} · ${range.count}개',
                    emphasized: range.isAll,
                    onTap: () => Navigator.pop(context, range.select(items)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningOptionCard extends StatelessWidget {
  const _LearningOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasized ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: emphasized ? _studentVocabPurple : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: _studentVocabPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE7E5F4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle, style: const TextStyle(height: 1.4)),
        ),
        trailing: Icon(Icons.arrow_forward_rounded, color: color),
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class StudentVocabularyCardStudyScreen extends StatefulWidget {
  const StudentVocabularyCardStudyScreen({
    super.key,
    required this.vocabularySet,
    required this.items,
  });

  final VocabularySet vocabularySet;
  final List<VocabularyItem> items;

  @override
  State<StudentVocabularyCardStudyScreen> createState() =>
      _StudentVocabularyCardStudyScreenState();
}

class _StudentVocabularyCardStudyScreenState
    extends State<StudentVocabularyCardStudyScreen> {
  int _index = 0;
  bool _showMeaning = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final item = items[_index];
    return Scaffold(
      appBar: AppBar(title: Text(widget.vocabularySet.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + 1) / items.length),
            const SizedBox(height: 8),
            Text('${_index + 1} / ${items.length}'),
            const SizedBox(height: 30),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => setState(() => _showMeaning = !_showMeaning),
                child: Card(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.word,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            _showMeaning
                                ? displayVocabularyMeaning(item.meaningKo)
                                : '눌러서 뜻 보기',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _showMeaning ? 24 : 16,
                              color: _showMeaning
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _index == 0
                        ? null
                        : () => setState(() {
                              _index--;
                              _showMeaning = false;
                            }),
                    child: const Text('이전'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _index == items.length - 1
                        ? () => Navigator.pop(context)
                        : () => setState(() {
                              _index++;
                              _showMeaning = false;
                            }),
                    child: Text(_index == items.length - 1 ? '학습 완료' : '다음'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StudentVocabularyMeaningQuizScreen extends StatefulWidget {
  const StudentVocabularyMeaningQuizScreen({
    super.key,
    required this.vocabularySet,
    required this.items,
    this.rangeLabel,
    this.rangeType,
  });

  final VocabularySet vocabularySet;
  final List<VocabularyItem> items;
  final String? rangeLabel;
  final String? rangeType;

  @override
  State<StudentVocabularyMeaningQuizScreen> createState() =>
      _StudentVocabularyMeaningQuizScreenState();
}

class _StudentVocabularyMeaningQuizScreenState
    extends State<StudentVocabularyMeaningQuizScreen> {
  late final List<VocabularyItem> _questions;
  late final Map<int, List<String>> _choices;
  final Map<int, String> _answers = {};
  int _index = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _questions = [...widget.items]..shuffle(random);
    _choices = {
      for (final item in _questions)
        item.id: _buildChoices(item, widget.vocabularySet.items, random),
    };
  }

  List<String> _buildChoices(
    VocabularyItem item,
    List<VocabularyItem> all,
    Random random,
  ) {
    final distractors = all
        .where((other) => other.id != item.id)
        .map((other) => other.meaningKo)
        .where((meaning) => meaning != item.meaningKo)
        .toSet()
        .toList()
      ..shuffle(random);
    return ([item.meaningKo, ...distractors.take(3)]..shuffle(random));
  }

  Future<void> _finish() async {
    setState(() => _submitting = true);
    try {
      final attempt = await const VocabularyService().submitMeaningQuiz(
        widget.vocabularySet.id,
        _answers,
        rangeLabel: widget.rangeLabel,
        rangeType: widget.rangeType,
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentVocabularyResultScreen(
            attempt: attempt,
            vocabularySet: widget.vocabularySet,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _questions[_index];
    final selected = _answers[item.id];
    final answered = selected != null;
    return Scaffold(
      backgroundColor: _studentVocabSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          '뜻 맞히기',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: (_index + 1) / _questions.length,
                                  minHeight: 10,
                                  color: _studentVocabPurple,
                                  backgroundColor: const Color(0xFFE7E5F4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_index + 1} / ${_questions.length}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: const Color(0xFFE7E5F4)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x120F172A),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '알맞은 뜻을 선택하세요',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                quizDisplayWord(item.word),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (final choice in _choices[item.id]!)
                          _QuizChoiceTile(
                            text: displayVocabularyMeaning(choice),
                            selected: choice == selected,
                            correct: answered && choice == item.meaningKo,
                            wrong: answered &&
                                choice == selected &&
                                choice != item.meaningKo,
                            onTap: answered
                                ? null
                                : () =>
                                    setState(() => _answers[item.id] = choice),
                          ),
                        if (answered)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected == item.meaningKo
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              selected == item.meaningKo
                                  ? '정답입니다!'
                                  : '오답입니다. 정답: '
                                      '${displayVocabularyMeaning(item.meaningKo)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected == item.meaningKo
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB91C1C),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        const Spacer(),
                        FilledButton(
                          onPressed: !answered || _submitting
                              ? null
                              : _index == _questions.length - 1
                                  ? _finish
                                  : () => setState(() => _index++),
                          style: FilledButton.styleFrom(
                            backgroundColor: _studentVocabPurple,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            _submitting
                                ? '결과 저장 중...'
                                : _index == _questions.length - 1
                                    ? '제출하고 결과 보기'
                                    : '다음 문제',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizChoiceTile extends StatelessWidget {
  const _QuizChoiceTile({
    required this.text,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = correct
        ? const Color(0xFFDCFCE7)
        : wrong
            ? const Color(0xFFFEE2E2)
            : selected
                ? const Color(0xFFEDE9FE)
                : Colors.white;
    final border = correct
        ? const Color(0xFF22C55E)
        : wrong
            ? const Color(0xFFEF4444)
            : selected
                ? _studentVocabPurple
                : const Color(0xFFD8D5E8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: selected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (correct)
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A))
                else if (wrong)
                  const Icon(Icons.cancel, color: Color(0xFFDC2626))
                else
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? _studentVocabPurple
                        : const Color(0xFF94A3B8),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentVocabularyResultCard extends StatelessWidget {
  const _RecentVocabularyResultCard({
    required this.latest,
    required this.loading,
    required this.onViewAll,
    required this.onReview,
  });

  final VocabularyAttempt? latest;
  final bool loading;
  final VoidCallback? onViewAll;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE7E5F4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : latest == null
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '최근 학습 결과',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('아직 학습 기록이 없습니다.'),
                      Text(
                        '뜻 맞히기를 풀면 결과가 여기에 표시됩니다.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '최근 학습 결과',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onViewAll,
                            child: const Text('결과 보기'),
                          ),
                        ],
                      ),
                      Text(
                        '${latest!.score.toStringAsFixed(1)}점',
                        style: const TextStyle(
                          color: _studentVocabPurple,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${latest!.correctCount} / ${latest!.totalCount} 정답'
                        ' · 오답 ${latest!.wrongCount}개',
                      ),
                      if ((latest!.rangeLabel ?? '').isNotEmpty)
                        Text(
                          '학습 범위: ${latest!.rangeLabel}',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      if ((latest!.createdAt ?? '').isNotEmpty)
                        Text(
                          '최근 학습: ${_shortDate(latest!.createdAt)}',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      if (latest!.wrongCount == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '오답이 없습니다. 훌륭해요!',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            onPressed: onReview,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('오답 복습'),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class StudentVocabularyAttemptsScreen extends StatelessWidget {
  const StudentVocabularyAttemptsScreen({
    super.key,
    required this.vocabularySet,
  });

  final VocabularySet vocabularySet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('단어장 학습 결과')),
      body: FutureBuilder<List<VocabularyAttempt>>(
        future:
            const VocabularyService().fetchStudentAttempts(vocabularySet.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final attempts = snapshot.data ?? const [];
          if (attempts.isEmpty) {
            return const Center(child: Text('아직 학습 기록이 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: attempts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEDE9FE),
                    child: Text('${attempt.score.round()}'),
                  ),
                  title: Text(
                    '${attempt.correctCount}/${attempt.totalCount} 정답'
                    ' · 오답 ${attempt.wrongCount}개',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${attempt.rangeLabel ?? '전체'}'
                    ' · ${_shortDate(attempt.createdAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final detail = await const VocabularyService()
                        .fetchStudentAttempt(attempt.id);
                    if (!context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentVocabularyResultScreen(
                          attempt: detail,
                          vocabularySet: vocabularySet,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StudentVocabularyResultScreen extends StatelessWidget {
  const StudentVocabularyResultScreen({
    super.key,
    required this.attempt,
    required this.vocabularySet,
  });

  final VocabularyAttempt attempt;
  final VocabularySet vocabularySet;

  List<VocabularyItem> get _attemptItems {
    final ids = attempt.results.map((result) => result.itemId).toSet();
    return vocabularySet.items.where((item) => ids.contains(item.id)).toList();
  }

  List<VocabularyItem> get _wrongItems {
    return wrongVocabularyItems(vocabularySet.items, attempt.results);
  }

  void _openQuiz(
    BuildContext context,
    List<VocabularyItem> items,
    String rangeLabel,
  ) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StudentVocabularyMeaningQuizScreen(
          vocabularySet: vocabularySet,
          items: items,
          rangeLabel: rangeLabel,
          rangeType: 'review',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wrongItems = _wrongItems;
    final attemptItems = _attemptItems;
    final perfect = attempt.wrongCount == 0;
    return Scaffold(
      backgroundColor: _studentVocabSurface,
      appBar: AppBar(
        title: const Text(
          '단어 테스트 결과',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 150),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: perfect
                    ? const [Color(0xFFECFDF5), Color(0xFFEFF6FF)]
                    : const [Color(0xFFF5F3FF), Color(0xFFFFF7ED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color:
                    perfect ? const Color(0xFFA7F3D0) : const Color(0xFFDDD6FE),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  Icon(
                    perfect
                        ? Icons.emoji_events_rounded
                        : Icons.insights_rounded,
                    size: 42,
                    color:
                        perfect ? const Color(0xFF059669) : _studentVocabPurple,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    perfect ? '완벽해요!' : '학습을 완료했어요',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${attempt.score.toStringAsFixed(1)}점',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: perfect
                          ? const Color(0xFF047857)
                          : _studentVocabPurple,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ResultStatPill(
                        icon: Icons.check_circle_outline_rounded,
                        label: '정답',
                        value: '${attempt.correctCount}개',
                        color: const Color(0xFF059669),
                      ),
                      _ResultStatPill(
                        icon: Icons.cancel_outlined,
                        label: '오답',
                        value: '${attempt.wrongCount}개',
                        color: const Color(0xFFEA580C),
                      ),
                      _ResultStatPill(
                        icon: Icons.format_list_numbered_rounded,
                        label: '총 단어',
                        value: '${attempt.totalCount}개',
                        color: const Color(0xFF2563EB),
                      ),
                      _ResultStatPill(
                        icon: Icons.bookmark_outline_rounded,
                        label: '학습 범위',
                        value: attempt.rangeLabel ?? '전체',
                        color: _studentVocabPurple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '문항별 결과',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final result in attempt.results)
            _VocabularyResultAnswerCard(result: result),
          if (wrongItems.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF059669)),
                  SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      '오답이 없습니다. 훌륭해요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE7E5F4))),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final actions = [
                OutlinedButton.icon(
                  onPressed: attemptItems.isEmpty
                      ? null
                      : () => _openQuiz(context, attemptItems, '다시 풀기'),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('다시 풀기'),
                ),
                FilledButton.tonalIcon(
                  onPressed: wrongItems.isEmpty
                      ? null
                      : () => _openQuiz(context, wrongItems, '오답 복습'),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('오답만 다시 풀기'),
                ),
                FilledButton.tonalIcon(
                  onPressed: wrongItems.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentVocabularyCardStudyScreen(
                                vocabularySet: vocabularySet,
                                items: wrongItems,
                              ),
                            ),
                          ),
                  icon: const Icon(Icons.style_rounded),
                  label: const Text('오답만 카드 학습'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _studentVocabPurple,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('단어장으로 돌아가기'),
                ),
              ];
              return Wrap(
                alignment:
                    wide ? WrapAlignment.end : WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in actions)
                    SizedBox(
                      width: wide ? null : (constraints.maxWidth - 8) / 2,
                      child: action,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResultStatPill extends StatelessWidget {
  const _ResultStatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            '$label $value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VocabularyResultAnswerCard extends StatelessWidget {
  const _VocabularyResultAnswerCard({required this.result});

  final VocabularyAttemptResult result;

  @override
  Widget build(BuildContext context) {
    final color =
        result.isCorrect ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final background =
        result.isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              result.isCorrect ? Icons.check_rounded : Icons.close_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.word,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        result.isCorrect ? '정답' : '오답',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _ResultAnswerLine(
                  label: '내 답',
                  value: displayVocabularyMeaning(result.studentAnswer),
                  color: result.isCorrect ? const Color(0xFF166534) : color,
                ),
                const SizedBox(height: 5),
                _ResultAnswerLine(
                  label: '정답',
                  value: displayVocabularyMeaning(result.correctAnswer),
                  color: const Color(0xFF166534),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultAnswerLine extends StatelessWidget {
  const _ResultAnswerLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

String _shortDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.year}.${parsed.month.toString().padLeft(2, '0')}.'
      '${parsed.day.toString().padLeft(2, '0')}';
}
