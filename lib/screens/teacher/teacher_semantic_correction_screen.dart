import 'package:flutter/material.dart';

import '../../config/auth_store.dart';
import '../../models/correction_generation_models.dart';
import '../../services/correction_generation_service.dart';
import '../../utils/grammar_vocabulary_inline_spans.dart';
import 'teacher_problem_set_preview_screen.dart';

class TeacherSemanticCorrectionScreen extends StatefulWidget {
  const TeacherSemanticCorrectionScreen({
    super.key,
    this.gateway,
    this.openPreviewAfterSave = true,
  });

  final CorrectionGenerationGateway? gateway;
  final bool openPreviewAfterSave;

  @override
  State<TeacherSemanticCorrectionScreen> createState() =>
      _TeacherSemanticCorrectionScreenState();
}

class _TeacherSemanticCorrectionScreenState
    extends State<TeacherSemanticCorrectionScreen> {
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);

  late final CorrectionGenerationGateway _gateway;
  final _passageController = TextEditingController();
  final _nameController = TextEditingController(text: 'Semantic Correction 문제');

  JsonMap? _semantic;
  List<CorrectionCandidate> _candidates = const [];
  CorrectionCandidate? _selected;
  CorrectionGeneratedQuestion? _generated;
  bool _busy = false;
  String? _error;
  bool _noCandidate = false;

  @override
  void initState() {
    super.initState();
    _gateway = widget.gateway ?? HttpCorrectionGenerationService();
    _passageController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _passageController
      ..removeListener(_onInputChanged)
      ..dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  void _setBusy(bool value) {
    if (mounted) setState(() => _busy = value);
  }

  Future<void> _analyze() async {
    final passage = _passageController.text.trim();
    if (passage.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _noCandidate = false;
      _semantic = null;
      _candidates = const [];
      _selected = null;
      _generated = null;
    });
    try {
      final semantic = await _gateway.analyzePassage(passage);
      final result = await _gateway.fetchCandidates(semantic: semantic);
      if (!mounted) return;
      setState(() {
        _semantic = semantic;
        _candidates = result.candidates;
        _noCandidate = result.candidates.isEmpty;
      });
    } on CorrectionGenerationException catch (error) {
      if (!mounted) return;
      setState(() {
        _noCandidate = error.code == 'CORRECTION_NO_CANDIDATE';
        _error = _noCandidate ? null : _messageFor(error);
      });
    } catch (_) {
      if (mounted) setState(() => _error = '네트워크 상태를 확인하고 다시 시도해 주세요.');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _generate() async {
    final semantic = _semantic;
    final selected = _selected;
    if (semantic == null || selected == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _generated = null;
    });
    try {
      final generated = await _gateway.generate(
        semantic: semantic,
        target: selected,
      );
      if (mounted) setState(() => _generated = generated);
    } on CorrectionGenerationException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) setState(() => _error = '문제 생성 요청에 실패했습니다. 다시 시도해 주세요.');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _save() async {
    final generated = _generated;
    final name = _nameController.text.trim();
    if (generated == null || name.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _gateway.saveProblemSet(
        name: name,
        passage: _passageController.text.trim(),
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
    } on CorrectionGenerationException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) setState(() => _error = '문제세트 저장에 실패했습니다. 다시 시도해 주세요.');
    } finally {
      _setBusy(false);
    }
  }

  String _messageFor(CorrectionGenerationException error) {
    switch (error.code) {
      case 'CORRECTION_TARGET_INVALID':
      case 'CORRECTION_AMBIGUOUS':
      case 'CORRECTION_SINGLE_ERROR_FAILED':
      case 'CORRECTION_VALIDATION_FAILED':
      case 'CORRECTION_GENERATION_FAILED':
        return '이 후보로는 안전한 문제를 생성하지 못했습니다. 다른 후보를 선택해 주세요.';
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
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Semantic 어법·문맥 고치기',
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
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. 영어 지문 입력',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '지문을 분석해 안전하게 변형할 수 있는 후보만 제시합니다.',
                          style: TextStyle(color: _muted),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          key: const Key('correction-passage-input'),
                          controller: _passageController,
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
                            key: const Key('correction-analyze-button'),
                            onPressed:
                                _busy || _passageController.text.trim().isEmpty
                                    ? null
                                    : _analyze,
                            icon: const Icon(Icons.manage_search_rounded),
                            label: Text(_busy ? '처리 중...' : 'Correction 후보 분석'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _messageBox(
                      key: const Key('correction-error-state'),
                      text: _error!,
                      color: const Color(0xFFB91C1C),
                    ),
                  ],
                  if (_noCandidate) ...[
                    const SizedBox(height: 14),
                    _messageBox(
                      key: const Key('correction-no-candidate-state'),
                      text: '이 지문에서는 안전하게 만들 수 있는 어법·문맥 고치기 후보를 찾지 못했습니다.',
                      color: const Color(0xFF92400E),
                    ),
                  ],
                  if (_candidates.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      '2. 출제 후보 선택',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final candidate in _candidates)
                      _candidateCard(candidate),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('correction-generate-button'),
                        onPressed:
                            _busy || _selected == null ? null : _generate,
                        icon: const Icon(Icons.auto_fix_high_rounded),
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

  Widget _candidateCard(CorrectionCandidate candidate) {
    final selected = identical(_selected, candidate);
    final sentenceText = _sentenceText(candidate.targetSentenceId);
    return Card(
      key: Key('correction-candidate-${candidate.candidateId}'),
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? const Color(0xFFEFF6FF) : Colors.white,
      child: RadioListTile<CorrectionCandidate>(
        value: candidate,
        groupValue: _selected,
        onChanged: _busy
            ? null
            : (value) => setState(() {
                  _selected = value;
                  _generated = null;
                  _error = null;
                }),
        title: Text(
          '문장 ${candidate.targetSentenceIndex + 1} · ${_familyLabel(candidate.corruptionFamily)}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sentenceText.isNotEmpty) ...[
                Text(sentenceText),
                const SizedBox(height: 4),
              ],
              Text('${candidate.originalText} → ${candidate.replacementText}'),
              if (candidate.reason.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(candidate.reason, style: const TextStyle(color: _muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _sentenceText(String sentenceId) {
    final sentences = _semantic?['sentences'];
    if (sentences is! List) return '';
    for (final sentence in sentences) {
      if (sentence is Map && sentence['sentence_id'] == sentenceId) {
        return sentence['text']?.toString() ?? '';
      }
    }
    return '';
  }

  Widget _preview(CorrectionGeneratedQuestion question) {
    return _card(
      key: const Key('correction-generated-preview'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3. 생성 결과 미리보기',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Text('문제 유형: 어법·문맥 고치기'),
          const SizedBox(height: 8),
          Text(
            question.stem,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text.rich(
            buildGrammarVocabularyInlineSpans(
              passage: question.markedPreviewPassage,
              specialData: question.previewSpecialData,
              baseStyle: const TextStyle(
                color: _ink,
                fontSize: 15,
                height: 1.65,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '정답: ${question.answer}:${question.correctExpression}',
            key: const Key('correction-preview-answer'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text('해설: ${question.explanation}'),
          const Divider(height: 28),
          TextField(
            key: const Key('correction-problem-set-name'),
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
              key: const Key('correction-save-button'),
              onPressed:
                  _busy || _nameController.text.trim().isEmpty ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('문제세트에 저장'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({Key? key, required Widget child}) {
    return Container(
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
  }

  Widget _messageBox({Key? key, required String text, required Color color}) {
    return Container(
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

  String _familyLabel(String family) {
    const labels = {
      'connector_mismatch': '연결어 불일치',
      'relation_reversal': '관계 반전',
      'cause_effect_reversal': '인과 반전',
      'condition_change': '조건 변경',
      'scope_strengthen': '범위 강화',
      'scope_weaken': '범위 약화',
      'reference_swap': '지칭 대상 변경',
      'audited_antonym': '반의어 변형',
      'modal_base_form': '조동사 형태',
      'do_aux_base_form': 'do 조동사 형태',
    };
    return labels[family] ?? family;
  }
}
