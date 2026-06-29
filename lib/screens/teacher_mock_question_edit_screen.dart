import 'package:flutter/material.dart';

import '../services/teacher_mock_exam_service.dart';

class TeacherMockQuestionEditScreen extends StatefulWidget {
  const TeacherMockQuestionEditScreen({
    super.key,
    required this.mockExamId,
    required this.question,
  });

  final int mockExamId;
  final Map<String, dynamic> question;

  @override
  State<TeacherMockQuestionEditScreen> createState() =>
      _TeacherMockQuestionEditScreenState();
}

class _TeacherMockQuestionEditScreenState
    extends State<TeacherMockQuestionEditScreen> {
  static const _ink = Color(0xFF172033);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sourceController;
  late final TextEditingController _passageController;
  late final TextEditingController _questionController;
  late final List<TextEditingController> _optionControllers;
  late final TextEditingController _explanationController;
  late final TextEditingController _passageGroupController;
  late int _answer;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final options = widget.question['options'] as List? ?? const [];
    _sourceController = TextEditingController(
      text: _asText(widget.question['source']),
    );
    _passageController = TextEditingController(
      text: _asText(widget.question['passage']),
    );
    _questionController = TextEditingController(
      text: _asText(widget.question['question_text']),
    );
    _optionControllers = List.generate(5, (index) {
      return TextEditingController(
        text: index < options.length ? _asText(options[index]) : '',
      );
    });
    _explanationController = TextEditingController(
      text: _asText(widget.question['explanation']),
    );
    _passageGroupController = TextEditingController(
      text: _asText(widget.question['passage_group_id']),
    );
    _answer = _asInt(widget.question['answer_index']) + 1;
    if (_answer < 1 || _answer > 5) _answer = 1;
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _passageController.dispose();
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    _explanationController.dispose();
    _passageGroupController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await TeacherMockExamService.updateQuestion(
        mockExamId: widget.mockExamId,
        questionId: _asInt(widget.question['id']),
        payload: {
          'source': _sourceController.text.trim(),
          'passage': _passageController.text.trim(),
          'question_text': _questionController.text.trim(),
          'options': _optionControllers
              .map((controller) => controller.text.trim())
              .toList(),
          'answer': _answer,
          'explanation': _explanationController.text.trim(),
          'passage_group_id': _passageGroupController.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문항이 저장되었습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문항 삭제'),
        content: const Text('이 문항을 삭제할까요? 삭제 후 다시 업로드하거나 수정 API로 복구해야 합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      await TeacherMockExamService.deleteQuestion(
        mockExamId: widget.mockExamId,
        questionId: _asInt(widget.question['id']),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문항이 삭제되었습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = _asInt(widget.question['number']);
    final typeLabel = _asText(
      widget.question['type_label'],
      _asText(widget.question['question_type']),
    );

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          '$number번 문항 수정',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saving || _deleting ? null : _delete,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            label: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _line)),
          ),
          child: FilledButton.icon(
            onPressed: _saving || _deleting ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? '저장 중' : '저장'),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: _cardDecoration(),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Badge(label: '$number번'),
                        _Badge(label: typeLabel),
                        _Badge(
                          label:
                              '유형 코드: ${_asText(widget.question['question_type'])}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        _TextField(
                          controller: _sourceController,
                          label: '출처',
                          hint: '예: 고2 2024년 9월 18번',
                        ),
                        _TextField(
                          controller: _passageController,
                          label: '지문',
                          minLines: 8,
                          hint: '<u>...</u>를 직접 입력하면 학생 화면에서 밑줄로 표시됩니다.',
                          required: false,
                        ),
                        _TextField(
                          controller: _questionController,
                          label: '질문',
                          minLines: 2,
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(5, (index) {
                          return _TextField(
                            controller: _optionControllers[index],
                            label: '선택지 ${index + 1}',
                            minLines: 1,
                          );
                        }),
                        DropdownButtonFormField<int>(
                          value: _answer,
                          decoration: const InputDecoration(
                            labelText: '정답',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(5, (index) {
                            final value = index + 1;
                            return DropdownMenuItem(
                              value: value,
                              child: Text('$value번'),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) setState(() => _answer = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        _TextField(
                          controller: _explanationController,
                          label: '해설',
                          minLines: 3,
                          required: false,
                        ),
                        _TextField(
                          controller: _passageGroupController,
                          label: 'passage_group',
                          hint: '필요한 경우 같은 지문 묶음 ID를 입력합니다.',
                          required: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 88),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.hint,
    this.minLines = 1,
    this.required = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int minLines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          alignLabelWithHint: minLines > 1,
        ),
        validator: required
            ? (value) {
                if ((value ?? '').trim().isEmpty) return '$label을 입력하세요.';
                return null;
              }
            : null,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

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
        label,
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _asText(dynamic value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
