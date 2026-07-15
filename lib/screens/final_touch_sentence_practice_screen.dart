import 'dart:math';

import 'package:flutter/material.dart';

import '../config/auth_store.dart';
import '../models/final_touch.dart';
import '../services/final_touch_practice_result_service.dart';

class FinalTouchSentencePracticeScreen extends StatefulWidget {
  const FinalTouchSentencePracticeScreen({
    super.key,
    required this.detail,
  });

  final FinalTouchDetail detail;

  @override
  State<FinalTouchSentencePracticeScreen> createState() =>
      _FinalTouchSentencePracticeScreenState();
}

class _FinalTouchSentencePracticeScreenState
    extends State<FinalTouchSentencePracticeScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);
  static const _green = Color(0xFF16A34A);
  static const _red = Color(0xFFDC2626);

  final _resultService = const FinalTouchPracticeResultService();
  late final List<_PracticeItem> _items;
  int _index = 0;
  bool _checked = false;
  bool _isCorrect = false;
  bool _savingResult = false;
  bool _completed = false;
  bool _saveFailed = false;
  bool _saveSkipped = false;
  String? _saveError;
  List<String> _selected = const [];
  List<String> _available = const [];
  final Map<String, bool> _answerResults = {};

  @override
  void initState() {
    super.initState();
    _items = _buildItems(widget.detail);
    _resetCurrent();
  }

  void _resetCurrent() {
    if (_items.isEmpty) {
      _selected = const [];
      _available = const [];
      _checked = false;
      _isCorrect = false;
      return;
    }

    final chunks = List<String>.from(_items[_index].chunks);
    chunks.shuffle(Random());
    if (_sameOrder(chunks, _items[_index].chunks) && chunks.length > 1) {
      final first = chunks.removeAt(0);
      chunks.add(first);
    }

    _selected = [];
    _available = chunks;
    _checked = false;
    _isCorrect = false;
  }

  void _selectChunk(String chunk) {
    if (_checked) return;
    setState(() {
      _available = List<String>.from(_available)..remove(chunk);
      _selected = List<String>.from(_selected)..add(chunk);
    });
  }

  void _unselectChunk(String chunk) {
    if (_checked) return;
    setState(() {
      _selected = List<String>.from(_selected)..remove(chunk);
      _available = List<String>.from(_available)..add(chunk);
    });
  }

  Future<void> _checkAnswer() async {
    if (_selected.isEmpty || _checked) return;
    final current = _items[_index];
    final selectedText = _normalize(_selected.join(' '));
    final answerText = _normalize(current.answer);
    final isCorrect = selectedText == answerText;

    setState(() {
      _checked = true;
      _isCorrect = isCorrect;
      _answerResults[current.kind] = isCorrect;
    });

    if (_index == _items.length - 1) {
      await _saveCompletionResult();
    }
  }

  void _next() {
    if (_index >= _items.length - 1) return;
    setState(() {
      _index += 1;
      _resetCurrent();
    });
  }

  void _retryCurrent() {
    setState(() {
      if (_items.isNotEmpty) {
        _answerResults.remove(_items[_index].kind);
      }
      _resetCurrent();
    });
  }

  void _retryAll() {
    setState(() {
      _index = 0;
      _answerResults.clear();
      _savingResult = false;
      _completed = false;
      _saveFailed = false;
      _saveSkipped = false;
      _saveError = null;
      _resetCurrent();
    });
  }

  Future<void> _saveCompletionResult({bool force = false}) async {
    if (_savingResult || (_completed && !force)) return;

    setState(() {
      _savingResult = true;
      _saveFailed = false;
      _saveSkipped = false;
      _saveError = null;
    });

    if (!AuthStore.isStudent) {
      setState(() {
        _savingResult = false;
        _completed = true;
        _saveSkipped = true;
      });
      return;
    }

    try {
      await _resultService.saveResult(
        detail: widget.detail,
        totalQuestions: _items.length,
        correctCount: _correctCount,
        practicedTypes: _items.map((item) => item.kind).toList(),
        wrongTypes: _wrongTypes,
      );
      if (!mounted) return;
      setState(() {
        _savingResult = false;
        _completed = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _savingResult = false;
        _completed = true;
        _saveFailed = true;
        _saveError = '$error';
      });
    }
  }

  int get _correctCount =>
      _answerResults.values.where((isCorrect) => isCorrect).length;

  List<String> get _wrongTypes {
    return _items
        .where((item) => _answerResults[item.kind] == false)
        .map((item) => item.kind)
        .toList();
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
        title: const Text(
          '핵심 문장 조립 연습',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _items.isEmpty ? _emptyState(context) : _practiceBody(),
    );
  }

  Widget _practiceBody() {
    final item = _items[_index];
    final progress = '${_index + 1} / ${_items.length}';

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _HeaderCard(source: widget.detail.source),
        const SizedBox(height: 14),
        _ProgressCard(
          progress: progress,
          typeLabel: item.typeLabel,
          instruction: item.instruction,
          korean: item.korean,
        ),
        const SizedBox(height: 14),
        _AnswerArea(
          selected: _selected,
          checked: _checked,
          isCorrect: _isCorrect,
          onTap: _unselectChunk,
        ),
        const SizedBox(height: 14),
        _ChunkBank(
          chunks: _available,
          checked: _checked,
          onTap: _selectChunk,
        ),
        if (_checked) ...[
          const SizedBox(height: 14),
          _FeedbackCard(
            isCorrect: _isCorrect,
            answer: item.answer,
          ),
        ],
        if (_savingResult || _completed) ...[
          const SizedBox(height: 14),
          _CompletionSummaryCard(
            totalQuestions: _items.length,
            correctCount: _correctCount,
            wrongTypes: _wrongTypes,
            saving: _savingResult,
            saveFailed: _saveFailed,
            saveSkipped: _saveSkipped,
            saveError: _saveError,
            onRetry: _retryAll,
            onRetrySave: () {
              _saveCompletionResult(force: true);
            },
            onBack: () => Navigator.pop(context, !_saveSkipped && !_saveFailed),
          ),
        ],
        if (!_completed && !_savingResult) ...[
          const SizedBox(height: 18),
          _Actions(
            canCheck: _selected.isNotEmpty && !_checked,
            canNext: _checked && _index < _items.length - 1,
            isLast: _index == _items.length - 1,
            onCheck: () {
              _checkAnswer();
            },
            onReset: _retryCurrent,
            onNext: _next,
          ),
        ],
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.extension_off_outlined, color: _blue, size: 38),
              const SizedBox(height: 12),
              const Text(
                '문장 조립 연습을 만들 수 있는 주제/제목 정보가 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Final Touch 분석에서 주제와 제목을 다시 확인해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, height: 1.45),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _FinalTouchSentencePracticeScreenState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.extension_rounded,
              color: _FinalTouchSentencePracticeScreenState._blue,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '핵심 문장 조립 연습',
                  style: TextStyle(
                    color: _FinalTouchSentencePracticeScreenState._ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  source.trim().isEmpty
                      ? '저장된 Final Touch의 제목과 주제를 조립합니다.'
                      : source,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _FinalTouchSentencePracticeScreenState._muted,
                    height: 1.35,
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.typeLabel,
    required this.instruction,
    required this.korean,
  });

  final String progress;
  final String typeLabel;
  final String instruction;
  final String korean;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _FinalTouchSentencePracticeScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                progress,
                style: const TextStyle(
                  color: _FinalTouchSentencePracticeScreenState._muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                    color: _FinalTouchSentencePracticeScreenState._blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            instruction,
            style: const TextStyle(
              color: _FinalTouchSentencePracticeScreenState._ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '한국어 힌트',
                  style: TextStyle(
                    color: _FinalTouchSentencePracticeScreenState._blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  korean.trim().isEmpty ? '-' : korean,
                  style: const TextStyle(
                    color: _FinalTouchSentencePracticeScreenState._ink,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
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

class _AnswerArea extends StatelessWidget {
  const _AnswerArea({
    required this.selected,
    required this.checked,
    required this.isCorrect,
    required this.onTap,
  });

  final List<String> selected;
  final bool checked;
  final bool isCorrect;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final color = !checked
        ? _FinalTouchSentencePracticeScreenState._blue
        : isCorrect
            ? _FinalTouchSentencePracticeScreenState._green
            : _FinalTouchSentencePracticeScreenState._red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '정답 영역',
            style: TextStyle(
              color: _FinalTouchSentencePracticeScreenState._ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (selected.isEmpty)
            const Text(
              '아래 chunk를 눌러 순서대로 문장을 완성하세요.',
              style: TextStyle(
                color: _FinalTouchSentencePracticeScreenState._muted,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chunk in selected)
                  _ChunkChip(
                    chunk: chunk,
                    color: color,
                    filled: true,
                    onTap: () => onTap(chunk),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChunkBank extends StatelessWidget {
  const _ChunkBank({
    required this.chunks,
    required this.checked,
    required this.onTap,
  });

  final List<String> chunks;
  final bool checked;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _FinalTouchSentencePracticeScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '선택지',
            style: TextStyle(
              color: _FinalTouchSentencePracticeScreenState._ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (chunks.isEmpty)
            const Text(
              '선택할 chunk가 없습니다.',
              style: TextStyle(
                color: _FinalTouchSentencePracticeScreenState._muted,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chunk in chunks)
                  _ChunkChip(
                    chunk: chunk,
                    color: _FinalTouchSentencePracticeScreenState._blue,
                    filled: false,
                    onTap: checked ? null : () => onTap(chunk),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChunkChip extends StatelessWidget {
  const _ChunkChip({
    required this.chunk,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  final String chunk;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Text(
          chunk,
          style: TextStyle(
            color: filled ? color : _FinalTouchSentencePracticeScreenState._ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.isCorrect,
    required this.answer,
  });

  final bool isCorrect;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect
        ? _FinalTouchSentencePracticeScreenState._green
        : _FinalTouchSentencePracticeScreenState._red;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? '정답입니다.' : '아쉬워요. 정답을 확인해 보세요.',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              answer,
              style: const TextStyle(
                color: _FinalTouchSentencePracticeScreenState._ink,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletionSummaryCard extends StatelessWidget {
  const _CompletionSummaryCard({
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongTypes,
    required this.saving,
    required this.saveFailed,
    required this.saveSkipped,
    required this.saveError,
    required this.onRetry,
    required this.onRetrySave,
    required this.onBack,
  });

  final int totalQuestions;
  final int correctCount;
  final List<String> wrongTypes;
  final bool saving;
  final bool saveFailed;
  final bool saveSkipped;
  final String? saveError;
  final VoidCallback onRetry;
  final VoidCallback onRetrySave;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final accuracy =
        totalQuestions == 0 ? 0 : (correctCount / totalQuestions * 100).round();
    final wrongText = wrongTypes.isEmpty
        ? '틀린 유형이 없습니다.'
        : wrongTypes.map(_practiceTypeLabel).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: _FinalTouchSentencePracticeScreenState._blue,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '문장 조립 연습 완료',
                  style: TextStyle(
                    color: _FinalTouchSentencePracticeScreenState._ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryPill(
                  label: '정답', value: '$correctCount / $totalQuestions'),
              _SummaryPill(label: '정답률', value: '$accuracy%'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '보완 유형: $wrongText',
            style: const TextStyle(
              color: _FinalTouchSentencePracticeScreenState._ink,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (saving)
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 9),
                Text(
                  '연습 결과를 저장하는 중입니다.',
                  style: TextStyle(
                    color: _FinalTouchSentencePracticeScreenState._muted,
                  ),
                ),
              ],
            )
          else if (saveSkipped)
            const Text(
              '교사용 미리보기에서는 학생 연습 기록을 저장하지 않습니다.',
              style: TextStyle(
                color: _FinalTouchSentencePracticeScreenState._muted,
                height: 1.45,
              ),
            )
          else if (saveFailed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                '결과 저장에 실패했습니다. 연습은 완료되었습니다.\n${saveError ?? ''}',
                style: const TextStyle(
                  color: _FinalTouchSentencePracticeScreenState._red,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const Text(
              '연습 결과가 저장되었습니다. Final Touch 상세에서 최근 결과를 확인할 수 있습니다.',
              style: TextStyle(
                color: _FinalTouchSentencePracticeScreenState._green,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('다시 풀기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Final Touch로 돌아가기'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _FinalTouchSentencePracticeScreenState._blue,
                  ),
                ),
              ),
            ],
          ),
          if (saveFailed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetrySave,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('저장 다시 시도'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: _FinalTouchSentencePracticeScreenState._blue,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.canCheck,
    required this.canNext,
    required this.isLast,
    required this.onCheck,
    required this.onReset,
    required this.onNext,
  });

  final bool canCheck;
  final bool canNext;
  final bool isLast;
  final VoidCallback onCheck;
  final VoidCallback onReset;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.icon(
            onPressed: canCheck ? onCheck : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('확인'),
            style: FilledButton.styleFrom(
              backgroundColor: _FinalTouchSentencePracticeScreenState._blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 풀기'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canNext ? onNext : null,
                icon: Icon(
                  isLast ? Icons.flag_outlined : Icons.arrow_forward_rounded,
                ),
                label: Text(isLast ? '마지막 문제' : '다음 문제'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PracticeItem {
  const _PracticeItem({
    required this.kind,
    required this.typeLabel,
    required this.instruction,
    required this.answer,
    required this.korean,
    required this.chunks,
  });

  final String kind;
  final String typeLabel;
  final String instruction;
  final String answer;
  final String korean;
  final List<String> chunks;
}

List<_PracticeItem> _buildItems(FinalTouchDetail detail) {
  final candidates = [
    (
      kind: 'title',
      label: '제목 조립',
      instruction: '다음 제목을 완성하세요.',
      english: _firstPracticeText([
        detail.titleEn,
        _englishFromMixed(detail.titleKo),
        detail.source,
      ]),
      korean: _firstPracticeText([
        detail.titleKo,
        detail.topicKo,
        detail.gistKo,
      ]),
    ),
    (
      kind: 'topic',
      label: '주제 조립',
      instruction: '다음 주제문을 완성하세요.',
      english: _firstPracticeText([
        detail.topicEn,
        _englishFromMixed(detail.topicKo),
        detail.gistEn,
        detail.summaryEn,
        detail.titleEn,
        _firstEnglishSentence(detail),
      ]),
      korean: _firstPracticeText([
        detail.topicKo,
        detail.gistKo,
        detail.summaryKo,
        detail.titleKo,
      ]),
    ),
    (
      kind: 'gist',
      label: '요지 조립',
      instruction: '다음 요지문을 완성하세요.',
      english: _firstPracticeText([
        detail.gistEn,
        _englishFromMixed(detail.gistKo),
        detail.summaryEn,
        detail.topicEn,
        _firstEnglishSentence(detail),
      ]),
      korean: _firstPracticeText([
        detail.gistKo,
        detail.summaryKo,
        detail.topicKo,
      ]),
    ),
  ];

  final items = <_PracticeItem>[];
  for (final candidate in candidates) {
    if (!_isValidPracticeText(candidate.english, kind: candidate.kind)) {
      continue;
    }
    final chunks = _chunkText(candidate.english);
    if (chunks.length < 3 || chunks.length > 7) continue;
    items.add(
      _PracticeItem(
        kind: candidate.kind,
        typeLabel: candidate.label,
        instruction: candidate.instruction,
        answer: candidate.english.trim(),
        korean: candidate.korean,
        chunks: chunks,
      ),
    );
  }
  return items;
}

String _firstPracticeText(Iterable<String> values) {
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

String _englishFromMixed(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final lines = trimmed
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty);
  for (final line in lines) {
    final candidate = line.contains(RegExp(r'[\uAC00-\uD7A3]'))
        ? line.substring(
            0, RegExp(r'[\uAC00-\uD7A3]').firstMatch(line)?.start ?? 0)
        : line;
    final cleaned = candidate
        .replaceAll(
            RegExp(r'^(EN|영어|주제|제목|요지)\s*[:：]\s*', caseSensitive: false), '')
        .trim();
    if (RegExp(r'[A-Za-z]').hasMatch(cleaned) &&
        !RegExp(r'[\uAC00-\uD7A3]').hasMatch(cleaned)) {
      return cleaned;
    }
  }
  return '';
}

String _firstEnglishSentence(FinalTouchDetail detail) {
  for (final sentence in detail.sentenceDetails) {
    final text = sentence.original.trim();
    if (RegExp(r'[A-Za-z]').hasMatch(text)) return text;
  }
  final passage = detail.passage.trim();
  if (passage.isEmpty) return '';
  final firstLine =
      passage.split(RegExp(r'\r?\n')).map((line) => line.trim()).firstWhere(
            (line) => RegExp(r'[A-Za-z]').hasMatch(line),
            orElse: () => '',
          );
  return firstLine;
}

bool _isValidPracticeText(String value, {required String kind}) {
  final text = value.trim();
  if (text.isEmpty) return false;

  final lower = text.toLowerCase();
  const badValues = [
    'central idea and supporting evidence',
    "the passage's central idea and supporting evidence",
    'the passage presents a central idea',
    'the passage develops the teacher-selected idea',
    'key idea of the passage',
    '지문의 핵심 생각',
    '핵심 주장과 근거',
  ];
  if (badValues.any(lower.contains)) return false;

  final words = _words(text);
  if (kind == 'gist') {
    if (words.length < 5 || words.length > 20) return false;
  } else if (words.length <= 2 || words.length > 25) {
    return false;
  }
  return true;
}

List<String> _chunkText(String value) {
  final tokens = _words(value);
  if (tokens.length <= 4) return tokens;

  var chunkCount = (tokens.length / 3).ceil().clamp(3, 7);
  while ((tokens.length / chunkCount).ceil() > 4 && chunkCount < 7) {
    chunkCount += 1;
  }

  final chunks = <String>[];
  var index = 0;
  for (var chunkIndex = 0; chunkIndex < chunkCount; chunkIndex++) {
    final remainingTokens = tokens.length - index;
    final remainingChunks = chunkCount - chunkIndex;
    final size = (remainingTokens / remainingChunks).ceil().clamp(1, 4);
    chunks.add(tokens.sublist(index, index + size).join(' '));
    index += size;
  }

  return chunks.where((chunk) => chunk.trim().isNotEmpty).toList();
}

List<String> _words(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .split(' ')
      .where((word) => word.trim().isNotEmpty)
      .toList();
}

bool _sameOrder(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _normalize(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAllMapped(RegExp(r'\s+([.,!?;:])'), (match) => match.group(1)!)
      .toLowerCase();
}

String _practiceTypeLabel(String kind) {
  switch (kind) {
    case 'title':
      return '제목';
    case 'topic':
      return '주제';
    case 'gist':
      return '요지';
    default:
      return kind;
  }
}
