import 'package:flutter/material.dart';

import '../models/workbook.dart';
import '../utils/workbook_question_parser.dart';

class WorkbookQuestionDraft {
  const WorkbookQuestionDraft({
    required this.questionType,
    required this.prompt,
    required this.answer,
    this.passageText,
    this.choices,
    this.explanation,
    this.points = 1,
    this.sectionId,
    this.newSectionTitle,
  });

  final String questionType;
  final String prompt;
  final String? passageText;
  final List<String>? choices;
  final Map<String, dynamic> answer;
  final String? explanation;
  final int points;
  final int? sectionId;
  final String? newSectionTitle;
}

class _StructuredManualParse {
  const _StructuredManualParse(this.answer, this.warnings, this.blockingError);

  final Map<String, dynamic> answer;
  final List<String> warnings;
  final String? blockingError;
}

class WorkbookQuestionEditorDialog extends StatefulWidget {
  const WorkbookQuestionEditorDialog({
    super.key,
    required this.questionType,
    this.initial,
    this.workbookSourceLabel,
    this.workbookFolderName,
    this.workbookUnitLabel,
    this.sections = const [],
    this.initialSectionId,
  });

  final String questionType;
  final WorkbookQuestion? initial;
  final String? workbookSourceLabel;
  final String? workbookFolderName;
  final String? workbookUnitLabel;
  final List<WorkbookSection> sections;
  final int? initialSectionId;

  String get workbookSourceText => _joinWorkbookMetadata([
        workbookSourceLabel,
        workbookFolderName,
        workbookUnitLabel,
      ]);

  @override
  State<WorkbookQuestionEditorDialog> createState() =>
      _WorkbookQuestionEditorDialogState();
}

