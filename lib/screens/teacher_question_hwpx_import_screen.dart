import 'package:flutter/material.dart';

import '../models/problem_set_import_draft.dart';
import '../models/question_import_draft.dart';
import '../services/final_touch_import_file_picker.dart';
import '../services/question_import_service.dart';
import '../utils/question_hwpx_import_parser.dart';
import '../utils/workbook_hwpx_text_extractor.dart';
import 'teacher/teacher_problem_set_preview_screen.dart';

class TeacherQuestionHwpxImportScreen extends StatefulWidget {
  const TeacherQuestionHwpxImportScreen({super.key});

  @override
  State<TeacherQuestionHwpxImportScreen> createState() =>
      _TeacherQuestionHwpxImportScreenState();
}

class _TeacherQuestionHwpxImportScreenState
    extends State<TeacherQuestionHwpxImportScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF172033);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);

  final _service = const QuestionImportService();
  final _setNameController = TextEditingController();
  final _textbookController = TextEditingController();
  final _unitController = TextEditingController();
  final Set<int> _selected = {};

  ProblemSetImportDraft? _draft;
  String? _fileName;
  String? _error;
  bool _reading = false;
  bool _saving = false;

  @override
  void dispose() {
    _setNameController.dispose();
    _textbookController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _reading = true;
      _error = null;
    });
    try {
      final file = await pickFinalTouchImportFile();
      if (file == null) return;
      final lower = file.name.toLowerCase();
      if (lower.endsWith('.hwp') && !lower.endsWith('.hwpx')) {
        throw const FormatException('구형 HWP 파일은 HWPX로 다시 저장한 뒤 가져와 주세요.');
      }
      if (!lower.endsWith('.hwpx')) {
        throw const FormatException('HWPX 파일만 선택할 수 있습니다.');
      }
      final extracted = extractWorkbookTextFromHwpx(file.bytes);
      final parsed = parseQuestionHwpxImportText(
        extracted.text,
        textbookFolderName: _textbookController.text.trim(),
        unitFolderName: _unitController.text.trim(),
      );
      _debugParsedQuestions(parsed.questions);
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _draft = parsed;
        _setNameController.text = parsed.name;
        if (_unitController.text.trim().isEmpty && parsed.source.isNotEmpty) {
          _unitController.text = parsed.source;
        }
        _selected
          ..clear()
          ..addAll([
            for (var index = 0; index < parsed.questions.length; index++)
              if (parsed.questions[index].isSaveable) index,
          ]);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _draft = null;
        _selected.clear();
        _error = error is FormatException ? error.message : '$error';
      });
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  void _selectSaveable() {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _selected
        ..clear()
        ..addAll([
          for (var index = 0; index < draft.questions.length; index++)
            if (draft.questions[index].isSaveable) index,
        ]);
    });
  }

  void _clearSelection() => setState(_selected.clear);

  void _debugParsedQuestions(List<QuestionImportDraft> questions) {
    debugPrint('[QuestionImportDraft] count=${questions.length}');
    for (final question in questions) {
      debugPrint(
        '[QuestionImportDraft] no=${question.questionNo} '
        'type=${question.questionType} '
        'question="${_preview(question.questionText)}" '
        'passage="${_preview(question.passage)}" '
        'choices=${question.choices.length} '
        'answer=${question.answerIndex}',
      );
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || _saving) return;
    final questions = [
      for (var index = 0; index < draft.questions.length; index++)
        if (_selected.contains(index) && draft.questions[index].isSaveable)
          draft.questions[index],
    ];
    if (questions.isEmpty) {
      _toast('저장 가능한 선택 문제가 없습니다.');
      return;
    }
    setState(() => _saving = true);
    try {
      final effectiveDraft = draft.copyWith(
        name: _setNameController.text.trim().isEmpty
            ? draft.name
            : _setNameController.text.trim(),
        textbookFolderName: _textbookController.text.trim(),
        unitFolderName: _unitController.text.trim(),
      );
      final result = await _service.saveSingleChoiceProblemSet(
        draft: effectiveDraft,
        questions: questions,
      );
      if (!mounted) return;
      final openPreview = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('문제세트 저장 완료'),
          content: Text(
            '${result.savedQuestionCount}개 문항을 저장했습니다.\n'
            '문제세트 관리에서 확인할 수 있습니다.'
            '${result.warnings.isEmpty ? '' : '\n\n경고:\n${result.warnings.join('\n')}'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('미리보기 열기'),
            ),
          ],
        ),
      );
      if (openPreview == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherProblemSetPreviewScreen(
              problemSetId: result.problemSetId,
            ),
          ),
        );
      }
    } catch (error) {
      _toast('저장 실패: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editQuestion(int index) async {
    final draft = _draft;
    if (draft == null) return;
    final edited = await showDialog<QuestionImportDraft>(
      context: context,
      builder: (context) => _QuestionImportEditDialog(
        question: draft.questions[index],
      ),
    );
    if (edited == null || !mounted) return;
    final next = [...draft.questions]..[index] = edited;
    setState(() {
      _draft = draft.copyWith(questions: next);
      if (!edited.isSaveable) _selected.remove(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final saveableCount =
        draft?.questions.where((question) => question.isSaveable).length ?? 0;
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text('HWPX 문제 가져오기'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: _SectionTitle(
                              title: 'HWPX 단일정답 문제 Import',
                              subtitle: '단일정답 객관식만 저장합니다. 복수정답/특수형은 경고로 제외됩니다.',
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _reading ? null : _pickFile,
                            icon: _reading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file_rounded),
                            label: Text(_reading ? '읽는 중...' : 'HWPX 선택'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 300,
                            child: TextField(
                              controller: _setNameController,
                              decoration: const InputDecoration(
                                labelText: '문제세트명',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 240,
                            child: TextField(
                              controller: _textbookController,
                              decoration: const InputDecoration(
                                labelText: '교재 폴더명',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 240,
                            child: TextField(
                              controller: _unitController,
                              decoration: const InputDecoration(
                                labelText: '단원/강 폴더명',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_fileName != null) ...[
                        const SizedBox(height: 10),
                        Text('선택 파일: $_fileName'),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (draft != null)
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SectionTitle(
                                title: '파싱 미리보기',
                                subtitle:
                                    '후보 ${draft.questions.length}개 · 저장 가능 $saveableCount개 · 선택 ${_selected.length}개',
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _selectSaveable,
                              child: const Text('저장 가능만 선택'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _clearSelection,
                              child: const Text('전체 해제'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (var index = 0;
                            index < draft.questions.length;
                            index++) ...[
                          _QuestionPreviewCard(
                            question: draft.questions[index],
                            selected: _selected.contains(index),
                            onSelected: draft.questions[index].isSaveable
                                ? (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selected.add(index);
                                      } else {
                                        _selected.remove(index);
                                      }
                                    });
                                  }
                                : null,
                            onEdit: () => _editQuestion(index),
                          ),
                          if (index != draft.questions.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: draft == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _line)),
                ),
                child: FilledButton.icon(
                  onPressed: _selected.isEmpty || _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_alt_rounded),
                  label: Text(
                      _saving ? '저장 중...' : '선택한 ${_selected.length}개 문제 저장'),
                ),
              ),
            ),
    );
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  const _QuestionPreviewCard({
    required this.question,
    required this.selected,
    required this.onSelected,
    required this.onEdit,
  });

  final QuestionImportDraft question;
  final bool selected;
  final ValueChanged<bool?>? onSelected;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final answer =
        question.answerIndex == null ? '-' : '①②③④⑤⑥⑦⑧⑨'[question.answerIndex!];
    final typeLabel = _questionImportTypeLabel(question.questionType);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: question.isSaveable ? Colors.white : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: question.isSaveable
              ? _TeacherQuestionHwpxImportScreenState._line
              : const Color(0xFFF59E0B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(value: selected, onChanged: onSelected),
              Expanded(
                child: Text(
                  '${question.questionNo}번 · ${typeLabel.isEmpty ? '유형 미확정' : typeLabel}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusChip(
                label: question.isSaveable ? '저장 가능' : '저장 제외',
                color: question.isSaveable
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('수정'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(question.questionText,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: '선택지', value: '${question.choices.length}개'),
              _InfoPill(label: '정답', value: answer),
              _InfoPill(label: '경고', value: '${question.warnings.length}개'),
            ],
          ),
          if (question.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              question.warnings.join('\n'),
              style: const TextStyle(color: Color(0xFFB45309), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

String _questionImportTypeLabel(String type) {
  switch (type.trim().toLowerCase()) {
    case 'blank':
    case 'cloze':
      return '빈칸';
    case 'topic':
      return '주제';
    case 'title':
      return '제목';
    case 'gist':
      return '요지';
    case 'implication':
      return '함의 추론';
    case 'purpose':
      return '목적';
    case 'mismatch':
      return '내용 불일치';
    case 'content':
      return '내용 일치';
    case 'insertion':
      return '문장 삽입';
    case 'order':
      return '순서 배열';
  }
  return type.trim();
}

String _preview(String text) {
  final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= 80) return compact;
  return '${compact.substring(0, 80)}...';
}

class _QuestionImportEditDialog extends StatefulWidget {
  const _QuestionImportEditDialog({required this.question});

  final QuestionImportDraft question;

  @override
  State<_QuestionImportEditDialog> createState() =>
      _QuestionImportEditDialogState();
}

class _QuestionImportEditDialogState extends State<_QuestionImportEditDialog> {
  late final TextEditingController _source;
  late final TextEditingController _type;
  late final TextEditingController _passage;
  late final TextEditingController _text;
  late final TextEditingController _choices;
  late final TextEditingController _answer;
  late final TextEditingController _explanation;

  @override
  void initState() {
    super.initState();
    _source = TextEditingController(text: widget.question.source);
    _type = TextEditingController(text: widget.question.questionType);
    _passage = TextEditingController(text: widget.question.passage);
    _text = TextEditingController(text: widget.question.questionText);
    _choices = TextEditingController(text: widget.question.choices.join('\n'));
    _answer = TextEditingController(
      text: widget.question.answerIndex == null
          ? ''
          : '${widget.question.answerIndex! + 1}',
    );
    _explanation = TextEditingController(text: widget.question.explanation);
  }

  @override
  void dispose() {
    _source.dispose();
    _type.dispose();
    _passage.dispose();
    _text.dispose();
    _choices.dispose();
    _answer.dispose();
    _explanation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.question.questionNo}번 저장 전 수정'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EditField(label: '출처', controller: _source),
              _EditField(label: '문제 유형', controller: _type),
              _EditField(label: '지문', controller: _passage, maxLines: 5),
              _EditField(label: '문항', controller: _text, maxLines: 3),
              _EditField(
                label: '선택지(줄바꿈으로 구분)',
                controller: _choices,
                maxLines: 6,
              ),
              _EditField(label: '정답 번호(1~9)', controller: _answer),
              _EditField(label: '해설', controller: _explanation, maxLines: 5),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final choices = _choices.text
                .split(RegExp(r'\r?\n'))
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .toList();
            final answerNumber = int.tryParse(_answer.text.trim());
            final answerIndex = answerNumber == null ? null : answerNumber - 1;
            final warnings = <String>[
              if (_type.text.trim().isEmpty) '문제 유형을 입력해 주세요.',
              if (_text.text.trim().isEmpty) '문항을 입력해 주세요.',
              if (choices.length < 2) '선택지가 부족합니다.',
              if (answerIndex == null) '정답 번호를 입력해 주세요.',
              if (answerIndex != null &&
                  (answerIndex < 0 || answerIndex >= choices.length))
                '정답이 선택지 범위를 벗어났습니다.',
            ];
            Navigator.pop(
              context,
              widget.question.copyWith(
                source: _source.text.trim(),
                questionType: _type.text.trim(),
                passage: _passage.text.trim(),
                questionText: _text.text.trim(),
                choices: choices,
                answerIndex: answerIndex,
                clearAnswerIndex: answerIndex == null,
                answerRaw: _answer.text.trim(),
                explanation: _explanation.text.trim(),
                warnings: warnings,
                isSpecialUnsupported: false,
              ),
            );
          },
          child: const Text('반영'),
        ),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _TeacherQuestionHwpxImportScreenState._line),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              color: _TeacherQuestionHwpxImportScreenState._ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            )),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            )),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          )),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label $value',
          style: const TextStyle(
            color: _TeacherQuestionHwpxImportScreenState._blue,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          )),
    );
  }
}
