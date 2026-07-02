import 'dart:math';

import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';

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
            return const Center(child: Text('공개된 단어장이 없습니다.'));
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
      appBar: AppBar(title: const Text('단어장')),
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
              Text(
                vocabularySet.title,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  vocabularySet.sourceLabel,
                  vocabularySet.unitLabel,
                  '${vocabularySet.items.length}개 단어',
                ].whereType<String>().join(' · '),
              ),
              if ((vocabularySet.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(vocabularySet.description!),
              ],
              const SizedBox(height: 24),
              _ModeCard(
                icon: Icons.style_rounded,
                title: '카드 학습',
                subtitle: '단어를 한 장씩 넘기며 뜻을 확인해요.',
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_rounded),
        enabled: onTap != null,
        onTap: onTap,
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
      appBar: AppBar(title: const Text('뜻 맞히기')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (_index + 1) / _questions.length),
            const SizedBox(height: 8),
            Text('${_index + 1} / ${_questions.length}'),
            const Spacer(),
            Text(
              item.word,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 28),
            for (final choice in _choices[item.id]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: !answered
                        ? null
                        : choice == item.meaningKo
                            ? Colors.green.withValues(alpha: 0.16)
                            : choice == selected
                                ? Colors.red.withValues(alpha: 0.14)
                                : null,
                  ),
                  onPressed: answered
                      ? null
                      : () => setState(() => _answers[item.id] = choice),
                  child: Text(choice),
                ),
              ),
            if (answered)
              Text(
                selected == item.meaningKo ? '정답입니다!' : '정답: ${item.meaningKo}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected == item.meaningKo ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w900,
                ),
              ),
            const Spacer(),
            FilledButton(
              onPressed: !answered || _submitting
                  ? null
                  : _index == _questions.length - 1
                      ? _finish
                      : () => setState(() => _index++),
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
