import 'package:flutter/material.dart';

import '../../config/auth_store.dart';
import '../../models/blank_generation_models.dart';
import '../../services/blank_generation_service.dart';
import 'teacher_problem_set_preview_screen.dart';

class TeacherSemanticBlankScreen extends StatefulWidget {
  const TeacherSemanticBlankScreen({
    super.key,
    this.gateway,
    this.openPreviewAfterSave = true,
  });

  final BlankGenerationGateway? gateway;
  final bool openPreviewAfterSave;

  @override
  State<TeacherSemanticBlankScreen> createState() =>
      _TeacherSemanticBlankScreenState();
}

class _TeacherSemanticBlankScreenState
    extends State<TeacherSemanticBlankScreen> {
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);
  static const _violet = Color(0xFF6D28D9);

  late final BlankGenerationGateway _gateway;
  final _passageController = TextEditingController();
  final _nameController = TextEditingController(text: 'Semantic Blank 문제');

  JsonMap? _semantic;
  String _authoringPassage = '';
  String? _analyzedPassage;
  BlankCandidatesResult? _candidateResult;
  BlankGenerationTarget? _selectedTarget;
  BlankGeneratedQuestion? _generated;
  bool _busy = false;
  bool _noCandidate = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _gateway = widget.gateway ?? HttpBlankGenerationService();
    _passageController.addListener(_refresh);
    _nameController.addListener(_refresh);
  }

  @override
  void dispose() {
    _passageController
      ..removeListener(_refresh)
      ..dispose();
    _nameController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _setBusy(bool value) {
    if (mounted) setState(() => _busy = value);
  }

  void _restoreAuthoringPassage() {
    if (!mounted || _passageController.text == _authoringPassage) return;
    _passageController.value = TextEditingValue(
      text: _authoringPassage,
      selection: TextSelection.collapsed(offset: _authoringPassage.length),
    );
  }

  Future<void> _analyze() async {
    final passage = _passageController.text.trim();
    if (passage.isEmpty || _busy) return;
    _authoringPassage = passage;
    setState(() {
      _busy = true;
      _analyzedPassage = passage;
      _semantic = null;
      _candidateResult = null;
      _selectedTarget = null;
      _generated = null;
      _noCandidate = false;
      _error = null;
    });
    try {
      final semantic = await _gateway.analyzePassage(passage);
      final result = await _gateway.fetchCandidates(semantic: semantic);
      if (!mounted) return;
      setState(() {
        _semantic = semantic;
        _candidateResult = result;
        _noCandidate = result.selectedTarget == null;
      });
      _restoreAuthoringPassage();
    } on BlankGenerationException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) setState(() => _error = '네트워크 상태를 확인하고 다시 시도해 주세요.');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _generate() async {
    _restoreAuthoringPassage();
    final semantic = _semantic;
    final target = _selectedTarget;
    if (semantic == null || target == null || _busy) return;
    setState(() {
      _busy = true;
      _generated = null;
      _error = null;
    });
    try {
      final generated = await _gateway.generate(
        semantic: semantic,
        target: target,
      );
      if (mounted) {
        setState(() => _generated = generated);
        _restoreAuthoringPassage();
      }
    } on BlankGenerationException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) setState(() => _error = '안전하게 생성하지 못했습니다. 다시 시도해 주세요.');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _save() async {
    _restoreAuthoringPassage();
    final generated = _generated;
    final name = _nameController.text.trim();
    final passage = (_analyzedPassage ?? '').trim();
    if (generated == null || name.isEmpty || _busy) return;
    if (passage.isEmpty) {
      setState(() => _error = '분석에 사용한 영어 지문을 확인해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _gateway.saveProblemSet(
        name: name,
        passage: passage,
        question: generated,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문제세트 저장 완료: #${result.problemSetId}')),
      );
      if (widget.openPreviewAfterSave) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TeacherProblemSetPreviewScreen(
              problemSetId: result.problemSetId,
            ),
          ),
        );
      }
    } on BlankGenerationException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) setState(() => _error = '문제세트 저장에 실패했습니다. 다시 시도해 주세요.');
    } finally {
      _setBusy(false);
    }
  }

  String _messageFor(BlankGenerationException error) {
    switch (error.code) {
      case 'BLANK_SINGLE_ANSWER_VALIDATION_FAILED':
        return '정답을 하나로 안전하게 확정하지 못해 생성을 중단했습니다.';
      case 'BLANK_TARGET_INVALID':
        return '선택한 후보를 사용할 수 없습니다. 지문을 다시 분석해 주세요.';
      case 'BLANK_LLM_FAILED':
        return '안전하게 생성하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      case 'TEACHER_REQUIRED':
        return '교사 계정으로 로그인해 주세요.';
      case 'SEMANTIC_ANALYSIS_FAILED':
        return '지문 분석에 실패했습니다. 잠시 후 다시 시도해 주세요.';
      default:
        if (error.statusCode == 401 || error.statusCode == 403) {
          return '교사 인증을 확인해 주세요.';
        }
        return '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthStore.isTeacher) {
      return const Scaffold(body: Center(child: Text('교사 계정으로 로그인해 주세요.')));
    }
    final result = _candidateResult;
    final target = result?.selectedTarget;
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Semantic 빈칸 만들기',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputCard(),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _messageBox(
                      key: const Key('blank-error-state'),
                      text: _error!,
                      color: const Color(0xFFB91C1C),
                    ),
                  ],
                  if (_noCandidate) ...[
                    const SizedBox(height: 14),
                    _messageBox(
                      key: const Key('blank-no-candidate-state'),
                      text: '안전한 빈칸 문제 후보를 찾지 못했습니다.',
                      color: const Color(0xFF92400E),
                    ),
                  ],
                  if (result != null && result.candidates.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      '2. 빈칸 후보 확인',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final candidate in result.candidates)
                      _candidateSummary(candidate),
                  ],
                  if (target != null) ...[
                    const SizedBox(height: 8),
                    _targetCard(target),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('blank-generate-button'),
                        onPressed: _selectedTarget == null || _busy
                            ? null
                            : _generate,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('선택한 후보로 문제 생성'),
                      ),
                    ),
                  ],
                  if (_generated != null) ...[
                    const SizedBox(height: 18),
                    _preview(_generated!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. 영어 지문 입력',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Backend 의미 분석과 Independent Judge를 통과한 빈칸만 생성합니다.',
          style: TextStyle(color: _muted),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('blank-passage-input'),
          controller: _passageController,
          onChanged: (value) => _authoringPassage = value,
          minLines: 8,
          maxLines: 16,
          decoration: const InputDecoration(
            hintText: '영어 지문을 입력하세요.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('blank-analyze-button'),
            onPressed: _busy || _passageController.text.trim().isEmpty
                ? null
                : _analyze,
            icon: const Icon(Icons.manage_search_rounded),
            label: Text(_busy ? '처리 중...' : '빈칸 후보 분석'),
          ),
        ),
      ],
    ),
  );

  Widget _candidateSummary(BlankCandidate candidate) => Container(
    key: Key('blank-candidate-summary-${candidate.candidateId}'),
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          candidate.text,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${candidate.sentenceId} · ${candidate.blankType} · '
          '${candidate.semanticRole} · '
          '${(candidate.suitabilityScore * 100).round()}%',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        if (candidate.suitabilityReasons.isNotEmpty)
          Text(
            candidate.suitabilityReasons.first,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
      ],
    ),
  );

  Widget _targetCard(BlankGenerationTarget target) {
    final selected = identical(_selectedTarget, target);
    return Card(
      key: Key('blank-candidate-${target.candidateId}'),
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? const Color(0xFFF5F3FF) : Colors.white,
      child: RadioListTile<BlankGenerationTarget>(
        value: target,
        groupValue: _selectedTarget,
        onChanged: _busy
            ? null
            : (value) {
                _restoreAuthoringPassage();
                setState(() {
                  _selectedTarget = value;
                  _generated = null;
                  _error = null;
                });
              },
        title: Text(
          target.text,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${target.sentenceId} · ${target.blankType} · '
          '${target.semanticRole} · 안전도 '
          '${(target.selectionScore * 100).round()}%',
        ),
      ),
    );
  }

  Widget _preview(BlankGeneratedQuestion question) => _card(
    key: const Key('blank-generated-preview'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. 생성 결과 미리보기',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          question.stem,
          key: const Key('blank-preview-question'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _previewBlock(
          '지문',
          question.blankedPassage,
          key: const Key('blank-preview-passage'),
        ),
        const SizedBox(height: 10),
        for (final choice in question.choices)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: choice.choiceNo == question.answerPosition
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _line),
            ),
            child: Text(
              '${blankChoiceLabel(choice.choiceNo)} ${choice.text}',
              key: Key('blank-preview-choice-${choice.choiceNo}'),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          '정답: ${question.displayAnswer}',
          key: const Key('blank-preview-answer'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          '해설: ${question.explanation}',
          key: const Key('blank-preview-explanation'),
        ),
        const Divider(height: 28),
        TextField(
          key: const Key('blank-problem-set-name'),
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '새 문제세트 이름',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('blank-save-button'),
            onPressed: _busy || _nameController.text.trim().isEmpty
                ? null
                : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('문제세트에 저장'),
          ),
        ),
      ],
    ),
  );

  Widget _previewBlock(String heading, String text, {Key? key}) => Container(
    key: key,
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(color: _violet, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        SelectableText(text),
      ],
    ),
  );

  Widget _card({Key? key, required Widget child}) => Container(
    key: key,
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _line),
    ),
    child: child,
  );

  Widget _messageBox({Key? key, required String text, required Color color}) =>
      Container(
        key: key,
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      );
}
