import 'package:flutter/material.dart';

import '../../config/auth_store.dart';
import '../../models/order_generation_models.dart';
import '../../services/order_generation_service.dart';
import 'teacher_problem_set_preview_screen.dart';

class TeacherSemanticOrderScreen extends StatefulWidget {
  const TeacherSemanticOrderScreen({
    super.key,
    this.gateway,
    this.openPreviewAfterSave = true,
  });

  final OrderGenerationGateway? gateway;
  final bool openPreviewAfterSave;

  @override
  State<TeacherSemanticOrderScreen> createState() =>
      _TeacherSemanticOrderScreenState();
}

class _TeacherSemanticOrderScreenState
    extends State<TeacherSemanticOrderScreen> {
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);
  static const _blue = Color(0xFF2563EB);

  late final OrderGenerationGateway _gateway;
  final _passageController = TextEditingController();
  final _nameController = TextEditingController(text: 'Semantic Order 문제');

  JsonMap? _semantic;
  OrderCandidatesResult? _candidateResult;
  OrderCandidate? _selected;
  OrderGeneratedQuestion? _generated;
  bool _busy = false;
  String? _error;
  bool _noCandidate = false;

  @override
  void initState() {
    super.initState();
    _gateway = widget.gateway ?? HttpOrderGenerationService();
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
      _selected = null;
      _generated = null;
      _error = null;
      _noCandidate = false;
    });
    try {
      final semantic = await _gateway.analyzePassage(passage);
      final result = await _gateway.fetchCandidates(semantic: semantic);
      if (!mounted) return;
      setState(() {
        _semantic = semantic;
        _candidateResult = result;
        _noCandidate =
            result.candidates.isEmpty ||
            result.reasonCode == 'ORDER_NO_CANDIDATE';
      });
    } on OrderGenerationException catch (error) {
      if (!mounted) return;
      setState(() {
        _noCandidate = error.code == 'ORDER_NO_CANDIDATE';
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
    final target = selected == null
        ? null
        : _candidateResult?.targetFor(selected);
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
    } on OrderGenerationException catch (error) {
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
    } on OrderGenerationException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) setState(() => _error = '문제세트 저장에 실패했습니다. 다시 시도해 주세요.');
    } finally {
      _setBusy(false);
    }
  }

  String _messageFor(OrderGenerationException error) {
    switch (error.code) {
      case 'ORDER_NO_CANDIDATE':
        return '이 지문에서는 의미상 순서가 하나로 확정되는 안전한 순서 문제 후보를 찾지 못했습니다.';
      case 'ORDER_SINGLE_ANSWER_VALIDATION_FAILED':
        return '이 후보는 순서가 하나로 확정되지 않아 문제를 생성하지 않았습니다. 다른 후보를 선택해 주세요.';
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
    final candidates = _candidateResult?.candidates ?? const <OrderCandidate>[];
    final canGenerate =
        _selected != null &&
        _candidateResult?.targetFor(_selected!) != null &&
        !_busy;
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Semantic 순서 문제 만들기',
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
                          '지문을 분석해 순서가 하나로 확정되는 안전한 후보만 제시합니다.',
                          style: TextStyle(color: _muted),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          key: const Key('order-passage-input'),
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
                            key: const Key('order-analyze-button'),
                            onPressed:
                                _busy || _passageController.text.trim().isEmpty
                                ? null
                                : _analyze,
                            icon: const Icon(Icons.manage_search_rounded),
                            label: Text(_busy ? '처리 중...' : 'Order 후보 분석'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _messageBox(
                      key: const Key('order-error-state'),
                      text: _error!,
                      color: const Color(0xFFB91C1C),
                    ),
                  ],
                  if (_noCandidate) ...[
                    const SizedBox(height: 14),
                    _messageBox(
                      key: const Key('order-no-candidate-state'),
                      text: '이 지문에서는 의미상 순서가 하나로 확정되는 안전한 순서 문제 후보를 찾지 못했습니다.',
                      color: const Color(0xFF92400E),
                    ),
                  ],
                  if (candidates.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      '2. 출제 후보 선택',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final candidate in candidates)
                      _candidateCard(candidate),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('order-generate-button'),
                        onPressed: canGenerate ? _generate : null,
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

  Widget _candidateCard(OrderCandidate candidate) {
    final selected = identical(_selected, candidate);
    final fixedIntro = _sentencesFor(candidate.fixedIntroSentenceIds);
    return Card(
      key: Key('order-candidate-${candidate.candidateId}'),
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? const Color(0xFFEFF6FF) : Colors.white,
      child: RadioListTile<OrderCandidate>(
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
          '안전도 ${(candidate.suitabilityScore * 100).round()}% · ${candidate.suitabilityLevel}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fixedIntro.isNotEmpty) Text('주어진 글: $fixedIntro'),
              for (final block in candidate.blocks)
                Text('${block.blockId}: ${block.text}'),
              for (final evidence in candidate.evidenceSummaries.take(2))
                Text(evidence, style: const TextStyle(color: _muted)),
              for (final reason in candidate.suitabilityReasons.take(1))
                Text(reason, style: const TextStyle(color: _muted)),
            ],
          ),
        ),
      ),
    );
  }

  String _sentencesFor(List<String> sentenceIds) {
    final sentences = _semantic?['sentences'];
    if (sentences is! List) return '';
    final textById = <String, String>{};
    for (final sentence in sentences) {
      if (sentence is Map) {
        textById[(sentence['sentence_id'] ?? '').toString()] =
            (sentence['text'] ?? '').toString();
      }
    }
    return sentenceIds
        .map((id) => textById[id] ?? '')
        .where((text) => text.isNotEmpty)
        .join(' ');
  }

  Widget _preview(OrderGeneratedQuestion question) {
    return _card(
      key: const Key('order-generated-preview'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3. 생성 결과 미리보기',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Text('문제 유형: 순서 배열'),
          const SizedBox(height: 8),
          Text(
            question.stem,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _previewBlock('주어진 글', 'A', question.fixedIntro),
          const SizedBox(height: 10),
          const Text('이어질 글', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          for (final block in question.productBlocks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _previewBlock('', block.label, block.text),
            ),
          const SizedBox(height: 6),
          Text(
            '정답 순서: ${question.productAnswerWithArrows}',
            key: const Key('order-preview-answer'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text('해설: ${question.explanation}'),
          const Divider(height: 28),
          TextField(
            key: const Key('order-problem-set-name'),
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
              key: const Key('order-save-button'),
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
  }

  Widget _previewBlock(String heading, String label, String text) {
    return Container(
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
          if (heading.isNotEmpty) ...[
            Text(
              heading,
              style: const TextStyle(color: _blue, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
          ],
          Text('($label) $text'),
        ],
      ),
    );
  }

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
