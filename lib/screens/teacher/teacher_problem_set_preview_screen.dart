import 'dart:convert';

import 'package:flutter/material.dart';

import '../../utils/insertion_display_prompt.dart';
import 'package:english_analyzer_app/services/teacher_problem_set_service.dart';
import 'package:english_analyzer_app/widgets/problem_set_assignment_dialog.dart';

class TeacherProblemSetPreviewScreen extends StatefulWidget {
  final int problemSetId;
  const TeacherProblemSetPreviewScreen({super.key, required this.problemSetId});

  @override
  State<TeacherProblemSetPreviewScreen> createState() =>
      _TeacherProblemSetPreviewScreenState();
}

class _TeacherProblemSetPreviewScreenState
    extends State<TeacherProblemSetPreviewScreen> {
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _blue = Color(0xFF2563EB);
  static const _surface = Color(0xFFF4F7FB);

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherProblemSetService.fetchProblemSet(widget.problemSetId);
  }

  Future<void> _showAssignmentEntry(String title) async {
    final result = await showDialog<ProblemSetAssignmentResult>(
      context: context,
      builder: (_) => ProblemSetAssignmentDialog(
        problemSetId: widget.problemSetId,
        title: title,
      ),
    );
    if (!mounted || result == null) return;
    final message = result.failed.isEmpty
        ? '${result.successCount}명에게 문제세트를 배포했습니다.'
        : '${result.successCount}명 배포 완료 · ${result.failed.length}명 실패/중복';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '새로고침',
          onPressed: () {
            setState(() {
              _future =
                  TeacherProblemSetService.fetchProblemSet(widget.problemSetId);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text('문제세트 미리보기 #${widget.problemSetId}'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorBox(message: '불러오기 실패: ${snap.error}');
          }

          final data = snap.data ?? {};
          final passage = _asMap(data['passage']);
          final questions = _asMapList(data['questions']);

          final passageTitle =
              _firstText([passage['title'], passage['source_title']]);
          final passageContent = _firstText([passage['content']]);
          final title = _firstText([
            data['name'],
            data['title'],
            passageTitle,
            '문제세트 #${widget.problemSetId}',
          ]);
          final folderName = _firstText([data['folder_name'], '미분류']);
          final distribution = _typeDistribution(questions);

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryCard(
                        title: title,
                        folderName: folderName,
                        questionCount: questions.length,
                        distribution: distribution,
                        onAssign: () => _showAssignmentEntry(title),
                      ),
                      const SizedBox(height: 14),
                      _PassageCard(
                        title: passageTitle.isEmpty ? '(제목 없음)' : passageTitle,
                        content: passageContent,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(
                            Icons.fact_check_outlined,
                            color: _blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '문항 미리보기',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const Spacer(),
                          Text(
                            '기본 접힘 · 필요한 문항만 펼쳐 확인',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...questions.map(
                        (q) => _QuestionCard(
                          q: q,
                          sharedPassage: passageContent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.folderName,
    required this.questionCount,
    required this.distribution,
    required this.onAssign,
  });

  final String title;
  final String folderName;
  final int questionCount;
  final Map<String, int> distribution;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final distributionText = distribution.entries.isEmpty
        ? '유형 정보 없음'
        : distribution.entries.map((e) => '${e.key} ${e.value}').join(' / ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _TeacherProblemSetPreviewScreenState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Teacher Preview',
                  style: TextStyle(
                    color: _TeacherProblemSetPreviewScreenState._blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: _TeacherProblemSetPreviewScreenState._ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(icon: Icons.folder_outlined, text: folderName),
                  _InfoPill(
                      icon: Icons.quiz_outlined, text: '$questionCount문항'),
                  _InfoPill(
                    icon: Icons.category_outlined,
                    text: distributionText,
                  ),
                ],
              ),
            ],
          );

          final button = FilledButton.icon(
            onPressed: onAssign,
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('학생에게 배포'),
            style: FilledButton.styleFrom(
              backgroundColor: _TeacherProblemSetPreviewScreenState._blue,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 16),
                button,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 18),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _PassageCard extends StatelessWidget {
  final String title;
  final String content;
  const _PassageCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            const BorderSide(color: _TeacherProblemSetPreviewScreenState._line),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        initiallyExpanded: false,
        leading: const Icon(
          Icons.article_outlined,
          color: _TeacherProblemSetPreviewScreenState._blue,
        ),
        title: const Text(
          '공통 지문',
          style: TextStyle(
            color: _TeacherProblemSetPreviewScreenState._ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _TeacherProblemSetPreviewScreenState._muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          _SectionBlock(
            label: title,
            child: SelectableText(
              content.isEmpty ? '(내용 없음)' : content,
              style: const TextStyle(
                color: _TeacherProblemSetPreviewScreenState._ink,
                height: 1.62,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> q;
  final String sharedPassage;
  const _QuestionCard({required this.q, required this.sharedPassage});

  @override
  Widget build(BuildContext context) {
    final order = _firstText([q['order'], q['question_number'], q['id']]);
    final type = _firstText([q['question_type'], q['type']]);
    final typeLabel = _questionTypeLabel(type);
    final rawText = _firstText([q['question_text'], q['text']]);
    final explanation = _firstText([q['explanation']]);
    final passage = _firstText([
      q['passage'],
      q['passage_text'],
      q['passage_content'],
      sharedPassage,
    ]);
    debugPrint(
      '[TeacherProblemSetPreview] question=${q['id'] ?? q['question_id']} '
      'type=$type '
      'passage="${_preview(passage)}"',
    );
    final options = _asMapList(q['options']);
    final specialData = _specialData(q);
    final isOrder = type.trim().toLowerCase() == 'order' ||
        specialData['kind']?.toString() == 'order';
    final isInsertion = type.trim().toLowerCase() == 'insertion' ||
        specialData['kind']?.toString() == 'insertion';
    final text = isOrder || isInsertion
        ? _teacherPreviewQuestionText(rawText, type, specialData)
        : rawText;
    final answerIndex = _asInt(q['answer_index']);
    final answerOption =
        answerIndex != null && answerIndex >= 0 && answerIndex < options.length
            ? options[answerIndex]
            : _firstCorrectOption(options);
    final orderAnswerLabel = _orderAnswerSummary(q, specialData);
    final insertionAnswerLabel = _insertionAnswerSummary(q, specialData);
    final answerLabel = isOrder
        ? orderAnswerLabel
        : isInsertion
            ? insertionAnswerLabel
            : _answerSummary(answerOption, answerIndex);
    final answerChipLabel = (isOrder || isInsertion) && answerLabel.isNotEmpty
        ? 'answer $answerLabel'
        : answerLabel;
    final orderBlocks = _orderBlocks(specialData);
    final insertionSentences = _insertionSentences(specialData);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            const BorderSide(color: _TeacherProblemSetPreviewScreenState._line),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          initiallyExpanded: false,
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              order.isEmpty ? '-' : order,
              style: const TextStyle(
                color: _TeacherProblemSetPreviewScreenState._blue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '문항 ${order.isEmpty ? '' : order}',
                style: const TextStyle(
                  color: _TeacherProblemSetPreviewScreenState._ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _SmallChip(text: typeLabel, color: const Color(0xFF7C3AED)),
              if (answerChipLabel.isNotEmpty)
                _SmallChip(
                    text: answerChipLabel, color: const Color(0xFF059669)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text.isEmpty ? '문항 내용 없음' : text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _TeacherProblemSetPreviewScreenState._muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            if (text.isNotEmpty)
              _SectionBlock(label: '문제', child: SelectableText(text)),
            if (isOrder) ...[
              if (_firstText([specialData['fixed_start'], passage]).isNotEmpty)
                _SectionBlock(
                  label: '주어진 글',
                  child: SelectableText(
                    _firstText([specialData['fixed_start'], passage]),
                  ),
                ),
              if (orderBlocks.isNotEmpty)
                _SectionBlock(
                  label: '순서 블록',
                  child: Column(
                    children: [
                      for (final entry in orderBlocks.entries)
                        _OrderBlockRow(label: entry.key, text: entry.value),
                    ],
                  ),
                ),
              if (_firstText([specialData['fixed_end']]).isNotEmpty)
                _SectionBlock(
                  label: '이어질 글',
                  child: SelectableText(_firstText([specialData['fixed_end']])),
                ),
            ] else if (isInsertion) ...[
              if (insertionSentences.isNotEmpty)
                _SectionBlock(
                  label: '주어진 문장들',
                  child: Column(
                    children: [
                      for (final entry in insertionSentences.entries)
                        _OrderBlockRow(label: entry.key, text: entry.value),
                    ],
                  ),
                )
              else if (_firstText([specialData['insert_sentence']]).isNotEmpty)
                _SectionBlock(
                  label: '\uC8FC\uC5B4\uC9C4 \uBB38\uC7A5',
                  child: SelectableText(
                    _firstText([specialData['insert_sentence']]),
                  ),
                ),
              if (_firstText([specialData['passage_with_positions'], passage])
                  .isNotEmpty)
                _SectionBlock(
                  label: '\uBCF8\uBB38',
                  child: SelectableText(
                    _firstText([
                      specialData['passage_with_positions'],
                      passage,
                    ]),
                  ),
                ),
            ] else ...[
              if (passage.isNotEmpty)
                _SectionBlock(label: '지문', child: SelectableText(passage)),
              if (options.isNotEmpty)
                _SectionBlock(
                  label: '보기',
                  child: Column(
                    children: [
                      for (final option in options)
                        _OptionRow(
                          option: option,
                          isCorrect: option == answerOption ||
                              option['is_correct'] == true,
                        ),
                    ],
                  ),
                ),
            ],
            if (answerLabel.isNotEmpty)
              _SectionBlock(
                label: '정답',
                child: Text(
                  answerLabel,
                  style: const TextStyle(
                    color: _TeacherProblemSetPreviewScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            if (explanation.trim().isNotEmpty)
              _SectionBlock(
                label: '해설',
                child: SelectableText(explanation),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderBlockRow extends StatelessWidget {
  const _OrderBlockRow({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '($label)',
              style: const TextStyle(
                color: _TeacherProblemSetPreviewScreenState._blue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              text,
              style: const TextStyle(
                color: _TeacherProblemSetPreviewScreenState._ink,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.option, required this.isCorrect});

  final Map<String, dynamic> option;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final label = _firstText([option['label']]);
    final text = _firstText([option['text']]);
    final accent = isCorrect
        ? const Color(0xFF059669)
        : _TeacherProblemSetPreviewScreenState._muted;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              label,
              style: TextStyle(color: accent, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _TeacherProblemSetPreviewScreenState._ink,
                fontWeight: isCorrect ? FontWeight.w800 : FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _TeacherProblemSetPreviewScreenState._line),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: _TeacherProblemSetPreviewScreenState._ink,
          height: 1.55,
          fontWeight: FontWeight.w500,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _TeacherProblemSetPreviewScreenState._blue,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _TeacherProblemSetPreviewScreenState._line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 15, color: _TeacherProblemSetPreviewScreenState._muted),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: _TeacherProblemSetPreviewScreenState._ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message),
      ),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.map(_asMap).where((item) => item.isNotEmpty).toList();
}

String _firstText(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

String _preview(String text) {
  final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= 60) return compact;
  return '${compact.substring(0, 60)}...';
}

int? _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

Map<String, dynamic> _specialData(Map<String, dynamic> q) {
  final value = q['special_data'] ?? q['specialData'];
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  final raw = q['special_data_json']?.toString().trim() ?? '';
  if (raw.isEmpty || raw == 'null') return <String, dynamic>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {
    return <String, dynamic>{};
  }
  return <String, dynamic>{};
}

Map<String, String> _orderBlocks(Map<String, dynamic> specialData) {
  final rawBlocks = specialData['blocks'];
  if (rawBlocks is! Map) return const <String, String>{};
  final entries = rawBlocks.entries
      .map((entry) => MapEntry(entry.key.toString(), entry.value.toString()))
      .where((entry) =>
          entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return Map<String, String>.fromEntries(entries);
}

Map<String, String> _insertionSentences(Map<String, dynamic> specialData) {
  final rawSentences = specialData['insert_sentences'];
  if (rawSentences is! Map) return const <String, String>{};
  final entries = rawSentences.entries
      .map((entry) => MapEntry(entry.key.toString(), entry.value.toString()))
      .where((entry) =>
          entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return Map<String, String>.fromEntries(entries);
}

String _orderAnswerSummary(
  Map<String, dynamic> q,
  Map<String, dynamic> specialData,
) {
  final direct = _firstText([q['answer_text'], specialData['answer_text']]);
  if (direct.isNotEmpty) return _cleanOrderAnswerText(direct);
  final order = specialData['answer_order'];
  if (order is List && order.isNotEmpty) {
    return order.map((item) => item.toString().trim()).join('-');
  }
  return '';
}

String _insertionAnswerSummary(
  Map<String, dynamic> q,
  Map<String, dynamic> specialData,
) {
  final direct = _firstText([q['answer_text'], specialData['answer_text']]);
  final mode = _firstText([specialData['mode']]).toLowerCase();
  if (direct.isNotEmpty) {
    return mode == 'multiple'
        ? _cleanMultipleInsertionAnswerText(direct)
        : _cleanInsertionAnswerText(direct);
  }
  final positions = specialData['answer_positions'];
  if (positions is Map && positions.isNotEmpty) {
    final entries = positions.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    return entries.map((entry) => '${entry.key}:${entry.value}').join(', ');
  }
  final position = specialData['answer_position'];
  if (position != null) return _cleanInsertionAnswerText(position.toString());
  return '';
}

String _cleanMultipleInsertionAnswerText(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final entries = decoded.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return entries.map((entry) => '${entry.key}:${entry.value}').join(', ');
    }
  } catch (_) {
    // The canonical non-JSON form is handled below.
  }
  return raw
      .replaceAll(RegExp(r'\s*,\s*'), ', ')
      .replaceAll(RegExp(r'\s*:\s*'), ':')
      .trim();
}

String _cleanInsertionAnswerText(String raw) {
  final digit = RegExp(r'[1-9]').firstMatch(raw)?.group(0);
  return digit ?? raw.trim();
}

String _teacherPreviewQuestionText(
  String raw,
  String type,
  Map<String, dynamic> specialData,
) {
  final isInsertion = type.trim().toLowerCase() == 'insertion' ||
      specialData['kind']?.toString().trim().toLowerCase() == 'insertion';
  if (isInsertion) {
    return insertionDisplayPromptForMode(specialData['mode']);
  }
  final cleaned = _stripLeadingAnswerLeak(raw);
  if (cleaned.isNotEmpty) return cleaned;
  if (type.trim().toLowerCase() == 'order' ||
      specialData['kind']?.toString() == 'order') {
    final mode = _firstText([specialData['order_mode']]).toLowerCase();
    if (mode == 'between') {
      return '주어진 글 사이에 이어질 글의 순서를 바르게 배열하시오.';
    }
    if (mode == 'after') {
      return '주어진 글 다음에 이어질 글의 순서를 바르게 배열하시오.';
    }
    return '주어진 글의 순서를 바르게 배열하시오.';
  }
  return cleaned;
}

String _stripLeadingAnswerLeak(String raw) {
  var text = raw.replaceAll('\r\n', '\n').trim();
  if (text.isEmpty) return '';

  final bracketedAnswerPattern = RegExp(
    '^\\s*\\[[^\\]]*(?:\\uC815\\uB2F5|\\uB2F5|answer)[^\\]]*\\]\\s*',
    caseSensitive: false,
  );
  final answerPrefixPattern = RegExp(
    '^\\s*(?:\\uC815\\uB2F5|\\uB2F5|answer)\\s*[:：>▶\\-]?\\s*',
    caseSensitive: false,
  );
  const circledDigits =
      '\u2460\u2461\u2462\u2463\u2464\u2465\u2466\u2467\u2468';
  final leadingAnswerNumberPattern = RegExp(
    '^\\s*(?:[\\(（\\[]?\\s*[$circledDigits]\\s*[\\)）\\]]?\\s*|'
    '[\\(（\\[]?\\s*[1-9]\\s*[\\)）\\].:]\\s*|'
    '[1-9]\\s+)',
  );

  for (var i = 0; i < 3; i++) {
    final before = text;
    text = text.replaceFirst(bracketedAnswerPattern, '');
    text = text.replaceFirst(answerPrefixPattern, '');
    text = text.replaceFirst(leadingAnswerNumberPattern, '');
    text = text.replaceFirst(
      RegExp(
        r'^\s*\[[^\]]*(?:정답|답|answer|뺣떟)[^\]]*\]\s*',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceFirst(
      RegExp(
        r'^\s*(?:정답|답|answer|뺣떟)\s*[:：>▶\-]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceFirst(
      RegExp(
        r'^\s*(?:[\(\[]?[A-Ea-e][\)\]]?\s*(?:[-–—]\s*)?){1,8}',
      ),
      '',
    );
    text = text.trimLeft();
    if (text == before) break;
  }

  return text.trim();
}

String _cleanOrderAnswerText(String raw) {
  final text = _stripLeadingAnswerLeak(raw)
      .replaceAll(RegExp(r'[\(\)\[\]\s]+'), '')
      .replaceAll(RegExp(r'[–—]'), '-')
      .trim();
  return text.isEmpty ? raw.trim() : text;
}

Map<String, int> _typeDistribution(List<Map<String, dynamic>> questions) {
  final result = <String, int>{};
  for (final q in questions) {
    final label =
        _questionTypeLabel(_firstText([q['question_type'], q['type']]));
    result[label] = (result[label] ?? 0) + 1;
  }
  return result;
}

String _questionTypeLabel(String type) {
  final normalized = type.trim().toLowerCase().replaceAll('-', '_');
  return switch (normalized) {
    'blank' || 'cloze' || '빈칸' => '빈칸',
    'topic' || 'main_idea' => '주제',
    'title' => '제목',
    'gist' || 'summary' => '요지',
    'implication' || 'implied' => '함의 추론',
    'purpose' => '목적',
    'mismatch' || 'content_mismatch' => '내용 불일치',
    'content' || 'detail' || 'match' => '내용 일치',
    'order' || 'sequence' => '순서 배열',
    'insert' || 'insertion' => '문장 삽입',
    'grammar' => '어법',
    'vocabulary' || 'vocab' => '어휘',
    _ => type.trim().isEmpty ? '유형 미지정' : type.trim(),
  };
}

Map<String, dynamic>? _firstCorrectOption(List<Map<String, dynamic>> options) {
  for (final option in options) {
    if (option['is_correct'] == true) return option;
  }
  return null;
}

String _answerSummary(Map<String, dynamic>? option, int? answerIndex) {
  if (option == null) {
    return answerIndex == null ? '' : '정답 ${answerIndex + 1}번';
  }
  final label = _firstText([option['label']]);
  final text = _firstText([option['text']]);
  if (label.isEmpty && text.isEmpty) return '';
  return '정답 ${label.isEmpty ? '' : label} ${text.isEmpty ? '' : text}'.trim();
}
