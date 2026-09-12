import 'package:flutter/material.dart';

import '../../config/auth_store.dart';
import '../../models/content_match_generation_models.dart';
import '../../services/content_match_generation_service.dart';
import 'teacher_problem_set_preview_screen.dart';

class TeacherSemanticContentMatchScreen extends StatefulWidget {
  const TeacherSemanticContentMatchScreen({
    super.key,
    this.gateway,
    this.openPreviewAfterSave = true,
  });

  final ContentMatchGenerationGateway? gateway;
  final bool openPreviewAfterSave;

  @override
  State<TeacherSemanticContentMatchScreen> createState() =>
      _TeacherSemanticContentMatchScreenState();
}

class _TeacherSemanticContentMatchScreenState
    extends State<TeacherSemanticContentMatchScreen> {
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);
  static const _violet = Color(0xFF6D28D9);

  late final ContentMatchGenerationGateway _gateway;
  final _passageController = TextEditingController();
  final _nameController = TextEditingController(
    text: 'Semantic Content Match 문제',
  );

  JsonMap? _semantic;
  ContentMatchCandidatesResult? _candidateResult;
  ContentMatchGenerationTarget? _selectedTarget;
  ContentMatchGeneratedQuestion? _generated;
  String _questionMode = 'content_match';
  bool _busy = false;
  String? _error;
  bool _noCandidate = false;

  @override
  void initState() {
    super.initState();
    _gateway = widget.gateway ?? HttpContentMatchGenerationService();
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

  Future<void> _analyze() async {
    final passage = _passageController.text.trim();
    if (passage.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _semantic = null;
      _candidateResult = null;
      _selectedTarget = null;
      _generated = null;
      _error = null;
      _noCandidate = false;
    });
    try {
      final semantic = await _gateway.analyzePassage(passage);
      final result = await _gateway.fetchCandidates(
        semantic: semantic,
        questionMode: _questionMode,
      );
      if (!mounted) return;
      setState(() {
        _semantic = semantic;
        _candidateResult = result;
        _noCandidate = result.selectedTarget == null;
      });
    } on ContentMatchGenerationException catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) setState(() => _error = '네트워크 상태를 확인하고 다시 시도해 주세요.');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _generate() async {
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
      if (mounted) setState(() => _generated = generated);
    } on ContentMatchGenerationException catch (error) {
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
    } on ContentMatchGenerationException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) setState(() => _error = '문제세트 저장에 실패했습니다. 다시 시도해 주세요.');
    } finally {
      _setBusy(false);
    }
  }

  String _messageFor(ContentMatchGenerationException error) {
    switch (error.code) {
      case 'CONTENT_MATCH_SEMANTIC_VALIDATION_FAILED':
      case 'CONTENT_MATCH_SINGLE_ANSWER_VALIDATION_FAILED':
        if (error.message.contains('JUDGE_DISAGREEMENT')) {
          return '문항의 정답 집합을 안전하게 확정할 수 없어 생성을 중단했습니다.';
        }
        return '정답이 정확히 2개로 확정되지 않아 문제를 생성하지 않았습니다.';
      case 'CONTENT_MATCH_TARGET_INVALID':
        return '선택한 후보를 사용할 수 없습니다. 지문을 다시 분석해 주세요.';
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
    final target = _candidateResult?.selectedTarget;
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Semantic 내용 일치 만들기',
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
                      key: const Key('content-match-error-state'),
                      text: _error!,
                      color: const Color(0xFFB91C1C),
                    ),
                  ],
                  if (_noCandidate) ...[
                    const SizedBox(height: 14),
                    _messageBox(
                      key: const Key('content-match-no-candidate-state'),
                      text:
                          '이 지문에서는 정답 2개와 명확한 오답 4개를 안전하게 구성할 수 있는 내용 일치 후보를 찾지 못했습니다.',
                      color: const Color(0xFF92400E),
                    ),
                  ],
                  if (target != null) ...[
                    const SizedBox(height: 18),
                    const Text(
                      '2. 출제 후보 선택',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _targetCard(target),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('content-match-generate-button'),
                        onPressed:
                            _selectedTarget == null || _busy ? null : _generate,
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
              'Backend 의미 분석으로 정답 2개가 명확한 후보만 구성합니다.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const Key('content-match-mode-selector'),
              value: _questionMode,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '문제 유형',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'content_match',
                  child: Text('내용과 일치하는 것 두 개'),
                ),
                DropdownMenuItem(
                  value: 'content_mismatch',
                  child: Text('내용과 일치하지 않는 것 두 개'),
                ),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _questionMode = value;
                        _semantic = null;
                        _candidateResult = null;
                        _selectedTarget = null;
                        _generated = null;
                        _error = null;
                        _noCandidate = false;
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('content-match-passage-input'),
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
                key: const Key('content-match-analyze-button'),
                onPressed: _busy || _passageController.text.trim().isEmpty
                    ? null
                    : _analyze,
                icon: const Icon(Icons.manage_search_rounded),
                label: Text(_busy ? '처리 중...' : 'Content Match 후보 분석'),
              ),
            ),
          ],
        ),
      );

  Widget _targetCard(ContentMatchGenerationTarget target) {
    final selected = identical(_selectedTarget, target);
    final modeLabel =
        target.questionMode == 'content_mismatch' ? '내용 불일치' : '내용 일치';
    return Card(
      key: Key('content-match-candidate-${target.targetId}'),
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? const Color(0xFFF5F3FF) : Colors.white,
      child: RadioListTile<ContentMatchGenerationTarget>(
        value: target,
        groupValue: _selectedTarget,
        onChanged: _busy
            ? null
            : (value) => setState(() {
                  _selectedTarget = value;
                  _generated = null;
                  _error = null;
                }),
        title: Text(
          '$modeLabel · 안전도 ${(target.selectionScore * 100).round()}%',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('검증된 의미 주장 ${target.claims.length}개'),
              for (final claim in target.claims.take(3)) ...[
                const SizedBox(height: 4),
                Text('• ${claim.meaning}'),
                if (claim.evidenceSummaries.isNotEmpty)
                  Text(
                    claim.evidenceSummaries.first,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(ContentMatchGeneratedQuestion question) => _card(
        key: const Key('content-match-generated-preview'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3. 생성 결과 미리보기',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              question.questionMode == 'content_mismatch'
                  ? '문제 유형: 내용 불일치 · 2개 선택'
                  : '문제 유형: 내용 일치 · 2개 선택',
            ),
            const SizedBox(height: 8),
            Text(
              question.stem,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _previewBlock('지문', _passageController.text.trim()),
            const SizedBox(height: 10),
            for (final choice in question.choices)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: question.answerPositions.contains(choice.choiceNo)
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _line),
                ),
                child: Text(
                  '${contentMatchChoiceLabel(choice.choiceNo)} ${choice.text}',
                  key: Key('content-match-preview-choice-${choice.choiceNo}'),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '정답: ${question.displayAnswer}',
              key: const Key('content-match-preview-answer'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text('해설: ${question.explanation}'),
            const Divider(height: 28),
            TextField(
              key: const Key('content-match-problem-set-name'),
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
                key: const Key('content-match-save-button'),
                onPressed:
                    _busy || _nameController.text.trim().isEmpty ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('문제세트에 저장'),
              ),
            ),
          ],
        ),
      );

  Widget _previewBlock(String heading, String text) => Container(
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
              style:
                  const TextStyle(color: _violet, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(text),
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
