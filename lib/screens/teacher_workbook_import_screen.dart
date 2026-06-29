import 'package:flutter/material.dart';

import '../models/workbook.dart';
import '../models/workbook_import_candidate.dart';
import '../services/workbook_hwpx_file_picker.dart';
import '../services/workbook_service.dart';
import '../utils/workbook_hwpx_text_extractor.dart';
import '../utils/workbook_import_parser.dart';

class WorkbookImportSaveResult {
  const WorkbookImportSaveResult({
    required this.savedQuestionIds,
    required this.failures,
  });

  final List<int> savedQuestionIds;
  final List<String> failures;

  int get savedCount => savedQuestionIds.length;
}

class TeacherWorkbookImportScreen extends StatefulWidget {
  const TeacherWorkbookImportScreen({super.key, required this.workbook});

  final Workbook workbook;

  @override
  State<TeacherWorkbookImportScreen> createState() =>
      _TeacherWorkbookImportScreenState();
}

class _TeacherWorkbookImportScreenState
    extends State<TeacherWorkbookImportScreen> {
  static const _teal = Color(0xFF0F766E);
  static const _ink = Color(0xFF102A43);
  static const _line = Color(0xFFE2E8F0);

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _service = const WorkbookService();
  List<WorkbookImportCandidate> _candidates = const [];
  final Set<String> _selected = {};
  final Set<String> _duplicateCandidates = {};
  final Map<String, GlobalKey> _candidateKeys = {};
  bool _analyzed = false;
  bool _saving = false;
  bool _pickingHwpx = false;
  String? _pickedHwpxName;
  int _omittedCount = 0;
  bool _removedPreamble = false;

  String get _sourceText => _join([
        widget.workbook.sourceLabel,
        widget.workbook.folderName,
        widget.workbook.unitLabel,
      ]);

  int get _warningCount => _candidates
      .where((item) => item.warnings.isNotEmpty || item.errors.isNotEmpty)
      .length;

  int get _unknownCount => _candidates.where((item) => item.isUnknown).length;

  bool _isDuplicateItem(WorkbookImportCandidate item) =>
      _duplicateCandidates.contains(item.localId);

  bool _isSelectable(WorkbookImportCandidate item) =>
      !item.isUnknown && !item.hasBlockingErrors;

  bool _isNormalCandidate(WorkbookImportCandidate item) =>
      _isSelectable(item) && item.warnings.isEmpty && !_isDuplicateItem(item);

  void _selectCandidates(bool Function(WorkbookImportCandidate item) test) {
    setState(() {
      _selected
        ..clear()
        ..addAll(
          _candidates
              .where((item) => _isSelectable(item) && test(item))
              .map((item) => item.localId),
        );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _analyze() {
    if (_controller.text.trim().isEmpty) {
      _message('문제 묶음 텍스트를 붙여넣어 주세요.');
      return;
    }
    final result = parseWorkbookImportTextDetailed(
      _controller.text,
      workbookSource: _sourceText,
    );
    final items = result.candidates;
    final duplicates = {
      for (final item in items)
        if (widget.workbook.questions.any(
          (question) => _isDuplicateCandidate(item, question),
        ))
          item.localId,
    };
    setState(() {
      _candidates = items;
      _omittedCount = result.omittedCount;
      _removedPreamble = result.removedPreamble;
      _candidateKeys
        ..clear()
        ..addEntries(
          items.map((item) => MapEntry(item.localId, GlobalKey())),
        );
      _duplicateCandidates
        ..clear()
        ..addAll(duplicates);
      _selected
        ..clear()
        ..addAll(
          items
              .where(
                (item) =>
                    item.isSelectedByDefault &&
                    !duplicates.contains(item.localId),
              )
              .map((item) => item.localId),
        );
      _analyzed = true;
    });
  }

  Future<void> _pickHwpx() async {
    if (_pickingHwpx) return;
    setState(() => _pickingHwpx = true);
    try {
      final picked = await pickWorkbookHwpxFile();
      if (picked == null) return;
      if (!picked.name.toLowerCase().endsWith('.hwpx')) {
        throw const FormatException('HWPX 파일만 선택할 수 있습니다.');
      }
      if (picked.bytes.length > 30 * 1024 * 1024) {
        throw const FormatException('30MB 이하의 HWPX 파일을 선택해 주세요.');
      }
      final extracted = extractWorkbookTextFromHwpx(picked.bytes);
      _controller.text = extracted.text;
      if (!mounted) return;
      setState(() {
        _pickedHwpxName = picked.name;
        _analyzed = false;
        _candidates = const [];
        _selected.clear();
        _duplicateCandidates.clear();
        _candidateKeys.clear();
        _omittedCount = 0;
        _removedPreamble = false;
      });
      _analyze();
      _message(
        '${picked.name}에서 ${extracted.paragraphCount}개 문단을 추출했습니다.',
      );
    } catch (error) {
      if (!mounted) return;
      _message('HWPX 텍스트 추출 실패: $error');
    } finally {
      if (mounted) setState(() => _pickingHwpx = false);
    }
  }

  Future<void> _save() async {
    final items = _candidates
        .where((item) => _selected.contains(item.localId) && !item.isUnknown)
        .toList();
    if (items.isEmpty || _saving) {
      if (items.isEmpty) _message('저장할 문제를 선택해 주세요.');
      return;
    }
    final duplicateCount = items
        .where((item) => _duplicateCandidates.contains(item.localId))
        .length;
    final warningCount = items
        .where((item) => item.warnings.isNotEmpty || item.errors.isNotEmpty)
        .length;
    if (duplicateCount > 0 || warningCount > 0 || items.length >= 10) {
      final proceed = await _confirmSave(
        total: items.length,
        duplicateCount: duplicateCount,
        warningCount: warningCount,
      );
      if (proceed != true) return;
    }
    setState(() => _saving = true);
    final savedQuestionIds = <int>[];
    final failures = <String>[];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      try {
        final created = await _service.createQuestion(
          workbookId: widget.workbook.id,
          questionType: item.questionType,
          prompt: item.prompt,
          sectionKey: _sectionInfoForCandidate(item).key,
          sectionTitle: _sectionInfoForCandidate(item).title,
          passageText: item.passageText,
          choices: item.choices,
          answer: item.answer,
          explanation: item.explanation,
        );
        savedQuestionIds.add(created.id);
      } catch (error) {
        failures.add('${index + 1}번 후보 (${item.title}): $error');
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    await _showSaveSummary(savedQuestionIds.length, failures);
    if (!mounted) return;
    Navigator.pop(
      context,
      WorkbookImportSaveResult(
        savedQuestionIds: savedQuestionIds,
        failures: failures,
      ),
    );
  }

  Future<bool?> _confirmSave({
    required int total,
    required int duplicateCount,
    required int warningCount,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택한 문제를 저장할까요?'),
        content: Text(
          '저장 예정: $total개\n'
          '중복 의심: $duplicateCount개\n'
          '경고 있음: $warningCount개\n\n'
          '${duplicateCount > 0 ? '중복 의심 문제가 포함되어 있습니다. ' : ''}'
          '저장을 진행하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장 진행'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaveSummary(
    int savedCount,
    List<String> failures,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(failures.isEmpty ? '문제 가져오기 완료' : '문제 가져오기 일부 완료'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('성공: $savedCount개'),
                Text('실패: ${failures.length}개'),
                if (failures.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '실패 사유',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  for (final failure in failures) Text('• $failure'),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('워크북으로 돌아가기'),
          ),
        ],
      ),
    );
  }

  Future<void> _editCandidateRaw(WorkbookImportCandidate item) async {
    final controller = TextEditingController(text: item.rawText);
    final hasWarning = item.errors.isNotEmpty || item.warnings.isNotEmpty;
    final statusLabel = item.isUnknown
        ? '유형 미확인'
        : hasWarning
            ? '검토 필요'
            : '정상 후보';
    final statusColor = item.isUnknown
        ? const Color(0xFFBE123C)
        : hasWarning
            ? const Color(0xFFA16207)
            : _teal;
    final updatedRaw = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final screenHeight = MediaQuery.sizeOf(dialogContext).height;
        final dialogHeight = screenHeight < 720 ? screenHeight - 40 : 640.0;
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _line),
          ),
          child: SizedBox(
            width: 760,
            height: dialogHeight,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.edit_document, color: statusColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '원문 수정 후 다시 분석',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              '정답 형식이나 유형 표시를 수정한 뒤 다시 분석할 수 있습니다.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _candidateStatusChip(
                                statusLabel,
                                statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '닫기',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _line),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 19,
                          color: Color(0xFF475569),
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            '문제 하나의 원문만 남기고, 정답과 유형 표식을 확인해 주세요.',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '문제 원문',
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14.5,
                        height: 1.55,
                      ),
                      decoration: InputDecoration(
                        hintText: '정답이나 유형 표식을 포함한 문제 원문을 입력해 주세요.',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFFCFDFE),
                        contentPadding: const EdgeInsets.all(18),
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
                          borderSide: const BorderSide(
                            color: _teal,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(92, 46),
                          foregroundColor: const Color(0xFF475569),
                        ),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(
                          dialogContext,
                          controller.text,
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(156, 46),
                          backgroundColor: _teal,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('수정 내용 적용'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    controller.dispose();
    if (updatedRaw == null || updatedRaw.trim().isEmpty || !mounted) return;

    final parsed = parseWorkbookImportTextDetailed(
      updatedRaw,
      workbookSource: _sourceText,
    );
    if (parsed.omittedCount > 0) {
      _message('도표 생략 자료는 문제 후보로 저장할 수 없습니다.');
      return;
    }
    if (parsed.candidates.length != 1) {
      _message('후보 하나의 원문만 입력해 주세요. 현재 ${parsed.candidates.length}개가 감지되었습니다.');
      return;
    }

    final replacement =
        parsed.candidates.single.copyWith(localId: item.localId);
    final duplicate = widget.workbook.questions.any(
      (question) => _isDuplicateCandidate(replacement, question),
    );
    final index =
        _candidates.indexWhere((entry) => entry.localId == item.localId);
    if (index < 0) return;
    setState(() {
      final updated = [..._candidates]..[index] = replacement;
      _candidates = updated;
      duplicate
          ? _duplicateCandidates.add(item.localId)
          : _duplicateCandidates.remove(item.localId);
      if (replacement.isSelectedByDefault && !duplicate) {
        _selected.add(item.localId);
      } else {
        _selected.remove(item.localId);
      }
    });
    _message('후보를 다시 분석했습니다.');
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _scrollToFirst(
    bool Function(WorkbookImportCandidate) matches,
  ) async {
    WorkbookImportCandidate? target;
    for (final item in _candidates) {
      if (matches(item)) {
        target = item;
        break;
      }
    }
    if (target == null) {
      _message('해당 후보가 없습니다.');
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final targetContext = _candidateKeys[target.localId]?.currentContext;
    if (targetContext == null) {
      _message('후보 위치를 준비 중입니다. 잠시 후 다시 눌러 주세요.');
      return;
    }
    if (!targetContext.mounted) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('문제 묶음 가져오기'),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _introCard(),
                const SizedBox(height: 14),
                _inputCard(),
                if (_analyzed) ...[
                  const SizedBox(height: 18),
                  _resultHeader(),
                  const SizedBox(height: 10),
                  _selectionControls(),
                  if (_removedPreamble || _omittedCount > 0) ...[
                    const SizedBox(height: 10),
                    _analysisNotice(),
                  ],
                  const SizedBox(height: 10),
                  if (_candidates.isEmpty)
                    _emptyCard()
                  else
                    ..._candidates.map(_candidateCard),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _analyzed ? _saveBar() : null,
    );
  }

  Widget _introCard() => _card(
        child: ListTile(
          leading: const Icon(Icons.content_paste_go_rounded, color: _teal),
          title: const Text('한글파일이나 워드 자료에서 문제를 복사해 붙여넣으세요.'),
          subtitle: Text(
            '분석 후 저장할 문제만 선택합니다.\n워크북 출처: '
            '${_sourceText.isEmpty ? '등록된 출처 없음' : _sourceText}',
          ),
        ),
      );

  Widget _inputCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickingHwpx ? null : _pickHwpx,
                  icon: _pickingHwpx
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(_pickingHwpx ? '텍스트 추출 중...' : 'HWPX 파일 선택'),
                ),
                if (_pickedHwpxName != null)
                  Text(
                    _pickedHwpxName!,
                    style: const TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'HWPX에서 텍스트만 추출합니다. 원본 파일은 서버에 업로드하지 않습니다.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 14,
              maxLines: 24,
              decoration: const InputDecoration(
                hintText: '한글파일에서 복사한 문제 묶음을 붙여넣어 주세요.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _analyze,
                icon: const Icon(Icons.manage_search_rounded),
                label: const Text('분석하기'),
              ),
            ),
          ],
        ),
      );

  Widget _resultHeader() => Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '문제 후보 ${_candidates.length}개',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          _summaryChip('선택 ${_selected.length}개', _teal),
          _summaryChip(
            '중복 의심 ${_duplicateCandidates.length}개',
            const Color(0xFFB45309),
            muted: _duplicateCandidates.isEmpty,
            onTap: () => _scrollToFirst(
              _isDuplicateItem,
            ),
          ),
          _summaryChip(
            '경고 $_warningCount개',
            const Color(0xFFDC2626),
            muted: _warningCount == 0,
            onTap: () => _scrollToFirst(
              (item) => item.errors.isNotEmpty || item.warnings.isNotEmpty,
            ),
          ),
          _summaryChip(
            'unknown $_unknownCount개',
            const Color(0xFF64748B),
            muted: _unknownCount == 0,
            onTap: () => _scrollToFirst((item) => item.isUnknown),
          ),
          if (_omittedCount > 0)
            _summaryChip('생략 $_omittedCount개', const Color(0xFF475569)),
        ],
      );

  Widget _selectionControls() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 2),
              child: Text(
                '선택 도구',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _selectionButton(
              icon: Icons.select_all_rounded,
              label: '전체 선택',
              onPressed: () => _selectCandidates((_) => true),
            ),
            _selectionButton(
              icon: Icons.deselect_rounded,
              label: '전체 선택 해제',
              onPressed: () => setState(_selected.clear),
            ),
            _selectionButton(
              icon: Icons.verified_outlined,
              label: '정상 후보만 선택',
              onPressed: () => _selectCandidates(_isNormalCandidate),
            ),
            _selectionButton(
              icon: Icons.filter_alt_off_outlined,
              label: '중복 의심 제외',
              onPressed: () => _selectCandidates(
                (item) => !_isDuplicateItem(item),
              ),
            ),
            _selectionButton(
              icon: Icons.warning_amber_rounded,
              label: '경고/unknown 제외',
              onPressed: () => _selectCandidates(
                (item) => item.warnings.isEmpty && item.errors.isEmpty,
              ),
            ),
          ],
        ),
      );

  Widget _selectionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _teal,
        side: const BorderSide(color: Color(0xFF99D5CF)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _summaryChip(
    String text,
    Color color, {
    VoidCallback? onTap,
    bool muted = false,
  }) {
    return MouseRegion(
      cursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: Opacity(
        opacity: muted ? 0.55 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Text(
                text,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _candidateStatusChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
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

  Widget _analysisNotice() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: Text(
          [
            if (_removedPreamble) '문제 시작 전 설명문을 제외했습니다.',
            if (_omittedCount > 0) '도표 생략 자료 $_omittedCount개를 저장 대상에서 제외했습니다.',
          ].join('\n'),
          style: const TextStyle(color: Color(0xFF475569), height: 1.4),
        ),
      );

  Widget _candidateCard(WorkbookImportCandidate item) {
    final selected = _selected.contains(item.localId);
    final hasWarning = item.errors.isNotEmpty || item.warnings.isNotEmpty;
    final isDuplicate = _isDuplicateItem(item);
    final color = item.isUnknown
        ? const Color(0xFFBE123C)
        : hasWarning
            ? const Color(0xFFA16207)
            : isDuplicate
                ? const Color(0xFFC2410C)
                : selected
                    ? const Color(0xFF7C6BB0)
                    : _teal;
    final background = item.isUnknown
        ? const Color(0xFFFFF1F2)
        : hasWarning
            ? const Color(0xFFFFFBEB)
            : isDuplicate
                ? const Color(0xFFFFF7ED)
                : selected
                    ? const Color(0xFFFBFAFF)
                    : Colors.white;
    return Container(
      key: _candidateKeys[item.localId],
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        color: background,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected || isDuplicate || hasWarning || item.isUnknown
                ? color.withValues(alpha: 0.55)
                : const Color(0xFFDDE7F0),
          ),
        ),
        child: Column(
          children: [
            CheckboxListTile(
              value: selected,
              activeColor: const Color(0xFF7C6BB0),
              onChanged: item.isUnknown
                  ? null
                  : (value) => setState(() {
                        value == true
                            ? _selected.add(item.localId)
                            : _selected.remove(item.localId);
                      }),
              title: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${item.typeLabel} · ${item.title}',
                    style: TextStyle(
                      color: item.isUnknown || hasWarning ? color : _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!isDuplicate && !hasWarning && !item.isUnknown)
                    _candidateStatusChip('정상', _teal),
                  if (isDuplicate) _candidateStatusChip('중복 의심', color),
                  if (hasWarning && !item.isUnknown)
                    _candidateStatusChip('검토 필요', color),
                  if (item.isUnknown) _candidateStatusChip('유형 미확인', color),
                ],
              ),
              subtitle: Text(
                item.summary,
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            ),
            if (isDuplicate)
              _messageLine(
                '이미 비슷한 문제가 이 워크북에 있습니다.',
                const Color(0xFFB45309),
              ),
            for (final error in item.errors)
              _messageLine(error, const Color(0xFFC2410C)),
            for (final warning in item.warnings)
              _messageLine(warning, const Color(0xFFA16207)),
            if (item.isUnknown)
              _messageLine(
                '유형 표식이나 정답 형식을 원문에 추가한 뒤 다시 분석해 주세요.',
                const Color(0xFFBE123C),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _editCandidateRaw(item),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(item.isUnknown ? '원문 수정 후 다시 분석' : '수정'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: item.isUnknown || hasWarning
                        ? color
                        : const Color(0xFF334155),
                    side: BorderSide(
                      color: (item.isUnknown || hasWarning
                              ? color
                              : const Color(0xFF94A3B8))
                          .withValues(alpha: 0.55),
                    ),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            ExpansionTile(
              leading: const Icon(
                Icons.subject_rounded,
                color: Color(0xFF64748B),
              ),
              title: const Text(
                '원문 보기',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text('추출된 문제 원문을 확인합니다.'),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              collapsedBackgroundColor: Colors.transparent,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFDFE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE7F0)),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: SingleChildScrollView(
                      primary: false,
                      child: SelectableText(
                        item.rawText,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 14.5,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageLine(String text, Color color) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 7),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      );

  Widget _emptyCard() => _card(
        child: const Text('문제 후보를 찾지 못했습니다. 유형 태그를 확인해 주세요.'),
      );

  Widget _saveBar() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: FilledButton.icon(
            onPressed: _selected.isEmpty || _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_alt_rounded),
            label: Text(
              _saving ? '저장 중...' : '선택한 문제 ${_selected.length}개 저장',
            ),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
        ),
        child: child,
      );
}

String _join(List<String?> values) {
  final parts = <String>[];
  for (final value in values) {
    final text = value?.trim() ?? '';
    if (text.isNotEmpty && !parts.contains(text)) parts.add(text);
  }
  return parts.join(' · ');
}

_ImportSectionInfo _sectionInfoForCandidate(WorkbookImportCandidate item) {
  final title = item.title.trim();
  final unitMatch =
      RegExp(r'Unit\s*(\d+)', caseSensitive: false).firstMatch(title);
  if (unitMatch != null) {
    final unitNo = unitMatch.group(1)!;
    return _ImportSectionInfo(key: 'unit_$unitNo', title: '$unitNo강');
  }
  if (RegExp(r'\bTest\s*\d*', caseSensitive: false).hasMatch(title)) {
    return const _ImportSectionInfo(key: 'test', title: 'Test');
  }
  return const _ImportSectionInfo(key: 'unclassified', title: '미분류');
}

class _ImportSectionInfo {
  const _ImportSectionInfo({required this.key, required this.title});

  final String key;
  final String title;
}

bool _isDuplicateCandidate(
  WorkbookImportCandidate candidate,
  WorkbookQuestion question,
) {
  if (candidate.questionType != question.questionType) return false;

  final candidateText = _normalizeDuplicateText(
    (candidate.passageText ?? '').isNotEmpty
        ? candidate.passageText!
        : candidate.prompt,
  );
  final questionText = _normalizeDuplicateText(
    (question.passageText ?? '').isNotEmpty
        ? question.passageText!
        : question.prompt,
  );
  if (_samePrefix(candidateText, questionText)) return true;

  final candidateAnswer = _normalizeDuplicateText(candidate.answer.toString());
  final questionAnswer = _normalizeDuplicateText(question.answer.toString());
  if (_samePrefix(candidateAnswer, questionAnswer, minimumLength: 30)) {
    return true;
  }

  final existingTitle = _normalizeDuplicateText(
    (question.answer['unit_title'] ?? '').toString(),
  );
  final candidateTitle = _normalizeDuplicateText(candidate.title);
  return candidateTitle.length >= 6 && candidateTitle == existingTitle;
}

bool _samePrefix(
  String left,
  String right, {
  int minimumLength = 24,
}) {
  if (left.length < minimumLength || right.length < minimumLength) {
    return false;
  }
  final length = [left.length, right.length, 110].reduce(
    (value, item) => value < item ? value : item,
  );
  return left.substring(0, length) == right.substring(0, length);
}

String _normalizeDuplicateText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9가-힣]+'), '').trim();
}