class _WorkbookQuestionEditorDialogState
    extends State<WorkbookQuestionEditorDialog> {
  static const _primary = Color(0xFF183B56);
  static const _teal = Color(0xFF0F766E);
  static const _ink = Color(0xFF102A43);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);

  late final TextEditingController _sourceController;
  late final TextEditingController _promptController;
  late final TextEditingController _passageController;
  late final TextEditingController _explanationController;
  late final TextEditingController _rawInlineController;
  late final TextEditingController _answerTextController;
  late final TextEditingController _tfStatementsController;
  late final TextEditingController _tfAnswerExplanationController;
  late final TextEditingController _checkLearningAController;
  late final TextEditingController _checkLearningBController;
  late final TextEditingController _checkLearningCController;
  late final TextEditingController _insertSentenceController;
  late final TextEditingController _orderLeadController;
  late final TextEditingController _orderAController;
  late final TextEditingController _orderBController;
  late final TextEditingController _orderCController;
  late final TextEditingController _newSectionController;
  late final List<TextEditingController> _choiceControllers;

  InlineChoiceParseResult? _inlinePreview;
  TrueFalseRawParseResult? _tfPreview;
  CheckLearningRawParseResult? _checkLearningPreview;
  Map<String, dynamic>? _structuredPreview;
  List<String> _structuredWarnings = const [];
  String? _structuredError;
  int _answerIndex = 0;
  bool _tfAnswer = true;
  late int _selectedSectionValue;
  bool _useNewSection = false;

  bool get _isInlineChoice => widget.questionType == 'inline_choice';
  bool get _isNewTrueFalse =>
      widget.questionType == 'true_false_en' ||
      widget.questionType == 'true_false_ko';
  bool get _isCheckLearningSet => widget.questionType == 'check_learning_set';
  bool get _isInitialBlank => widget.questionType == 'initial_blank';
  bool get _isSentenceInsertion => widget.questionType == 'sentence_insertion';
  bool get _isParagraphOrder => widget.questionType == 'paragraph_order';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _selectedSectionValue =
        widget.initialSectionId ?? widget.initial?.sectionId ?? 0;
    _newSectionController = TextEditingController();
    if (_selectedSectionValue != 0 &&
        !widget.sections
            .any((section) => section.id == _selectedSectionValue)) {
      _selectedSectionValue = 0;
    }
    final answer = initial?.answer ?? const <String, dynamic>{};
    final savedSource = _asString(
      answer['source_label'] ?? answer['unit_title'],
    ).trim();
    _sourceController = TextEditingController(
      text: savedSource.isNotEmpty ? savedSource : widget.workbookSourceText,
    );
    _promptController = TextEditingController(text: initial?.prompt ?? '');
    _passageController = TextEditingController(
      text: _asString(answer['passage_text'] ?? initial?.passageText),
    );
    _explanationController = TextEditingController(
      text: _isInlineChoice
          ? _buildInitialInlineChoiceExplanations(answer)
          : _isCheckLearningSet
              ? _buildInitialCheckLearningExplanation(answer)
              : initial?.explanation ?? '',
    );
    _rawInlineController = TextEditingController(
      text: _asString(answer['raw_text']),
    );
    _answerTextController = TextEditingController(
      text: _buildInitialStructuredAnswer(widget.questionType, answer),
    );
    _tfStatementsController = TextEditingController(
      text: _buildInitialTrueFalseStatements(answer),
    );
    _tfAnswerExplanationController = TextEditingController(
      text: _buildInitialTrueFalseAnswerText(answer),
    );
    _checkLearningAController = TextEditingController(
      text: _buildInitialCheckLearningA(answer),
    );
    _checkLearningBController = TextEditingController(
      text: _buildInitialCheckLearningB(answer),
    );
    _checkLearningCController = TextEditingController(
      text: _buildInitialCheckLearningC(answer),
    );
    _insertSentenceController = TextEditingController(
      text: _asString(answer['insert_sentence']),
    );
    _orderLeadController = TextEditingController(
      text: _asString(answer['lead_text']),
    );
    _orderAController = TextEditingController(
      text: _buildInitialOrderSegment(answer, 'A'),
    );
    _orderBController = TextEditingController(
      text: _buildInitialOrderSegment(answer, 'B'),
    );
    _orderCController = TextEditingController(
      text: _buildInitialOrderSegment(answer, 'C'),
    );

    final choices = initial?.choices ?? const <String>[];
    _choiceControllers = List.generate(
      5,
      (index) => TextEditingController(
        text: index < choices.length ? choices[index] : '',
      ),
    );
    _answerIndex = _asInt(answer['answer_index']).clamp(0, 4);
    _tfAnswer = answer['answer'] == false ? false : true;

    if (_isInlineChoice && _rawInlineController.text.trim().isNotEmpty) {
      _inlinePreview = parseInlineChoiceRawText(
        _rawInlineController.text,
        explanationText: _explanationController.text,
      );
    }
    if (_isNewTrueFalse && _tfStatementsController.text.trim().isNotEmpty) {
      _previewTrueFalse();
    }
    if (_isCheckLearningSet) {
      _previewCheckLearning();
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _promptController.dispose();
    _passageController.dispose();
    _explanationController.dispose();
    _rawInlineController.dispose();
    _answerTextController.dispose();
    _tfStatementsController.dispose();
    _tfAnswerExplanationController.dispose();
    _checkLearningAController.dispose();
    _checkLearningBController.dispose();
    _checkLearningCController.dispose();
    _insertSentenceController.dispose();
    _orderLeadController.dispose();
    _orderAController.dispose();
    _orderBController.dispose();
    _orderCController.dispose();
    _newSectionController.dispose();
    for (final controller in _choiceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _previewInlineChoice() {
    setState(() {
      _inlinePreview = parseInlineChoiceRawText(
        _rawInlineController.text,
        explanationText: _explanationController.text,
      );
    });
  }

  void _previewTrueFalse() {
    setState(() {
      _tfPreview = parseTrueFalseRawText(
        _tfStatementsController.text,
        widget.questionType,
        answerExplanationText: _tfAnswerExplanationController.text,
      );
    });
  }

  void _previewCheckLearning() {
    setState(() {
      _checkLearningPreview = parseCheckLearningWordBankBlank(
        unitTitle: _sourceController.text,
        wordBankText: _checkLearningAController.text,
        passageText: _checkLearningBController.text,
        answerText: _checkLearningCController.text,
      );
    });
  }

  void _previewStructuredManualQuestion() {
    final parsed = _buildStructuredManualAnswer();
    setState(() {
      _structuredPreview = parsed.answer;
      _structuredWarnings = parsed.warnings;
      _structuredError = parsed.blockingError;
    });
    if (parsed.blockingError != null) {
      _showError(parsed.blockingError!);
    }
  }

  void _submit() {
    if (_isInlineChoice) {
      _submitInlineChoice();
      return;
    }
    if (_isNewTrueFalse) {
      _submitTrueFalseSet();
      return;
    }
    if (_isCheckLearningSet) {
      _submitCheckLearningSet();
      return;
    }
    if (_isInitialBlank || _isSentenceInsertion || _isParagraphOrder) {
      _submitStructuredManualQuestion();
      return;
    }
    _submitLegacyQuestion();
  }

  void _submitInlineChoice() {
    final parsed = parseInlineChoiceRawText(
      _rawInlineController.text,
      explanationText: _explanationController.text,
    );
    setState(() => _inlinePreview = parsed);
    if (!parsed.hasItems) {
      _showError('본문 선택 항목을 1개 이상 입력해 주세요.');
      return;
    }
    if (parsed.hasErrors) {
      _showError('선택 항목을 확인해 주세요.');
      return;
    }
    final prompt = _promptController.text.trim().isEmpty
        ? '본문에서 알맞은 표현을 고르세요.'
        : _promptController.text.trim();
    Navigator.pop(
      context,
      WorkbookQuestionDraft(
        questionType: 'inline_choice',
        prompt: prompt,
        passageText: parsed.passageText,
        answer: parsed.toAnswerJson(unitTitle: _sourceController.text),
        sectionId: _draftSectionId,
        newSectionTitle: _draftNewSectionTitle,
      ),
    );
  }

  void _submitTrueFalseSet() {
    final parsed = parseTrueFalseRawText(
      _tfStatementsController.text,
      widget.questionType,
      answerExplanationText: _tfAnswerExplanationController.text,
    );
    setState(() => _tfPreview = parsed);
    if (!parsed.hasItems) {
      _showError('T/F 문항을 1개 이상 입력해 주세요.');
      return;
    }
    if (parsed.hasErrors) {
      _showError(parsed.errors.first);
      return;
    }
    final isEnglish = widget.questionType == 'true_false_en';
    final prompt = _promptController.text.trim().isEmpty
        ? (isEnglish
            ? '영어 진술문이 본문과 일치하면 T, 일치하지 않으면 F를 고르세요.'
            : '한글 진술문이 본문과 일치하면 T, 일치하지 않으면 F를 고르세요.')
        : _promptController.text.trim();
    Navigator.pop(
      context,
      WorkbookQuestionDraft(
        questionType: 'true_false',
        prompt: prompt,
        passageText: _emptyToNull(_passageController.text),
        answer: parsed.toAnswerJson(
          unitTitle: _sourceController.text,
          sourceLabel: _sourceController.text,
          passageText: _passageController.text,
        ),
        sectionId: _draftSectionId,
        newSectionTitle: _draftNewSectionTitle,
      ),
    );
  }

  void _submitCheckLearningSet() {
    final parsed = parseCheckLearningWordBankBlank(
      unitTitle: _sourceController.text,
      wordBankText: _checkLearningAController.text,
      passageText: _checkLearningBController.text,
      answerText: _checkLearningCController.text,
    );
    setState(() => _checkLearningPreview = parsed);
    if (!parsed.hasSections) {
      _showError('보기, 본문, 정답을 입력해 주세요.');
      return;
    }
    if (parsed.errors.isNotEmpty) {
      _showError(parsed.errors.first);
      return;
    }
    Navigator.pop(
      context,
      WorkbookQuestionDraft(
        questionType: 'check_learning_set',
        prompt: _promptController.text.trim().isEmpty
            ? '확인학습'
            : _promptController.text.trim(),
        passageText: _emptyToNull(
          parsed.sectionB['passage_text']?.toString() ?? '',
        ),
        answer: parsed.toAnswerJson(),
        sectionId: _draftSectionId,
        newSectionTitle: _draftNewSectionTitle,
      ),
    );
  }

  void _submitStructuredManualQuestion() {
    final parsed = _buildStructuredManualAnswer();
    setState(() {
      _structuredPreview = parsed.answer;
      _structuredWarnings = parsed.warnings;
      _structuredError = parsed.blockingError;
    });
    if (parsed.blockingError != null) {
      _showError(parsed.blockingError!);
      return;
    }
    final prompt = _promptController.text.trim().isEmpty
        ? _editorTitle(widget.questionType)
        : _promptController.text.trim();
    final answer = parsed.answer;
    String? passageText;
    if (_isInitialBlank) {
      passageText = _passageController.text.trim();
    } else if (_isSentenceInsertion) {
      passageText = _passageController.text.trim();
    } else {
      passageText = _orderLeadController.text.trim();
    }
    Navigator.pop(
      context,
      WorkbookQuestionDraft(
        questionType: widget.questionType,
        prompt: prompt,
        passageText: passageText,
        answer: answer,
        sectionId: _draftSectionId,
        newSectionTitle: _draftNewSectionTitle,
      ),
    );
  }

  _StructuredManualParse _buildStructuredManualAnswer() {
    final warnings = <String>[];
    if (_isInitialBlank) {
      final answer = buildInitialBlankAnswerJson(
        unitTitle: _sourceController.text,
        passageText: _passageController.text,
        answerText: _answerTextController.text,
      );
      final items = (answer['items'] as List?) ?? const [];
      if (_passageController.text.trim().isEmpty) {
        return _StructuredManualParse(answer, warnings, '본문을 입력해 주세요.');
      }
      if (items.isEmpty) {
        return _StructuredManualParse(
          answer,
          warnings,
          '(a) c________ 형태의 빈칸을 본문에 입력해 주세요.',
        );
      }
      if (items
          .any((item) => (item['answer'] ?? '').toString().trim().isEmpty)) {
        return _StructuredManualParse(answer, warnings, '정답을 모두 입력해 주세요.');
      }
      return _StructuredManualParse(answer, warnings, null);
    }
    if (_isSentenceInsertion) {
      final answer = buildSentenceInsertionAnswerJson(
        unitTitle: _sourceController.text,
        insertSentence: _insertSentenceController.text,
        passageText: _passageController.text,
        answerText: _answerTextController.text,
      );
      final positions = (answer['positions'] as List?) ?? const [];
      final normalizedAnswer = (answer['answer'] ?? '').toString().trim();
      if (_insertSentenceController.text.trim().isEmpty) {
        return _StructuredManualParse(answer, warnings, '삽입할 문장을 입력해 주세요.');
      }
      if (_passageController.text.trim().isEmpty) {
        return _StructuredManualParse(answer, warnings, '본문을 입력해 주세요.');
      }
      if (positions.isEmpty) warnings.add('위치 표시를 찾지 못했습니다.');
      if (normalizedAnswer.isEmpty) {
        return _StructuredManualParse(answer, warnings, '정답 위치를 입력해 주세요.');
      }
      if (positions.isNotEmpty && !positions.contains(normalizedAnswer)) {
        warnings.add('정답 위치가 위치 목록에 없습니다.');
      }
      return _StructuredManualParse(answer, warnings, null);
    }
    final answer = buildParagraphOrderAnswerJson(
      unitTitle: _sourceController.text,
      leadText: _orderLeadController.text,
      segmentA: _orderAController.text,
      segmentB: _orderBController.text,
      segmentC: _orderCController.text,
      answerText: _answerTextController.text,
    );
    final order = (answer['answer_order'] as List?)?.cast<String>() ?? const [];
    if (_orderLeadController.text.trim().isEmpty) {
      return _StructuredManualParse(answer, warnings, '제시문을 입력해 주세요.');
    }
    if (_orderAController.text.trim().isEmpty ||
        _orderBController.text.trim().isEmpty ||
        _orderCController.text.trim().isEmpty) {
      return _StructuredManualParse(answer, warnings, 'A/B/C 문단을 모두 입력해 주세요.');
    }
    if (order.length != 3 || order.toSet().length != 3) {
      return _StructuredManualParse(answer, warnings, '정답 순서를 A/B/C로 입력해 주세요.');
    }
    if (!(order.toSet().contains('A') &&
        order.toSet().contains('B') &&
        order.toSet().contains('C'))) {
      return _StructuredManualParse(
          answer, warnings, '정답 순서는 A, B, C를 모두 포함해야 합니다.');
    }
    return _StructuredManualParse(answer, warnings, null);
  }

  void _submitLegacyQuestion() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _showError('문제 지시문을 입력해 주세요.');
      return;
    }

    final questionType = widget.questionType;
    Map<String, dynamic> answer;
    List<String>? choices;

    if (questionType == 'multiple_choice') {
      choices = _choiceControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (choices.length < 2) {
        _showError('선택형은 보기 2개 이상이 필요합니다.');
        return;
      }
      if (_answerIndex >= choices.length) {
        _showError('정답 번호가 입력한 보기 범위를 벗어났습니다.');
        return;
      }
      answer = {'answer_index': _answerIndex};
    } else if (questionType == 'check_learning') {
      final answerText = _answerTextController.text.trim();
      if (answerText.isEmpty) {
        _showError('확인학습 모범답안을 입력해 주세요.');
        return;
      }
      answer = {'answer_text': answerText};
    } else {
      answer = {'answer': _tfAnswer};
    }

    Navigator.pop(
      context,
      WorkbookQuestionDraft(
        questionType: questionType,
        prompt: prompt,
        passageText: _emptyToNull(_passageController.text),
        choices: choices,
        answer: answer,
        explanation: _emptyToNull(_explanationController.text),
        sectionId: _draftSectionId,
        newSectionTitle: _draftNewSectionTitle,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.initial == null
        ? '${_editorTitle(widget.questionType)} 추가'
        : '${_editorTitle(widget.questionType)} 수정';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: const Color(0xFFF4F7FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: MediaQuery.sizeOf(context).height - 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _DialogHeader(title: title, subtitle: _editorSubtitle()),
            ),
            if (_structuredError != null &&
                (_isInitialBlank || _isSentenceInsertion || _isParagraphOrder))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _StructuredErrorBanner(message: _structuredError!),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionSelector(),
                    const SizedBox(height: 16),
                    if (_isInlineChoice)
                      _inlineChoiceEditor()
                    else if (_isNewTrueFalse)
                      _trueFalseSetEditor()
                    else if (_isCheckLearningSet)
                      _checkLearningSetEditor()
                    else if (_isInitialBlank)
                      _initialBlankEditor()
                    else if (_isSentenceInsertion)
                      _sentenceInsertionEditor()
                    else if (_isParagraphOrder)
                      _paragraphOrderEditor()
                    else
                      _legacyEditor(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('저장'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? get _draftSectionId => _useNewSection || _selectedSectionValue == 0
      ? null
      : _selectedSectionValue;

  String? get _draftNewSectionTitle {
    if (!_useNewSection) return null;
    final title = _newSectionController.text.trim();
    return title.isEmpty ? null : title;
  }

  Widget _sectionSelector() {
    final sourceText = widget.workbookSourceText.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sourceText.isNotEmpty) ...[
            const Text(
              '워크북 출처',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sourceText,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<int>(
            value: _selectedSectionValue,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '저장할 섹션',
              helperText: '선택하지 않으면 미분류에 저장됩니다.',
              prefixIcon: Icon(Icons.folder_outlined),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: 0,
                child: Text('미분류'),
              ),
              for (final section in widget.sections)
                DropdownMenuItem<int>(
                  value: section.id,
                  child: Text(
                    section.questionCount > 0
                        ? '${section.title} (${section.questionCount}문항)'
                        : section.title,
                  ),
                ),
            ],
            onChanged: widget.initial == null
                ? (value) {
                    if (value == null) return;
                    setState(() => _selectedSectionValue = value);
                  }
                : null,
          ),
          if (widget.initial == null) ...[
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('새 섹션 직접 입력'),
              subtitle: const Text('예: 3강, Unit 5, Test, 실전 복습'),
              value: _useNewSection,
              onChanged: (value) {
                setState(() => _useNewSection = value);
              },
            ),
            if (_useNewSection)
              TextField(
                controller: _newSectionController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '새 섹션명',
                  hintText: '예: 3강',
                  prefixIcon: Icon(Icons.create_new_folder_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _inlineChoiceEditor() {
    final preview = _inlinePreview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          controller: _sourceController,
          label: '출처 선택',
          hint: '예: 수특라이트 영어 4강 1-4번',
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _promptController,
          label: '문제 지시문 선택',
          hint: '비워두면 기본 지시문을 사용합니다.',
          minLines: 1,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _rawInlineController,
          label: '본문 선택형 붙여넣기',
          hint:
              '본문 안에 [[1:정답|오답]] 형태로 입력하세요.\n예: A laboratory is a(n) [[1:artificial|natural]] environment.',
          minLines: 10,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _explanationController,
          label: '해설 입력 선택',
          hint: '1. natural 자연적인\n2. concentration 집중\n3. destroyed 파괴된',
          helperText: '필요한 경우 번호별 해설을 입력해 주세요. 해설이 없어도 저장할 수 있습니다.',
          minLines: 4,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _previewInlineChoice,
          icon: const Icon(Icons.preview_rounded),
          label: const Text('미리보기/분석'),
        ),
        if (preview != null) ...[
          const SizedBox(height: 12),
          _InlineChoicePreview(result: preview),
        ],
      ],
    );
  }

  Widget _trueFalseSetEditor() {
    final isEnglish = widget.questionType == 'true_false_en';
    final preview = _tfPreview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoBox(
          icon: Icons.rule_rounded,
          title: isEnglish ? '영어 T/F 묶음 입력' : '한글 T/F 묶음 입력',
          message:
              '워크북 출처를 사용하고 지문, 문항, 정답·해설을 덩어리로 입력합니다. 학생에게는 정답과 해설을 보여주지 않습니다.',
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _sourceController,
          label: '출처',
          hint: '예: 고1 2026년 06월 18번',
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _passageController,
          label: '지문',
          hint: '학생에게 보여줄 영어 지문을 붙여넣으세요.',
          minLines: 6,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _tfStatementsController,
          label: isEnglish ? '영어 T/F 문항' : '한글 T/F 문항',
          hint: isEnglish
              ? '1. The center is collecting brand new books.\n2. Donating books can help young individuals...'
              : '1. 센터는 독서 프로그램을 지원하기 위해 책을 모으고 있다.\n2. 기부된 책은 청소년들이 독서의 즐거움을 발견하도록 도울 수 있다.',
          minLines: 6,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _tfAnswerExplanationController,
          label: '정답 및 해설',
          hint: '정답: F F T F T\n\n해설:\n1. 새 책이 아니라 중고 도서를 수집합니다.\n2. ...',
          minLines: 7,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _previewTrueFalse,
          icon: const Icon(Icons.preview_rounded),
          label: const Text('미리보기/분석'),
        ),
        if (preview != null) ...[
          const SizedBox(height: 12),
          _TrueFalsePreview(result: preview),
        ],
      ],
    );
  }

  Widget _checkLearningSetEditor() {
    final preview = _checkLearningPreview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoBox(
          icon: Icons.fact_check_rounded,
          title: '확인학습 추가',
          message: '보기와 빈칸 본문, 정답을 입력하면 학생 화면에서는 정답을 숨기고, 제출 후 자동 채점에 사용합니다.',
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _sourceController,
          label: '출처/단원명',
          hint: '예: Unit 1 Gateway',
          minLines: 1,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _promptController,
          label: '문제 제목 선택',
          hint: '비워두면 확인학습으로 저장됩니다.',
          minLines: 1,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _checkLearningAController,
          label: '보기 입력',
          hint:
              'separation / historical / collection / industry / available / thankful',
          minLines: 3,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _checkLearningBController,
          label: '본문 입력',
          hint:
              'The ________ of pictures, tools, and ________ documents made the gold miners come to life.',
          minLines: 10,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _checkLearningCController,
          label: '정답 및 해설 입력',
          hint:
              '[정답] B chaotic intense security announcement browse (shallow 오답, 일상적인)\n\n또는\ncollection / historical / industry / available / thankful (separation 분리)',
          helperText: '정답을 순서대로 입력하고, 괄호 안에는 필요한 해설을 적어 주세요.',
          minLines: 4,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _previewCheckLearning,
          icon: const Icon(Icons.preview_rounded),
          label: const Text('미리보기/분석'),
        ),
        if (preview != null) ...[
          const SizedBox(height: 12),
          _CheckLearningPreview(result: preview),
        ],
      ],
    );
  }

  Widget _legacyEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          controller: _promptController,
          label: '문제 지시문',
          hint: '학생에게 보여줄 질문 또는 지시문을 입력하세요.',
          minLines: 2,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _passageController,
          label: '본문 또는 참고 지문 선택',
          hint: '필요한 경우 문제와 함께 보여줄 지문을 입력하세요.',
          minLines: 2,
        ),
        const SizedBox(height: 12),
        if (widget.questionType == 'multiple_choice') ...[
          const Text(
            '보기',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _choiceControllers.length; i++) ...[
            TextField(
              controller: _choiceControllers[i],
              decoration: _decoration('보기 ${i + 1}'),
            ),
            const SizedBox(height: 8),
          ],
          DropdownButtonFormField<int>(
            value: _answerIndex,
            decoration: _decoration('정답'),
            items: List.generate(
              5,
              (index) => DropdownMenuItem(
                value: index,
                child: Text('${index + 1}번'),
              ),
            ),
            onChanged: (value) => setState(() => _answerIndex = value ?? 0),
          ),
        ] else if (widget.questionType == 'check_learning') ...[
          _Field(
            controller: _answerTextController,
            label: '모범답안',
            hint: '확인학습의 모범답안을 입력하세요.',
            minLines: 2,
          ),
          const SizedBox(height: 8),
          const Text(
            'TODO: 한글파일에서 추출한 보기/본문/정답 텍스트를 확인학습으로 변환하는 흐름을 연결합니다.',
            style: TextStyle(color: _muted, height: 1.35),
          ),
        ] else ...[
          const Text(
            '정답',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('O / 맞음')),
              ButtonSegment(value: false, label: Text('X / 틀림')),
            ],
            selected: {_tfAnswer},
            onSelectionChanged: (values) =>
                setState(() => _tfAnswer = values.first),
          ),
        ],
        const SizedBox(height: 12),
        _Field(
          controller: _explanationController,
          label: '해설 선택',
          hint: '정답 근거 또는 참고 설명을 입력하세요.',
          minLines: 2,
        ),
      ],
    );
  }

  Widget _initialBlankEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoBox(
          icon: Icons.short_text_rounded,
          title: '첫 글자 제공 빈칸',
          message: '본문의 (a) c________ 같은 빈칸과 정답을 직접 입력합니다.',
        ),
        const SizedBox(height: 12),
        _Field(
            controller: _sourceController,
            label: '출처/단원명',
            hint: 'Unit 2 Gateway'),
        const SizedBox(height: 12),
        _Field(
            controller: _promptController, label: '문제 제목', hint: '첫 글자 빈칸 1번'),
        const SizedBox(height: 12),
        _Field(
          controller: _passageController,
          label: '본문 입력',
          hint: 'The whole morning had been (a) c________.',
          minLines: 9,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _answerTextController,
          label: '정답 입력',
          hint: '[정답] (a) chaotic (b) endless (c) Worried',
          minLines: 3,
        ),
        const SizedBox(height: 10),
        _StructuredPreviewButton(onPressed: _previewStructuredManualQuestion),
        if (_structuredPreview != null && _isInitialBlank) ...[
          const SizedBox(height: 12),
          _StructuredManualPreview(
            type: widget.questionType,
            answer: _structuredPreview!,
            warnings: _structuredWarnings,
          ),
        ],
      ],
    );
  }

  Widget _sentenceInsertionEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoBox(
          icon: Icons.input_rounded,
          title: '문장 삽입',
          message: '삽입할 문장, 위치 표시가 포함된 본문, 정답 위치를 입력합니다.',
        ),
        const SizedBox(height: 12),
        _Field(
            controller: _sourceController,
            label: '출처/단원명',
            hint: 'Unit 1 Gateway'),
        const SizedBox(height: 12),
        _Field(controller: _promptController, label: '문제 제목', hint: '문장 삽입 1번'),
        const SizedBox(height: 12),
        _Field(
          controller: _insertSentenceController,
          label: '삽입할 문장',
          hint: 'This reminded me of when I lived in Qukkon...',
          minLines: 2,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _passageController,
          label: '본문 입력',
          hint: '...\\n① The collection ...\\n② Because of this ...',
          minLines: 9,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: _answerTextController,
          label: '정답 입력',
          hint: '[정답] ② 또는 2',
        ),
        const SizedBox(height: 10),
        _StructuredPreviewButton(onPressed: _previewStructuredManualQuestion),
        if (_structuredPreview != null && _isSentenceInsertion) ...[
          const SizedBox(height: 12),
          _StructuredManualPreview(
            type: widget.questionType,
            answer: _structuredPreview!,
            warnings: _structuredWarnings,
          ),
        ],
      ],
    );
  }

  Widget _paragraphOrderEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoBox(
          icon: Icons.reorder_rounded,
          title: '문단 배열',
          message: '제시문과 (A), (B), (C) 문단을 입력하고 정답 순서를 저장합니다.',
        ),
        const SizedBox(height: 12),
        _Field(
            controller: _sourceController,
            label: '출처/단원명',
            hint: 'Unit 1 Gateway'),
        const SizedBox(height: 12),
        _Field(controller: _promptController, label: '문제 제목', hint: '문단 배열 1번'),
        const SizedBox(height: 12),
        _Field(
            controller: _orderLeadController,
            label: '제시문 입력',
            hint: 'I recently visited...',
            minLines: 3),
        const SizedBox(height: 12),
        _Field(
            controller: _orderAController,
            label: 'A 문단 입력',
            hint: 'A 문단',
            minLines: 3),
        const SizedBox(height: 12),
        _Field(
            controller: _orderBController,
            label: 'B 문단 입력',
            hint: 'B 문단',
            minLines: 3),
        const SizedBox(height: 12),
        _Field(
            controller: _orderCController,
            label: 'C 문단 입력',
            hint: 'C 문단',
            minLines: 3),
        const SizedBox(height: 12),
        _Field(
            controller: _answerTextController,
            label: '정답 순서 입력',
            hint: '[정답] (B)-(C)-(A) 또는 B-C-A'),
        const SizedBox(height: 10),
        _StructuredPreviewButton(onPressed: _previewStructuredManualQuestion),
        if (_structuredPreview != null && _isParagraphOrder) ...[
          const SizedBox(height: 12),
          _StructuredManualPreview(
            type: widget.questionType,
            answer: _structuredPreview!,
            warnings: _structuredWarnings,
          ),
        ],
      ],
    );
  }

  String _editorSubtitle() {
    if (_isInlineChoice) {
      return '자료의 [[번호:정답|오답]] 형식을 그대로 붙여넣어 선택 항목을 자동 분석합니다.';
    }
    if (_isNewTrueFalse) {
      return '워크북 출처와 함께 지문, 문항, 정답·해설을 한글파일 자료 구조처럼 묶어서 저장합니다.';
    }
    return '기존 워크북 문제 입력 방식입니다.';
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _teal, width: 1.3),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.edit_note_rounded, color: Color(0xFF0F766E)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _WorkbookFieldColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _WorkbookFieldColors.muted,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _WorkbookFieldColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: _WorkbookFieldColors.muted,
                    height: 1.35,
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

