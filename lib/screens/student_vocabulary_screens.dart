import 'dart:math';

import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';

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
      appBar: AppBar(title: const Text('단어장 학습')),
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
                    Icon(Icons.inbox_outlined, size: 44),
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
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.translate_rounded),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    [
                      item.sourceLabel,
                      item.unitLabel,
                      '${item.itemCount}개 단어',
                    ].whereType<String>().join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StudentVocabularyDetailScreen(setId: item.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StudentVocabularyDetailScreen extends StatelessWidget {
  const StudentVocabularyDetailScreen({super.key, required this.setId});

  final int setId;

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
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentVocabularyCardStudyScreen(
                              vocabularySet: vocabularySet,
                            ),
                          ),
                        ),
              ),
              const SizedBox(height: 12),
              _ModeCard(
                icon: Icons.quiz_rounded,
                title: '뜻 맞히기',
                subtitle: '보기에서 알맞은 우리말 뜻을 선택해요.',
                color: _studentVocabPurple,
                onTap: vocabularySet.items.length < 2
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentVocabularyMeaningQuizScreen(
                              vocabularySet: vocabularySet,
                            ),
                          ),
                        ),
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
  });

  final VocabularySet vocabularySet;

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
    final items = widget.vocabularySet.items;
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
                            _showMeaning ? item.meaningKo : '눌러서 뜻 보기',
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
  });

  final VocabularySet vocabularySet;

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
    _questions = [...widget.vocabularySet.items]..shuffle(random);
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
      final attempt = await const VocabularyService()
          .submitMeaningQuiz(widget.vocabularySet.id, _answers);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentVocabularyResultScreen(attempt: attempt),
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
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                        style: const TextStyle(fontWeight: FontWeight.w900),
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
                          item.word,
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
                      text: choice,
                      selected: choice == selected,
                      correct: answered && choice == item.meaningKo,
                      wrong: answered &&
                          choice == selected &&
                          choice != item.meaningKo,
                      onTap: answered
                          ? null
                          : () => setState(() => _answers[item.id] = choice),
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
                            : '오답입니다. 정답: ${item.meaningKo}',
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

class StudentVocabularyResultScreen extends StatelessWidget {
  const StudentVocabularyResultScreen({super.key, required this.attempt});

  final VocabularyAttempt attempt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('단어 테스트 결과')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${attempt.score.toStringAsFixed(1)}점',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('${attempt.correctCount} / ${attempt.totalCount} 정답'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final result in attempt.results)
            Card(
              child: ListTile(
                leading: Icon(
                  result.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: result.isCorrect ? Colors.green : Colors.red,
                ),
                title: Text(
                  result.word,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '내 답: ${result.studentAnswer}\n정답: ${result.correctAnswer}',
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('단어장으로 돌아가기'),
          ),
        ),
      ),
    );
  }
}
