import 'package:flutter/material.dart';

import '../models/learning_assignment.dart';
import '../models/workbook.dart';
import '../models/workbook_attempt.dart';
import '../services/learning_assignment_service.dart';
import '../services/workbook_attempt_service.dart';
import '../services/workbook_service.dart';

class StudentWorkbookViewScreen extends StatefulWidget {
  const StudentWorkbookViewScreen({
    super.key,
    required this.assignment,
  });

  final LearningAssignment assignment;

  @override
  State<StudentWorkbookViewScreen> createState() =>
      _StudentWorkbookViewScreenState();
}

class _StudentWorkbookViewScreenState extends State<StudentWorkbookViewScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF64748B);
  static const _blue = Color(0xFF2563EB);
  static const _line = Color(0xFFE2E8F0);

  final _workbookService = const WorkbookService();
  final _assignmentService = const LearningAssignmentService();
  final _attemptService = const WorkbookAttemptService();
  final Map<int, int> _multipleChoiceAnswers = {};
  final Map<int, bool> _trueFalseAnswers = {};
  final Map<int, List<String>> _paragraphOrderAnswers = {};
  final Map<int, TextEditingController> _textControllers = {};
  final ScrollController _scrollController = ScrollController();

  late Future<Workbook> _future;
  // Kept only for the deprecated completion path below; the active flow uses
  // attempt submission.
  // ignore: unused_field
  bool _isCompleting = false;
  bool _isSubmitting = false;
  bool _isRetakeMode = false;
  bool _submittedInSession = false;
  int? _selectedSectionId;
  String? _selectedSectionTitle;
  Workbook? _loadedWorkbook;
  WorkbookAttempt? _lastAttempt;

  @override
  void initState() {
    super.initState();
    _future = _workbookService.fetchStudentWorkbook(
      widget.assignment.contentId,
      sectionId: _selectedSectionId,
    );
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _restartPractice() async {
    final ok = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.replay_rounded, color: _blue),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '워크북 다시 풀기',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '현재 화면에서 선택한 답을 초기화하고 다시 풀어볼까요?',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15.5,
                    height: 1.45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  '완료 기록은 유지되며, 답안 저장과 채점은 다음 단계에서 연결됩니다.',
                  style: TextStyle(
                    color: _muted,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('다시 풀기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;

    setState(() {
      _isRetakeMode = true;
      _lastAttempt = null;
      _multipleChoiceAnswers.clear();
      _trueFalseAnswers.clear();
      _paragraphOrderAnswers.clear();
      for (final controller in _textControllers.values) {
        controller.clear();
      }
    });
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('다시 풀기를 시작합니다.')),
    );
  }

  // ignore: unused_element
  Future<void> _complete() async {
    await _submitWorkbook();
    return;
    // ignore: dead_code
    final ok = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '워크북 학습 완료',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '이 워크북 학습을 완료 처리할까요?',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15.5,
                    height: 1.45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  '완료 후 내 학습 화면에서 상태가 완료로 표시됩니다. 답안 저장과 채점은 다음 단계에서 연결합니다.',
                  style: TextStyle(
                    color: _muted,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('계속 학습'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('완료하기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;

    setState(() => _isCompleting = true);
    try {
      await _assignmentService.completeAssignment(widget.assignment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('워크북 학습을 완료했습니다.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('완료 처리 실패: $error')),
      );
    }
  }

  Future<void> _submitWorkbook() async {
    final workbook = _loadedWorkbook;
    if (workbook == null || _isSubmitting) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('워크북 제출'),
        content: const Text(
          '답안을 제출하고 결과를 확인할까요?\n제출 후 점수와 정오답을 확인할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 풀기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('제출하기'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _isSubmitting = true);
    try {
      final attempt = await _attemptService.submit(
        assignmentId: widget.assignment.id,
        workbookId: workbook.id,
        sectionId: _selectedSectionId,
        answers: _buildSubmitAnswers(workbook),
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isRetakeMode = false;
        _submittedInSession = true;
        _lastAttempt = attempt;
      });
      await _showAttemptResult(attempt, workbook.title);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('워크북 제출 실패: $error')),
      );
    }
  }

  Future<void> _showLatestResult() async {
    final workbook = _loadedWorkbook;
    if (workbook == null) return;
    final cachedAttempt = _lastAttempt;
    if (cachedAttempt != null) {
      await _showAttemptResult(cachedAttempt, workbook.title);
      return;
    }
    try {
      final attempt =
          await _attemptService.fetchLatestForStudent(widget.assignment.id);
      if (!mounted) return;
      if (attempt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('아직 제출한 결과가 없습니다. 다시 풀기를 눌러 답안을 제출하면 결과를 확인할 수 있습니다.'),
          ),
        );
        return;
      }
      await _showAttemptResult(attempt, workbook.title);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('아직 제출한 결과가 없습니다. 다시 풀기를 눌러 답안을 제출하면 결과를 확인할 수 있습니다.'),
        ),
      );
    }
  }

  Future<void> _showAttemptResult(
    WorkbookAttempt attempt,
    String workbookTitle,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _WorkbookAttemptResultDialog(
        attempt: attempt,
        workbookTitle: workbookTitle,
      ),
    );
  }

  List<Map<String, dynamic>> _buildSubmitAnswers(Workbook workbook) {
    final answers = <Map<String, dynamic>>[];
    for (final question in workbook.questions) {
      if (question.questionType == 'inline_choice') {
        for (final item in _contentItems(question.content)) {
          final number = _asInt(item['number']);
          final choices = _stringList(item['choices']);
          final selected =
              _multipleChoiceAnswers[_localKey(question.id, number)];
          final value =
              selected != null && selected >= 0 && selected < choices.length
                  ? choices[selected]
                  : null;
          answers.add({
            'question_id': question.id,
            'question_type': question.questionType,
            'item_number': number,
            'student_answer': value,
          });
        }
        continue;
      }
      if (question.questionType == 'true_false' &&
          question.content['items'] is List) {
        final subtype = question.content['subtype'];
        for (final item in _contentItems(question.content)) {
          final number = _asInt(item['number']);
          final selected = _trueFalseAnswers[_localKey(question.id, number)];
          answers.add({
            'question_id': question.id,
            'question_type': question.questionType,
            if (subtype != null) 'subtype': subtype,
            'item_number': number,
            'student_answer': selected == null ? null : (selected ? 'T' : 'F'),
          });
        }
        continue;
      }
      if (question.questionType == 'check_learning_set') {
        final sectionB = _asMap(question.content['section_b']);
        final wordBank = _stringList(sectionB['word_bank']);
        final blankCount = _asInt(sectionB['blank_count']);
        for (var index = 1; index <= blankCount; index++) {
          final selected =
              _multipleChoiceAnswers[_localKey(question.id, index)];
          final value =
              selected != null && selected >= 0 && selected < wordBank.length
                  ? wordBank[selected]
                  : null;
          answers.add({
            'question_id': question.id,
            'question_type': question.questionType,
            'item_number': index,
            'student_answer': value,
          });
        }
        continue;
      }
      if (question.questionType == 'initial_blank') {
        final items = _contentItems(question.content);
        for (var index = 0; index < items.length; index++) {
          final item = items[index];
          final label = _asString(item['label']);
          final keyNumber = index + 1;
          answers.add({
            'question_id': question.id,
            'question_type': question.questionType,
            'item_number': keyNumber,
            'student_answer':
                _textControllers[_localKey(question.id, keyNumber)]
                    ?.text
                    .trim(),
            'subtype': label,
          });
        }
        continue;
      }
      if (question.questionType == 'sentence_insertion') {
        final positions = _stringList(question.content['positions']);
        final selected = _multipleChoiceAnswers[question.id];
        answers.add({
          'question_id': question.id,
          'question_type': question.questionType,
          'item_number': 1,
          'student_answer':
              selected != null && selected >= 0 && selected < positions.length
                  ? positions[selected]
                  : null,
        });
        continue;
      }
      if (question.questionType == 'paragraph_order') {
        final order = _paragraphOrderAnswers[question.id] ?? const <String>[];
        answers.add({
          'question_id': question.id,
          'question_type': question.questionType,
          'item_number': 1,
          'student_answer': order.join('-'),
        });
        continue;
      }
      if (question.questionType == 'multiple_choice') {
        final selected = _multipleChoiceAnswers[question.id];
        final value = selected != null &&
                selected >= 0 &&
                selected < question.choices.length
            ? question.choices[selected]
            : null;
        answers.add({
          'question_id': question.id,
          'question_type': question.questionType,
          'student_answer': value,
        });
        continue;
      }
      if (question.questionType == 'true_false') {
        final selected = _trueFalseAnswers[question.id];
        answers.add({
          'question_id': question.id,
          'question_type': question.questionType,
          'student_answer': selected == null ? null : (selected ? 'T' : 'F'),
        });
        continue;
      }
      answers.add({
        'question_id': question.id,
        'question_type': question.questionType,
        'student_answer': _textControllers[question.id]?.text.trim(),
      });
    }
    return answers;
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
          '워크북 학습',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<Workbook>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _StateMessage(
              title: '워크북을 불러오지 못했습니다.',
              message: '${snapshot.error}',
              onRetry: () => setState(() {
                _future = _workbookService.fetchStudentWorkbook(
                  widget.assignment.contentId,
                  sectionId: _selectedSectionId,
                );
              }),
            );
          }
          final workbook = snapshot.data;
          if (workbook == null) {
            return const _StateMessage(
              title: '워크북을 찾을 수 없습니다.',
              message: '배포된 자료인지 다시 확인해 주세요.',
            );
          }
          _loadedWorkbook = workbook;
          final completedForUi =
              widget.assignment.isCompleted || _submittedInSession;
          final needsSectionSelection =
              workbook.sections.length > 1 && _selectedSectionId == null;
          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
            children: [
              _HeaderCard(
                assignment: widget.assignment,
                workbook: workbook,
                selectedSectionTitle: _selectedSectionTitle,
              ),
              if (needsSectionSelection) ...[
                const SizedBox(height: 14),
                _StudentSectionSelectionCard(
                  workbook: workbook,
                  onSelected: (section) {
                    setState(() {
                      _selectedSectionId = section.id;
                      _selectedSectionTitle = section.title;
                      _future = _workbookService.fetchStudentWorkbook(
                        widget.assignment.contentId,
                        sectionId: section.id,
                      );
                    });
                  },
                ),
              ] else ...[
                if (completedForUi && !_isRetakeMode) ...[
                  const SizedBox(height: 14),
                  const _CompletedPracticeNotice(),
                ],
                const SizedBox(height: 14),
                const _WorkbookQuestionSectionHeader(),
                const SizedBox(height: 10),
                if (workbook.questions.isEmpty)
                  const _EmptyQuestionCard()
                else
                  ...workbook.questions.map(_buildQuestionCard),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _line)),
          ),
          child: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final workbook = _loadedWorkbook;
    if (workbook != null &&
        workbook.sections.length > 1 &&
        _selectedSectionId == null) {
      return _BackToLearningButton(
          onPressed: () => Navigator.pop(context, false));
    }
    final completedForUi = widget.assignment.isCompleted || _submittedInSession;
    if (completedForUi && !_isRetakeMode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showLatestResult,
                  icon: const Icon(Icons.insights_rounded),
                  label: const Text('결과 보기'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _restartPractice,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('다시 풀기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _BackToLearningButton(onPressed: () => Navigator.pop(context, false)),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: _BackToLearningButton(
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitWorkbook,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isSubmitting ? '제출 중...' : '제출하기'),
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(WorkbookQuestion question) {
    final contentPassage = _asString(question.content['passage_text']);
    final displayPassage = renderInlineChoicePassageForStudent(
      (question.passageText ?? '').isNotEmpty
          ? question.passageText!
          : contentPassage,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  '${question.orderIndex}',
                  style: const TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${question.orderIndex}번 문제',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _TypePill(text: workbookQuestionDisplayLabel(question)),
            ],
          ),
          if (displayPassage.isNotEmpty &&
              question.questionType != 'sentence_insertion') ...[
            const SizedBox(height: 12),
            const _QuestionSectionLabel(
              icon: Icons.article_outlined,
              label: '자료',
            ),
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5EAF3)),
              ),
              child: Text(
                displayPassage,
                style: const TextStyle(
                  color: _ink,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const _QuestionSectionLabel(
            icon: Icons.help_outline_rounded,
            label: '지시문',
          ),
          const SizedBox(height: 7),
          Text(
            question.prompt,
            style: const TextStyle(
              color: _ink,
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const _QuestionSectionLabel(
            icon: Icons.edit_rounded,
            label: '답안 영역',
          ),
          const SizedBox(height: 7),
          _answerArea(question),
        ],
      ),
    );
  }

  Widget _answerArea(WorkbookQuestion question) {
    if (question.questionType == 'inline_choice') {
      return _InlineChoiceInput(
        question: question,
        selected: _multipleChoiceAnswers,
        onChanged: (key, value) {
          setState(() => _multipleChoiceAnswers[key] = value);
        },
      );
    }
    if (question.questionType == 'true_false' &&
        question.content['items'] is List) {
      return _TrueFalseSetInput(
        question: question,
        selected: _trueFalseAnswers,
        onChanged: (key, value) {
          setState(() => _trueFalseAnswers[key] = value);
        },
      );
    }
    if (question.questionType == 'check_learning_set') {
      return _CheckLearningSetInput(
        question: question,
        selectedChoices: _multipleChoiceAnswers,
        onChoiceChanged: (key, value) {
          setState(() => _multipleChoiceAnswers[key] = value);
        },
      );
    }
    if (question.questionType == 'initial_blank') {
      return _InitialBlankInput(
        question: question,
        controllers: _textControllers,
      );
    }
    if (question.questionType == 'sentence_insertion') {
      return _SentenceInsertionInput(
        question: question,
        selected: _multipleChoiceAnswers[question.id],
        onChanged: (value) {
          setState(() => _multipleChoiceAnswers[question.id] = value);
        },
      );
    }
    if (question.questionType == 'paragraph_order') {
      return _ParagraphOrderInput(
        question: question,
        selectedOrder: _paragraphOrderAnswers[question.id] ?? const [],
        onChanged: (value) {
          setState(() => _paragraphOrderAnswers[question.id] = value);
        },
      );
    }
    return switch (question.questionType) {
      'multiple_choice' => _MultipleChoiceInput(
          question: question,
          selected: _multipleChoiceAnswers[question.id],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _multipleChoiceAnswers[question.id] = value);
          },
        ),
      'true_false' => _TrueFalseInput(
          selected: _trueFalseAnswers[question.id],
          onChanged: (value) {
            setState(() => _trueFalseAnswers[question.id] = value);
          },
        ),
      _ => TextField(
          controller: _textControllers.putIfAbsent(
            question.id,
            () => TextEditingController(),
          ),
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '답안을 입력해 보세요.',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _line),
            ),
          ),
        ),
    };
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.assignment,
    required this.workbook,
    this.selectedSectionTitle,
  });

  final LearningAssignment assignment;
  final Workbook workbook;
  final String? selectedSectionTitle;

  @override
  Widget build(BuildContext context) {
    final meta = [
      workbook.sourceLabel,
      workbook.folderName,
      workbook.unitLabel,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _StudentWorkbookViewScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _StudentWorkbookViewScreenState._blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workbook.title,
                      style: const TextStyle(
                        color: _StudentWorkbookViewScreenState._ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        style: const TextStyle(
                          color: _StudentWorkbookViewScreenState._muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if ((workbook.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              workbook.description!,
              style: const TextStyle(
                color: _StudentWorkbookViewScreenState._muted,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if ((assignment.teacherMessage ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5EAF3)),
              ),
              child: Text(
                assignment.teacherMessage!,
                style: const TextStyle(
                  color: _StudentWorkbookViewScreenState._muted,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(text: '${workbook.questionCount}문항'),
              _MiniChip(text: _statusLabel(assignment.status)),
              if ((selectedSectionTitle ?? '').trim().isNotEmpty)
                _MiniChip(text: '섹션 ${selectedSectionTitle!.trim()}'),
              if ((assignment.dueAt ?? '').isNotEmpty)
                _MiniChip(text: '마감 ${_dateText(assignment.dueAt!)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentSectionSelectionCard extends StatelessWidget {
  const _StudentSectionSelectionCard({
    required this.workbook,
    required this.onSelected,
  });

  final Workbook workbook;
  final ValueChanged<WorkbookSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _StudentWorkbookViewScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '학습할 섹션을 선택하세요',
            style: TextStyle(
              color: _StudentWorkbookViewScreenState._ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '강 또는 Test 단위로 나누어 필요한 부분만 풀 수 있습니다.',
            style: TextStyle(
              color: _StudentWorkbookViewScreenState._muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          for (final section in workbook.sections)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5EAF3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: _StudentWorkbookViewScreenState._blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            color: _StudentWorkbookViewScreenState._ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${section.questionCount}문항',
                          style: const TextStyle(
                            color: _StudentWorkbookViewScreenState._muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: section.questionCount <= 0
                        ? null
                        : () => onSelected(section),
                    style: FilledButton.styleFrom(
                      backgroundColor: _StudentWorkbookViewScreenState._blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('시작하기'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CompletedPracticeNotice extends StatelessWidget {
  const _CompletedPracticeNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.replay_rounded,
              color: _StudentWorkbookViewScreenState._blue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '완료된 워크북입니다. 다시 풀기를 누르면 화면의 선택값만 초기화하여 복습할 수 있습니다.',
              style: TextStyle(
                color: _StudentWorkbookViewScreenState._ink,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbookAttemptResultDialog extends StatelessWidget {
  const _WorkbookAttemptResultDialog({
    required this.attempt,
    required this.workbookTitle,
  });

  final WorkbookAttempt attempt;
  final String workbookTitle;

  @override
  Widget build(BuildContext context) {
    final score = _formatScore(attempt.scorePercent);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _StudentWorkbookViewScreenState._line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 28,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: _StudentWorkbookViewScreenState._blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '워크북 결과',
                            style: TextStyle(
                              color: _StudentWorkbookViewScreenState._ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            workbookTitle,
                            style: const TextStyle(
                              color: _StudentWorkbookViewScreenState._muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5EAF3)),
                  ),
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _ResultMetric(label: '점수', value: '$score점'),
                      _ResultMetric(
                        label: '정답',
                        value:
                            '${attempt.correctCount}/${attempt.totalQuestions}',
                      ),
                      _ResultMetric(
                          label: '시도', value: '${attempt.attemptNo}회차'),
                      _ResultMetric(
                        label: '제출',
                        value: _dateOrDash(attempt.submittedAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '문항별 결과',
                  style: TextStyle(
                    color: _StudentWorkbookViewScreenState._ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                if (attempt.results.isEmpty)
                  const Text(
                    '표시할 문항별 결과가 없습니다.',
                    style: TextStyle(
                      color: _StudentWorkbookViewScreenState._muted,
                    ),
                  )
                else
                  ...attempt.results.map(_AttemptAnswerTile.new),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _StudentWorkbookViewScreenState._blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackToLearningButton extends StatelessWidget {
  const _BackToLearningButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.list_alt_rounded),
      label: const Text('내 학습으로'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _StudentWorkbookViewScreenState._muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: _StudentWorkbookViewScreenState._ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptAnswerTile extends StatelessWidget {
  const _AttemptAnswerTile(this.result);

  final WorkbookAttemptAnswerResult result;

  @override
  Widget build(BuildContext context) {
    final color =
        result.isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final bg =
        result.isCorrect ? const Color(0xFFEFFDF5) : const Color(0xFFFEF2F2);
    final titleNumber =
        result.itemNumber == null ? '' : ' ${result.itemNumber}번';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: Text(
                  result.isCorrect ? 'O' : 'X',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_questionTypeLabel(result.questionType)}$titleNumber',
                  style: const TextStyle(
                    color: _StudentWorkbookViewScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _AnswerLine(
            label: '내 답',
            value: _emptyDash(result.studentAnswer),
          ),
          _AnswerLine(
            label: '정답',
            value: _emptyDash(result.correctAnswer),
          ),
          if ((result.explanation ?? '').trim().isNotEmpty)
            _AnswerLine(
              label: '해설',
              value: result.explanation!.trim(),
            ),
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: const TextStyle(
                color: _StudentWorkbookViewScreenState._muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _StudentWorkbookViewScreenState._ink,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultipleChoiceInput extends StatelessWidget {
  const _MultipleChoiceInput({
    required this.question,
    required this.selected,
    required this.onChanged,
  });

  final WorkbookQuestion question;
  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (question.choices.isEmpty) {
      return const Text(
        '선택지가 없습니다.',
        style: TextStyle(color: _StudentWorkbookViewScreenState._muted),
      );
    }
    return Column(
      children: [
        for (final entry in question.choices.asMap().entries)
          RadioListTile<int>(
            value: entry.key,
            groupValue: selected,
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${entry.key + 1}. ${entry.value}',
              style: const TextStyle(
                color: _StudentWorkbookViewScreenState._ink,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _InlineChoiceInput extends StatelessWidget {
  const _InlineChoiceInput({
    required this.question,
    required this.selected,
    required this.onChanged,
  });

  final WorkbookQuestion question;
  final Map<int, int> selected;
  final void Function(int key, int value) onChanged;

  @override
  Widget build(BuildContext context) {
    final items = _contentItems(question.content);
    if (items.isEmpty) {
      return const Text(
        '표시할 선택 항목이 없습니다.',
        style: TextStyle(color: _StudentWorkbookViewScreenState._muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          _InlineChoiceItemRow(
            questionId: question.id,
            item: item,
            selected: selected[_localKey(question.id, _asInt(item['number']))],
            onChanged: onChanged,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _InlineChoiceItemRow extends StatelessWidget {
  const _InlineChoiceItemRow({
    required this.questionId,
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  final int questionId;
  final Map<String, dynamic> item;
  final int? selected;
  final void Function(int key, int value) onChanged;

  @override
  Widget build(BuildContext context) {
    final number = _asInt(item['number']);
    final choices = _stringList(item['choices']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number번',
            style: const TextStyle(
              color: _StudentWorkbookViewScreenState._blue,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < choices.length; index++)
                ChoiceChip(
                  selected: selected == index,
                  label: Text(choices[index]),
                  onSelected: (_) =>
                      onChanged(_localKey(questionId, number), index),
                  selectedColor: const Color(0xFFDBEAFE),
                  labelStyle: TextStyle(
                    color: selected == index
                        ? _StudentWorkbookViewScreenState._blue
                        : _StudentWorkbookViewScreenState._ink,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: selected == index
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFFE5EAF3),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckLearningSetInput extends StatelessWidget {
  const _CheckLearningSetInput({
    required this.question,
    required this.selectedChoices,
    required this.onChoiceChanged,
  });

  final WorkbookQuestion question;
  final Map<int, int> selectedChoices;
  final void Function(int key, int value) onChoiceChanged;

  @override
  Widget build(BuildContext context) {
    final sectionB = _asMap(question.content['section_b']);
    final hasAny = _asString(sectionB['passage_text']).isNotEmpty ||
        _stringList(sectionB['word_bank']).isNotEmpty ||
        _asInt(sectionB['blank_count']) > 0;
    if (!hasAny) {
      return const Text(
        '표시할 확인학습 문제가 없습니다.',
        style: TextStyle(color: _StudentWorkbookViewScreenState._muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CheckLearningSectionCard(
          label: '확인학습',
          title: '빈칸 완성',
          instruction: _asString(sectionB['instruction']).isEmpty
              ? '보기에서 알맞은 표현을 골라 빈칸을 완성하세요.'
              : _asString(sectionB['instruction']),
          child: _CheckLearningBlankInput(
            questionId: question.id,
            section: sectionB,
            selectedChoices: selectedChoices,
            onChanged: onChoiceChanged,
          ),
        ),
      ],
    );
  }
}

class _CheckLearningSectionCard extends StatelessWidget {
  const _CheckLearningSectionCard({
    required this.label,
    required this.title,
    required this.instruction,
    required this.child,
  });

  final String label;
  final String title;
  final String instruction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _StudentWorkbookViewScreenState._blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _StudentWorkbookViewScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (instruction.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              instruction,
              style: const TextStyle(
                color: _StudentWorkbookViewScreenState._muted,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _CheckLearningBlankInput extends StatelessWidget {
  const _CheckLearningBlankInput({
    required this.questionId,
    required this.section,
    required this.selectedChoices,
    required this.onChanged,
  });

  final int questionId;
  final Map<String, dynamic> section;
  final Map<int, int> selectedChoices;
  final void Function(int key, int value) onChanged;

  @override
  Widget build(BuildContext context) {
    final wordBank = _stringList(section['word_bank']);
    final passage = _asString(section['passage_text']);
    final blankCount = _asInt(section['blank_count']);
    if (passage.isEmpty && wordBank.isEmpty && blankCount == 0) {
      return const Text(
        '등록된 B 문항이 없습니다.',
        style: TextStyle(color: _StudentWorkbookViewScreenState._muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wordBank.isNotEmpty) ...[
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final word in wordBank)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    word,
                    style: const TextStyle(
                      color: _StudentWorkbookViewScreenState._blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (passage.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE5EAF3)),
            ),
            child: Text(
              passage,
              style: const TextStyle(
                color: _StudentWorkbookViewScreenState._ink,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (blankCount > 0) ...[
          const SizedBox(height: 10),
          for (var index = 1; index <= blankCount; index++) ...[
            _BlankChoiceRow(
              questionId: questionId,
              number: index,
              wordBank: wordBank,
              selected: selectedChoices[_localKey(questionId, index)],
              onChanged: onChanged,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _BlankChoiceRow extends StatelessWidget {
  const _BlankChoiceRow({
    required this.questionId,
    required this.number,
    required this.wordBank,
    required this.selected,
    required this.onChanged,
  });

  final int questionId;
  final int number;
  final List<String> wordBank;
  final int? selected;
  final void Function(int key, int value) onChanged;

  @override
  Widget build(BuildContext context) {
    if (wordBank.isEmpty) {
      return Text(
        '$number번 빈칸: 선택지가 없습니다.',
        style: const TextStyle(color: _StudentWorkbookViewScreenState._muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number번 빈칸',
          style: const TextStyle(
            color: _StudentWorkbookViewScreenState._ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (var index = 0; index < wordBank.length; index++)
              ChoiceChip(
                selected: selected == index,
                label: Text(wordBank[index]),
                onSelected: (_) =>
                    onChanged(_localKey(questionId, number), index),
                selectedColor: const Color(0xFFDBEAFE),
                labelStyle: TextStyle(
                  color: selected == index
                      ? _StudentWorkbookViewScreenState._blue
                      : _StudentWorkbookViewScreenState._ink,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: selected == index
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFFE5EAF3),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InitialBlankInput extends StatelessWidget {
  const _InitialBlankInput({
    required this.question,
    required this.controllers,
  });

  final WorkbookQuestion question;
  final Map<int, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final items = _contentItems(question.content);
    if (items.isEmpty) {
      return const Text(
        '표시할 첫 글자 빈칸이 없습니다.',
        style: TextStyle(color: _StudentWorkbookViewScreenState._muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _InitialBlankRow(
            itemNumber: index + 1,
            item: items[index],
            controller: controllers.putIfAbsent(
              _localKey(question.id, index + 1),
              () => TextEditingController(),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _InitialBlankRow extends StatelessWidget {
  const _InitialBlankRow({
    required this.itemNumber,
    required this.item,
    required this.controller,
  });

  final int itemNumber;
  final Map<String, dynamic> item;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final label = _asString(item['label']);
    final initial = _asString(item['initial']);
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: _StudentWorkbookViewScreenState._ink,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: '(${label.isEmpty ? itemNumber : label}) ${initial}________',
        hintText: '정답 단어 입력',
        labelStyle: const TextStyle(
          color: _StudentWorkbookViewScreenState._blue,
          fontWeight: FontWeight.w900,
        ),
        floatingLabelStyle: const TextStyle(
          color: _StudentWorkbookViewScreenState._blue,
          fontWeight: FontWeight.w900,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF93C5FD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _StudentWorkbookViewScreenState._blue,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _SentenceInsertionInput extends StatelessWidget {
  const _SentenceInsertionInput({
    required this.question,
    required this.selected,
    required this.onChanged,
  });

  final WorkbookQuestion question;
  final int? selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final insertSentence = _asString(question.content['insert_sentence']);
    final passage = renderInlineChoicePassageForStudent(
      (question.passageText ?? '').isNotEmpty
          ? question.passageText!
          : _asString(question.content['passage_text']),
    );
    final positions = _stringList(question.content['positions']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insertSentence.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              insertSentence,
              style: const TextStyle(
                color: _StudentWorkbookViewScreenState._ink,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (passage.isNotEmpty) ...[
          const _QuestionSectionLabel(
            icon: Icons.article_outlined,
            label: '본문',
          ),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5EAF3)),
            ),
            child: Text(
              passage,
              style: const TextStyle(
                color: _StudentWorkbookViewScreenState._ink,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < positions.length; index++)
              ChoiceChip(
                selected: selected == index,
                label: Text(positions[index]),
                onSelected: (_) => onChanged(index),
                selectedColor: const Color(0xFFDBEAFE),
              ),
          ],
        ),
      ],
    );
  }
}

class _ParagraphOrderInput extends StatelessWidget {
  const _ParagraphOrderInput({
    required this.question,
    required this.selectedOrder,
    required this.onChanged,
  });

  final WorkbookQuestion question;
  final List<String> selectedOrder;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final segments = _contentItems({'items': question.content['segments']});
    final labels = segments
        .map((item) => _asString(item['label']).toUpperCase())
        .where((label) => label.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in segments) ...[
          Text(
            '(${_asString(item['label'])}) ${_asString(item['text'])}',
            style: const TextStyle(
              color: _StudentWorkbookViewScreenState._ink,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in labels)
              ChoiceChip(
                selected: selectedOrder.contains(label),
                label: Text(label),
                onSelected: (_) {
                  final next = [...selectedOrder];
                  if (next.contains(label)) {
                    next.remove(label);
                  } else {
                    next.add(label);
                  }
                  onChanged(next);
                },
                selectedColor: const Color(0xFFDBEAFE),
              ),
            OutlinedButton.icon(
              onPressed: () => onChanged(const []),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('초기화'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          selectedOrder.isEmpty
              ? '선택한 순서가 없습니다.'
              : '선택 순서: ${selectedOrder.join(' → ')}',
          style: const TextStyle(
            color: _StudentWorkbookViewScreenState._blue,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _WorkbookQuestionSectionHeader extends StatelessWidget {
  const _WorkbookQuestionSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.fact_check_outlined,
            color: _StudentWorkbookViewScreenState._blue,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '문제 영역',
                style: TextStyle(
                  color: _StudentWorkbookViewScreenState._ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '유형별 문제를 풀고 마지막에 학습 완료를 눌러 주세요.',
                style: TextStyle(
                  color: _StudentWorkbookViewScreenState._muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionSectionLabel extends StatelessWidget {
  const _QuestionSectionLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _StudentWorkbookViewScreenState._blue),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: _StudentWorkbookViewScreenState._blue,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.text});

  final String text;

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
        text,
        style: const TextStyle(
          color: _StudentWorkbookViewScreenState._blue,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TrueFalseInput extends StatelessWidget {
  const _TrueFalseInput({
    required this.selected,
    required this.onChanged,
  });

  final bool? selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('O / 맞음')),
        ButtonSegment(value: false, label: Text('X / 틀림')),
      ],
      selected: selected == null ? const <bool>{} : {selected!},
      emptySelectionAllowed: true,
      onSelectionChanged: (values) {
        if (values.isEmpty) return;
        onChanged(values.first);
      },
    );
  }
}

class _TrueFalseSetInput extends StatelessWidget {
  const _TrueFalseSetInput({
    required this.question,
    required this.selected,
    required this.onChanged,
  });

  final WorkbookQuestion question;
  final Map<int, bool> selected;
  final void Function(int key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final items = _contentItems(question.content);
    if (items.isEmpty) {
      return const Text(
        '표시할 T/F 문항이 없습니다.',
        style: TextStyle(color: _StudentWorkbookViewScreenState._muted),
      );
    }
    return Column(
      children: [
        for (final item in items) ...[
          _TrueFalseSetItemRow(
            questionId: question.id,
            item: item,
            selected: selected[_localKey(question.id, _asInt(item['number']))],
            onChanged: onChanged,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TrueFalseSetItemRow extends StatelessWidget {
  const _TrueFalseSetItemRow({
    required this.questionId,
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  final int questionId;
  final Map<String, dynamic> item;
  final bool? selected;
  final void Function(int key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final number = _asInt(item['number']);
    final statement = _asString(item['statement']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $statement',
            style: const TextStyle(
              color: _StudentWorkbookViewScreenState._ink,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('T')),
              ButtonSegment(value: false, label: Text('F')),
            ],
            selected: selected == null ? const <bool>{} : {selected!},
            emptySelectionAllowed: true,
            onSelectionChanged: (values) {
              if (values.isEmpty) return;
              onChanged(_localKey(questionId, number), values.first);
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyQuestionCard extends StatelessWidget {
  const _EmptyQuestionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _StudentWorkbookViewScreenState._line),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            color: _StudentWorkbookViewScreenState._blue,
            size: 38,
          ),
          SizedBox(height: 10),
          Text(
            '아직 등록된 문제가 없습니다.',
            style: TextStyle(
              color: _StudentWorkbookViewScreenState._ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '선생님이 문제를 추가하면 이곳에서 학습할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _StudentWorkbookViewScreenState._muted),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _StudentWorkbookViewScreenState._muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              color: _StudentWorkbookViewScreenState._blue,
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _StudentWorkbookViewScreenState._ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _StudentWorkbookViewScreenState._muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'completed' => '완료',
    'in_progress' => '진행 중',
    'overdue' => '마감 지남',
    _ => '미시작',
  };
}

String _dateText(String value) {
  if (value.length < 10) return value;
  return value.substring(0, 10);
}

String _dateOrDash(String? value) {
  if (value == null || value.trim().isEmpty) return '-';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value.length >= 16 ? value.substring(0, 16) : value;
  }
  final local = parsed.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _formatScore(double value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}

String _emptyDash(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? '미응답' : text;
}

String _questionTypeLabel(String type) {
  return switch (type) {
    'inline_choice' => '본문 선택형',
    'true_false' => 'T/F',
    'multiple_choice' => '선택형',
    'check_learning_set' => '확인학습',
    'initial_blank' => '첫 글자 빈칸',
    'sentence_insertion' => '문장 삽입',
    'paragraph_order' => '문단 배열',
    'check_learning_set:A' => '확인학습',
    'check_learning_set:B' => '확인학습',
    'check_learning_set:C' => '확인학습',
    _ => type,
  };
}

List<Map<String, dynamic>> _contentItems(Map<String, dynamic> content) {
  final raw = content['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

int _localKey(int questionId, int number) => questionId * 1000 + number;

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value) {
  if (value == null) return '';
  final text = value.toString();
  return text == 'null' ? '' : text;
}

String renderInlineChoicePassageForStudent(String passageText) {
  return passageText.replaceAllMapped(
    RegExp(r'\[\[(\d+):[^\]]+\]\]'),
    (match) => '(${match.group(1)}) ______',
  );
}