class _CheckLearningPreview extends StatelessWidget {
  const _CheckLearningPreview({required this.result});

  final CheckLearningRawParseResult result;

  @override
  Widget build(BuildContext context) {
    final wordBankCount = (result.sectionB['word_bank'] as List?)?.length ?? 0;
    final blankCount = result.sectionB['blank_count'] ?? 0;
    final bAnswerCount = (result.sectionB['answers'] as List?)?.length ?? 0;
    final wordBank = _stringList(result.sectionB['word_bank']);
    final bAnswers = _stringList(result.sectionB['answers']);
    final note = _asString(result.sectionB['note']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '확인학습 미리보기',
            style: TextStyle(
              color: _WorkbookFieldColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text('보기 $wordBankCount개'),
          Text('빈칸 $blankCount개'),
          Text('정답 $bAnswerCount개'),
          if (wordBank.isNotEmpty || bAnswers.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (wordBank.isNotEmpty) Text('보기: ${wordBank.join(', ')}'),
            if (bAnswers.isNotEmpty) Text('정답: ${bAnswers.join(', ')}'),
            if (note.isNotEmpty) Text('해설: $note'),
          ],
          if (result.warnings.isNotEmpty || result.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final warning in result.warnings)
              Text(
                '주의: $warning',
                style: const TextStyle(color: Color(0xFFB45309)),
              ),
            for (final error in result.errors)
              Text(
                '오류: $error',
                style: const TextStyle(color: Color(0xFFDC2626)),
              ),
          ],
        ],
      ),
    );
  }
}

class _StructuredPreviewButton extends StatelessWidget {
  const _StructuredPreviewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.preview_rounded),
      label: const Text('미리보기/분석'),
    );
  }
}

class _StructuredErrorBanner extends StatelessWidget {
  const _StructuredErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFB7185)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE11D48),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFBE123C),
                fontWeight: FontWeight.w900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StructuredManualPreview extends StatelessWidget {
  const _StructuredManualPreview({
    required this.type,
    required this.answer,
    required this.warnings,
  });

  final String type;
  final Map<String, dynamic> answer;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_editorTitle(type)} 미리보기',
            style: const TextStyle(
              color: _WorkbookFieldColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (type == 'initial_blank') ..._initialBlankPreview(),
          if (type == 'sentence_insertion') ..._sentenceInsertionPreview(),
          if (type == 'paragraph_order') ..._paragraphOrderPreview(),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final warning in warnings)
              Text(
                '주의: $warning',
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<Widget> _initialBlankPreview() {
    final items = (answer['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return [
      Text('빈칸 ${items.length}개'),
      Text(
          '정답 ${items.where((item) => _asString(item['answer']).isNotEmpty).length}개'),
      const SizedBox(height: 8),
      for (final item in items)
        Text(
          '(${_asString(item['label'])}) ${_asString(item['initial'])}________ → ${_asString(item['answer'])}',
        ),
    ];
  }

  List<Widget> _sentenceInsertionPreview() {
    final positions = _stringList(answer['positions']);
    return [
      Text('위치 ${positions.length}개'),
      Text('정답 ${_asString(answer['answer'])}'),
      const SizedBox(height: 8),
      Text('삽입할 문장: ${_asString(answer['insert_sentence'])}'),
      Text('위치: ${positions.join('  ')}'),
    ];
  }

  List<Widget> _paragraphOrderPreview() {
    final segments = (answer['segments'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final order = _stringList(answer['answer_order']);
    return [
      Text('문단 ${segments.length}개'),
      Text('정답 ${order.join('-')}'),
      const SizedBox(height: 8),
      Text('제시문: ${_asString(answer['lead_text'])}'),
      for (final segment in segments)
        Text('${_asString(segment['label'])}: ${_asString(segment['text'])}'),
    ];
  }
}

class _InlineChoicePreview extends StatelessWidget {
  const _InlineChoicePreview({required this.result});

  final InlineChoiceParseResult result;

  @override
  Widget build(BuildContext context) {
    return _PreviewBox(
      borderColor:
          result.hasErrors ? const Color(0xFFFCA5A5) : const Color(0xFF99F6E4),
      title: '총 ${result.items.length}개 선택 항목을 찾았습니다.',
      messages: result.errors,
      warnings: result.warnings,
      children: [
        ...result.items.map(
          (item) => _PreviewLine(
            text:
                '${item.number}. ${item.choices.join(' / ')}  ·  정답: ${item.answer}'
                '${item.explanation == null ? '' : '  ·  해설: ${item.explanation}'}',
          ),
        ),
      ],
    );
  }
}

class _TrueFalsePreview extends StatelessWidget {
  const _TrueFalsePreview({required this.result});

  final TrueFalseRawParseResult result;

  @override
  Widget build(BuildContext context) {
    return _PreviewBox(
      borderColor:
          result.hasErrors ? const Color(0xFFFCA5A5) : const Color(0xFF99F6E4),
      title: '총 ${result.items.length}개 T/F 문항을 찾았습니다.',
      messages: [...result.errors, ...result.warnings],
      children: [
        ...result.items.map(
          (item) => _PreviewLine(
            text:
                '${item.number}. ${item.statement}\n정답: ${item.answer == null ? '미입력' : (item.answer! ? 'T' : 'F')}'
                '${item.explanation == null ? '' : '\n해설: ${item.explanation}'}',
          ),
        ),
      ],
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({
    required this.borderColor,
    required this.title,
    required this.messages,
    required this.children,
    this.warnings = const [],
  });

  final Color borderColor;
  final String title;
  final List<String> messages;
  final List<Widget> children;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _WorkbookFieldColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (messages.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...messages.map(
              (message) => Text(
                '• $message',
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings.map(
              (warning) => Text(
                '참고: $warning',
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (children.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...children,
          ],
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: _WorkbookFieldColors.muted,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.helperText,
    this.minLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? helperText;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    final isWorkbookSource = label.contains('출처');
    return TextField(
      controller: controller,
      readOnly: isWorkbookSource,
      minLines: isWorkbookSource ? 1 : minLines,
      maxLines: isWorkbookSource ? 2 : minLines + 5,
      style: TextStyle(
        color: _WorkbookFieldColors.ink,
        fontWeight: isWorkbookSource ? FontWeight.w800 : FontWeight.w500,
      ),
      decoration: _fieldDecoration(
        isWorkbookSource ? '워크북 출처' : label,
        isWorkbookSource ? '워크북에 등록된 출처 정보가 없습니다.' : hint,
        helperText: isWorkbookSource
            ? '현재 워크북의 교재/출처 · 단원/강 · 세부 번호를 사용합니다.'
            : helperText,
      ).copyWith(
        prefixIcon: isWorkbookSource
            ? const Icon(Icons.menu_book_rounded, color: Color(0xFF0F766E))
            : null,
      ),
    );
  }
}

class _WorkbookFieldColors {
  static const line = Color(0xFFE2E8F0);
  static const teal = Color(0xFF0F766E);
  static const ink = Color(0xFF102A43);
  static const muted = Color(0xFF64748B);
}

InputDecoration _fieldDecoration(
  String label,
  String hint, {
  String? helperText,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helperText,
    helperMaxLines: 2,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _WorkbookFieldColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _WorkbookFieldColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide:
          const BorderSide(color: _WorkbookFieldColors.teal, width: 1.3),
    ),
  );
}

String _joinWorkbookMetadata(List<String?> values) {
  final parts = <String>[];
  for (final value in values) {
    final text = value?.trim() ?? '';
    if (text.isNotEmpty && !parts.contains(text)) parts.add(text);
  }
  return parts.join(' · ');
}

String _editorTitle(String type) {
  return switch (type) {
    'inline_choice' => '본문 선택형',
    'true_false_en' => '영어 T/F',
    'true_false_ko' => '한글 T/F',
    'initial_blank' => '첫 글자 빈칸',
    'sentence_insertion' => '문장 삽입',
    'paragraph_order' => '문단 배열',
    _ => workbookQuestionTypeLabel(type),
  };
}

String _buildInitialInlineChoiceExplanations(Map<String, dynamic> answer) {
  final rawItems = answer['items'];
  if (rawItems is! List) return '';
  final lines = <String>[];
  for (final raw in rawItems.whereType<Map>()) {
    final explanation = _asString(raw['explanation']).trim();
    if (explanation.isEmpty) continue;
    final number = _asInt(raw['number'], fallback: lines.length + 1);
    lines.add('$number. $explanation');
  }
  return lines.join('\n');
}

String _buildInitialTrueFalseStatements(Map<String, dynamic> answer) {
  final rawItems = answer['items'];
  if (rawItems is! List) return '';
  final lines = <String>[];
  for (final raw in rawItems.whereType<Map>()) {
    final number = _asInt(raw['number'], fallback: lines.length + 1);
    final statement = _asString(raw['statement']);
    if (statement.isNotEmpty) lines.add('$number. $statement');
  }
  return lines.join('\n');
}

String _buildInitialTrueFalseAnswerText(Map<String, dynamic> answer) {
  final raw = _asString(answer['answer_explanation_text']);
  if (raw.isNotEmpty) return raw;
  final rawItems = answer['items'];
  if (rawItems is! List) return '';
  final answers = <String>[];
  final explanations = <String>[];
  for (final raw in rawItems.whereType<Map>()) {
    final number = _asInt(raw['number'], fallback: explanations.length + 1);
    final itemAnswer = raw['answer'] == true ? 'T' : 'F';
    answers.add(itemAnswer);
    final explanation = _asString(raw['explanation']);
    if (explanation.isNotEmpty) explanations.add('$number. $explanation');
  }
  return [
    if (answers.isNotEmpty) '정답: ${answers.join(' ')}',
    if (explanations.isNotEmpty) '',
    if (explanations.isNotEmpty) '해설:',
    ...explanations,
  ].join('\n');
}

String _buildInitialCheckLearningA(Map<String, dynamic> answer) {
  final section = answer['section_b'];
  if (section is! Map) return '';
  return _stringList(section['word_bank']).join(' / ');
}

String _buildInitialCheckLearningB(Map<String, dynamic> answer) {
  final section = answer['section_b'];
  if (section is! Map) return '';
  final passage = _asString(section['passage_text']);
  return passage;
}

String _buildInitialCheckLearningC(Map<String, dynamic> answer) {
  final section = answer['section_b'];
  if (section is! Map) return '';
  final answers = _stringList(section['answers']).join(' / ');
  final note = _asString(section['note']);
  if (answers.isNotEmpty && note.isNotEmpty) return '$answers ($note)';
  if (answers.isNotEmpty) return answers;
  return note;
}

String _buildInitialCheckLearningExplanation(Map<String, dynamic> answer) {
  final section = answer['section_b'];
  if (section is! Map) return '';
  final note = _asString(section['note']);
  if (note.isNotEmpty) return note;
  return _stringList(section['explanations']).join('\n');
}

String _buildInitialStructuredAnswer(
  String questionType,
  Map<String, dynamic> answer,
) {
  if (questionType == 'initial_blank') {
    final items = answer['items'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((item) =>
              '(${_asString(item['label'])}) ${_asString(item['answer'])}')
          .where((item) => item.trim().length > 3)
          .join(' ');
    }
  }
  if (questionType == 'sentence_insertion') {
    return _asString(answer['answer']);
  }
  if (questionType == 'paragraph_order') {
    return _stringList(answer['answer_order']).join('-');
  }
  return _asString(answer['answer_text']);
}

String _buildInitialOrderSegment(Map<String, dynamic> answer, String label) {
  final segments = answer['segments'];
  if (segments is! List) return '';
  for (final raw in segments.whereType<Map>()) {
    if (_asString(raw['label']).toUpperCase() == label) {
      return _asString(raw['text']);
    }
  }
  return '';
}

String? _emptyToNull(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String _asString(dynamic value) {
  if (value == null) return '';
  final text = value.toString();
  return text == 'null' ? '' : text;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty && item != 'null')
      .toList();
}
