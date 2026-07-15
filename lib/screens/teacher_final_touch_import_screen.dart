import 'package:flutter/material.dart';

import '../models/final_touch_import_draft.dart';
import '../services/final_touch_import_file_picker.dart';
import '../services/final_touch_service.dart';
import '../utils/final_touch_import_parser.dart';
import '../utils/workbook_hwpx_text_extractor.dart';
import '../widgets/bracket_colored_text.dart';

@visibleForTesting
String finalTouchImportPreviewTitle(FinalTouchImportDraft draft) {
  return draft.displayLabel;
}

@visibleForTesting
String finalTouchImportDestinationLabel(String? folderName) {
  final name = folderName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return '미분류';
}

class TeacherFinalTouchImportScreen extends StatefulWidget {
  const TeacherFinalTouchImportScreen({
    super.key,
    this.folderId,
    this.folderName,
    this.textbookFolderName,
    this.unitFolderName,
  });

  final int? folderId;
  final String? folderName;
  final String? textbookFolderName;
  final String? unitFolderName;

  @override
  State<TeacherFinalTouchImportScreen> createState() =>
      _TeacherFinalTouchImportScreenState();
}

class _TeacherFinalTouchImportScreenState
    extends State<TeacherFinalTouchImportScreen> {
  final _service = const FinalTouchService();
  final Set<int> _selectedIndexes = {};
  final List<String> _globalWarnings = [];
  late final TextEditingController _textbookFolderController;
  late final TextEditingController _unitFolderController;
  List<FinalTouchImportDraft> _drafts = [];
  String? _fileName;
  String? _error;
  bool _reading = false;
  bool _saving = false;

  String get _textbookFolderName => _textbookFolderController.text.trim();
  String get _unitFolderName => _unitFolderController.text.trim();
  String get _destinationLabel {
    if (_unitFolderName.isNotEmpty && _textbookFolderName.isNotEmpty) {
      return '$_textbookFolderName > $_unitFolderName';
    }
    if (_unitFolderName.isNotEmpty) return _unitFolderName;
    if (_textbookFolderName.isNotEmpty) return _textbookFolderName;
    return finalTouchImportDestinationLabel(widget.folderName);
  }

  @override
  void initState() {
    super.initState();
    _textbookFolderController = TextEditingController(
      text: (widget.textbookFolderName?.trim().isNotEmpty ?? false)
          ? widget.textbookFolderName!.trim()
          : widget.folderName?.trim() ?? '',
    );
    _unitFolderController = TextEditingController(
      text: widget.unitFolderName?.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _textbookFolderController.dispose();
    _unitFolderController.dispose();
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
      if (file.bytes.length > 30 * 1024 * 1024) {
        throw const FormatException('30MB 이하의 HWPX 파일을 선택해 주세요.');
      }
      final extracted = extractWorkbookTextFromHwpx(file.bytes);
      final result = parseFinalTouchImportDrafts(extracted.text);
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _drafts = result.drafts;
        _globalWarnings
          ..clear()
          ..addAll(result.globalWarnings);
        _selectedIndexes
          ..clear()
          ..addAll(
            result.drafts
                .where((draft) => draft.canSave)
                .map((draft) => draft.index),
          );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _drafts = [];
        _globalWarnings.clear();
        _selectedIndexes.clear();
        _error = error is FormatException ? error.message : '$error';
      });
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _save() async {
    final selected = _drafts
        .where(
            (draft) => draft.canSave && _selectedIndexes.contains(draft.index))
        .toList();
    if (selected.isEmpty || _saving) return;
    setState(() => _saving = true);
    final succeeded = <String>[];
    final failed = <String>[];
    try {
      for (final draft in selected) {
        try {
          await _service.createFromImport(
            draft,
            folderId: widget.folderId,
            textbookFolderName:
                _textbookFolderName.isEmpty ? null : _textbookFolderName,
            unitFolderName: _unitFolderName.isEmpty ? null : _unitFolderName,
            folderName: _destinationLabel == '미분류' ? null : _destinationLabel,
          );
          succeeded.add(draft.displayLabel);
        } catch (error) {
          failed.add('${draft.displayLabel}: $error');
        }
      }
      if (!mounted) return;
      if (succeeded.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${succeeded.length}개 자료를 Final Touch에 저장했습니다. '
              '저장 위치: $_destinationLabel',
            ),
          ),
        );
      }
      final close = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('저장 결과'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${succeeded.length}개 성공 · ${failed.length}개 실패',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '저장 위치: $_destinationLabel',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Teacher Final Touch 모음에서 확인할 수 있습니다.'),
                const SizedBox(height: 12),
                for (final label in succeeded)
                  Text(
                    '✓ $label 저장',
                    style: const TextStyle(color: Color(0xFF047857)),
                  ),
                for (final message in failed)
                  Text(
                    '• $message',
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('계속 확인'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('목록으로'),
            ),
          ],
        ),
      );
      if (close == true && mounted) Navigator.pop(context, succeeded.length);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editDraft(FinalTouchImportDraft draft) async {
    final edited = await showDialog<FinalTouchImportDraft>(
      context: context,
      builder: (context) => _DraftEditDialog(draft: draft),
    );
    if (edited == null || !mounted) return;
    setState(() {
      final index = _drafts.indexWhere((item) => item.index == draft.index);
      if (index >= 0) _drafts[index] = edited;
      if (!edited.canSave) {
        _selectedIndexes.remove(edited.index);
      }
    });
  }

  void _selectAllSaveable() {
    setState(() {
      _selectedIndexes
        ..clear()
        ..addAll(_drafts
            .where((draft) => draft.canSave)
            .map((draft) => draft.index));
    });
  }

  void _clearSelection() {
    setState(_selectedIndexes.clear);
  }

  @override
  Widget build(BuildContext context) {
    final saveableCount = _drafts.where((draft) => draft.canSave).length;
    final warningCount = _drafts.fold<int>(
        0, (sum, draft) => sum + _draftWarnings(draft).length);
    final selectedCount = _drafts
        .where(
            (draft) => draft.canSave && _selectedIndexes.contains(draft.index))
        .length;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text(
          'Final Touch HWPX 가져오기',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _ImportCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HWPX 분석지를 Final Touch 자료로 가져옵니다.',
                  style: TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '파일은 브라우저에서만 읽고, 파싱 후보를 저장 전에 확인·수정할 수 있습니다.',
                  style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 10),
                const Text(
                  '구형 HWP는 한글 프로그램에서 HWPX 형식으로 다시 저장한 뒤 선택해 주세요.',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _ImportDestinationFields(
                  textbookController: _textbookFolderController,
                  unitController: _unitFolderController,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                _DestinationBanner(label: _destinationLabel),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _reading ? null : _pickFile,
                  icon: _reading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(_reading ? '파일 읽는 중...' : 'HWPX 파일 선택'),
                ),
                if (_fileName != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '선택 파일: $_fileName',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_drafts.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ImportCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '파싱 미리보기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '후보 ${_drafts.length}개',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '저장 가능 $saveableCount개 · 경고 $warningCount개 · 선택 $selectedCount개',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  if (_globalWarnings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final warning in _globalWarnings)
                      Text(
                        '• $warning',
                        style: const TextStyle(color: Color(0xFFB45309)),
                      ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed:
                            saveableCount == 0 ? null : _selectAllSaveable,
                        icon: const Icon(Icons.done_all_rounded),
                        label: const Text('저장 가능한 후보만 선택'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _drafts.isEmpty ? null : _clearSelection,
                        icon: const Icon(Icons.remove_done_rounded),
                        label: const Text('전체 해제'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            for (final draft in _drafts) ...[
              const SizedBox(height: 14),
              _DraftPreviewCard(
                draft: draft,
                selected: _selectedIndexes.contains(draft.index),
                warnings: _draftWarnings(draft),
                onEdit: () => _editDraft(draft),
                onSelected: draft.canSave
                    ? (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedIndexes.add(draft.index);
                          } else {
                            _selectedIndexes.remove(draft.index);
                          }
                        });
                      }
                    : null,
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: selectedCount > 0 && !_saving ? _save : null,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _saving ? '저장 중...' : '선택한 $selectedCount개 Final Touch로 저장',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DraftPreviewCard extends StatelessWidget {
  const _DraftPreviewCard({
    required this.draft,
    required this.selected,
    required this.warnings,
    required this.onEdit,
    required this.onSelected,
  });

  final FinalTouchImportDraft draft;
  final bool selected;
  final List<String> warnings;
  final VoidCallback onEdit;
  final ValueChanged<bool?>? onSelected;

  @override
  Widget build(BuildContext context) {
    return _ImportCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Checkbox(value: selected, onChanged: onSelected),
        title: Text(
          finalTouchImportPreviewTitle(draft),
          style: const TextStyle(
            color: Color(0xFF172033),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoPill(text: '영어 ${draft.englishSentenceCount}문장'),
              _InfoPill(
                text: '해석 ${draft.translationSentenceCount}문장',
                warning: draft.translationSentenceCount <
                    draft.englishSentenceCount.clamp(1, 999),
              ),
              _InfoPill(
                  text: _hasText(draft.title) ? '제목 있음' : '제목 없음',
                  warning: !_hasText(draft.title)),
              _InfoPill(
                  text: _hasText(draft.topic) ? '주제 있음' : '주제 없음',
                  warning: !_hasText(draft.topic)),
              _InfoPill(
                  text: _hasText(draft.gist) ? '요지 있음' : '요지 없음',
                  warning: !_hasText(draft.gist)),
              _InfoPill(
                  text: _hasOutline(draft) ? '글의 흐름 있음' : '글의 흐름 없음',
                  warning: !_hasOutline(draft)),
              _InfoPill(
                  text: draft.canSave ? '저장 가능' : '저장 불가',
                  warning: !draft.canSave),
              if (warnings.isNotEmpty)
                _InfoPill(text: '경고 ${warnings.length}', warning: true),
            ],
          ),
        ),
        trailing: TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('상세 수정'),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PreviewField(label: '출처', value: draft.source),
                _PreviewField(label: '제목', value: draft.title),
                _PreviewField(label: '주제', value: draft.topic),
                _PreviewField(label: '요지', value: draft.gist),
                _PreviewField(
                    label: '글의 흐름', value: _outlineText(draft.outline)),
                const Text(
                  '괄호 구조 영어 지문',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const BracketLegend(),
                const SizedBox(height: 10),
                BracketColoredText(
                  text: draft.passageBracketed.isEmpty
                      ? '영어 지문이 없습니다.'
                      : draft.passageBracketed,
                  style: const TextStyle(fontSize: 15, height: 1.7),
                ),
                const SizedBox(height: 16),
                _PreviewField(label: '한글 해석', value: draft.combinedTranslation),
                if (warnings.isNotEmpty) ...[
                  const Text(
                    '확인할 내용',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final warning in warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $warning'),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftEditDialog extends StatefulWidget {
  const _DraftEditDialog({required this.draft});

  final FinalTouchImportDraft draft;

  @override
  State<_DraftEditDialog> createState() => _DraftEditDialogState();
}

class _DraftEditDialogState extends State<_DraftEditDialog> {
  late final TextEditingController _sourceController;
  late final TextEditingController _titleController;
  late final TextEditingController _titleEnController;
  late final TextEditingController _titleKoController;
  late final TextEditingController _topicController;
  late final TextEditingController _topicEnController;
  late final TextEditingController _topicKoController;
  late final TextEditingController _gistController;
  late final TextEditingController _gistEnController;
  late final TextEditingController _gistKoController;
  late final TextEditingController _passageController;
  late final TextEditingController _translationController;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _sourceController = TextEditingController(text: draft.source);
    _titleController = TextEditingController(text: draft.title);
    _titleEnController = TextEditingController(text: draft.titleEn);
    _titleKoController = TextEditingController(text: draft.titleKo);
    _topicController = TextEditingController(text: draft.topic);
    _topicEnController = TextEditingController(text: draft.topicEn);
    _topicKoController = TextEditingController(text: draft.topicKo);
    _gistController = TextEditingController(text: draft.gist);
    _gistEnController = TextEditingController(text: draft.gistEn);
    _gistKoController = TextEditingController(text: draft.gistKo);
    _passageController = TextEditingController(text: draft.passage);
    _translationController =
        TextEditingController(text: draft.combinedTranslation);
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _titleController.dispose();
    _titleEnController.dispose();
    _titleKoController.dispose();
    _topicController.dispose();
    _topicEnController.dispose();
    _topicKoController.dispose();
    _gistController.dispose();
    _gistEnController.dispose();
    _gistKoController.dispose();
    _passageController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final englishCount = _countEnglishSentences(_passageController.text);
    final translationCount =
        _countTranslationSentences(_translationController.text);
    final matchText = englishCount == translationCount
        ? '문장 수가 일치합니다.'
        : '영어 $englishCount문장 / 해석 $translationCount문장 — 저장은 가능하지만 문장별 해석이 일부 비어 있을 수 있습니다.';

    return AlertDialog(
      title: const Text('저장 전 상세 수정'),
      content: SizedBox(
        width: 980,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EditField(label: '출처', controller: _sourceController),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 760;
                  final titleFields = [
                    _EditField(label: '제목', controller: _titleController),
                    _EditField(label: '제목 EN', controller: _titleEnController),
                    _EditField(label: '제목 KO', controller: _titleKoController),
                  ];
                  final topicFields = [
                    _EditField(label: '주제', controller: _topicController),
                    _EditField(label: '주제 EN', controller: _topicEnController),
                    _EditField(label: '주제 KO', controller: _topicKoController),
                  ];
                  final gistFields = [
                    _EditField(label: '요지', controller: _gistController),
                    _EditField(label: '요지 EN', controller: _gistEnController),
                    _EditField(label: '요지 KO', controller: _gistKoController),
                  ];
                  if (stacked) {
                    return Column(children: [
                      ...titleFields,
                      ...topicFields,
                      ...gistFields
                    ]);
                  }
                  return Column(
                    children: [
                      Row(children: _expandedFields(titleFields)),
                      Row(children: _expandedFields(topicFields)),
                      Row(children: _expandedFields(gistFields)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              _SentenceCountBanner(
                text: matchText,
                warning: englishCount != translationCount,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 760;
                  final english = _EditField(
                    label: '영어 지문',
                    controller: _passageController,
                    maxLines: 16,
                    onChanged: (_) => setState(() {}),
                  );
                  final korean = _EditField(
                    label: '한글 해석',
                    controller: _translationController,
                    maxLines: 16,
                    onChanged: (_) => setState(() {}),
                  );
                  if (stacked) {
                    return Column(children: [english, korean]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: english),
                      const SizedBox(width: 12),
                      Expanded(child: korean),
                    ],
                  );
                },
              ),
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
            final translationLines =
                _splitEditedTranslation(_translationController.text);
            final updatedDetails = _applyEditedTranslations(
              widget.draft.sentenceDetails,
              translationLines,
            );
            final passage = _passageController.text.trim();
            Navigator.pop(
              context,
              widget.draft.copyWith(
                source: _sourceController.text.trim(),
                title: _titleController.text.trim(),
                titleEn: _titleEnController.text.trim(),
                titleKo: _titleKoController.text.trim(),
                topic: _topicController.text.trim(),
                topicEn: _topicEnController.text.trim(),
                topicKo: _topicKoController.text.trim(),
                gist: _gistController.text.trim(),
                gistEn: _gistEnController.text.trim(),
                gistKo: _gistKoController.text.trim(),
                passage: passage,
                passageBracketed: passage,
                translationText: _translationController.text.trim(),
                sentenceDetails: updatedDetails,
              ),
            );
          },
          child: const Text('수정 반영'),
        ),
      ],
    );
  }
}

class _DestinationBanner extends StatelessWidget {
  const _DestinationBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_rounded, color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '저장 위치: $label',
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportDestinationFields extends StatelessWidget {
  const _ImportDestinationFields({
    required this.textbookController,
    required this.unitController,
    required this.onChanged,
  });

  final TextEditingController textbookController;
  final TextEditingController unitController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 680;
        final textbook = TextField(
          controller: textbookController,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: '교재 폴더 / 출처',
            hintText: '예: 수능특강 영어',
            prefixIcon: const Icon(Icons.folder_copy_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        );
        final unit = TextField(
          controller: unitController,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: '단원/강 폴더 선택',
            hintText: '예: Unit 1',
            prefixIcon: const Icon(Icons.bookmark_border_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        );

        if (stacked) {
          return Column(
            children: [
              textbook,
              const SizedBox(height: 10),
              unit,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: textbook),
            const SizedBox(width: 12),
            Expanded(child: unit),
          ],
        );
      },
    );
  }
}

class _ImportCard extends StatelessWidget {
  const _ImportCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4EE)),
      ),
      child: child,
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xFFB45309) : const Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PreviewField extends StatelessWidget {
  const _PreviewField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '없음' : value,
            style: const TextStyle(color: Color(0xFF25324A), height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class _SentenceCountBanner extends StatelessWidget {
  const _SentenceCountBanner({required this.text, required this.warning});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xFFB45309) : const Color(0xFF047857);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

List<Widget> _expandedFields(List<Widget> fields) {
  return [
    for (var i = 0; i < fields.length; i++) ...[
      Expanded(child: fields[i]),
      if (i != fields.length - 1) const SizedBox(width: 10),
    ],
  ];
}

List<String> _draftWarnings(FinalTouchImportDraft draft) {
  final warnings = <String>[...draft.warnings];
  if (!draft.canSave) warnings.add('영어 지문이 없어 저장할 수 없습니다.');
  if (!_hasText(draft.source)) warnings.add('출처가 비어 있습니다.');
  if (!_hasText(draft.title) &&
      !_hasText(draft.titleEn) &&
      !_hasText(draft.titleKo)) {
    warnings.add('제목이 비어 있습니다.');
  }
  if (!_hasText(draft.topic) &&
      !_hasText(draft.topicEn) &&
      !_hasText(draft.topicKo)) {
    warnings.add('주제가 비어 있습니다.');
  }
  if (!_hasText(draft.gist) &&
      !_hasText(draft.gistEn) &&
      !_hasText(draft.gistKo)) {
    warnings.add('요지가 비어 있습니다.');
  }
  if (!_hasOutline(draft)) warnings.add('글의 흐름이 비어 있습니다.');
  if (draft.englishSentenceCount <= 1) warnings.add('영어 지문이 너무 짧을 수 있습니다.');
  if (draft.translationSentenceCount < draft.englishSentenceCount) {
    warnings.add('해석 문장 수가 영어 문장 수보다 적습니다.');
  }
  return warnings.toSet().toList();
}

bool _hasText(String value) => value.trim().isNotEmpty;

bool _hasOutline(FinalTouchImportDraft draft) {
  return (draft.outline['intro'] ?? '').trim().isNotEmpty ||
      (draft.outline['body'] ?? '').trim().isNotEmpty ||
      (draft.outline['conclusion'] ?? '').trim().isNotEmpty;
}

String _outlineText(Map<String, String> outline) {
  return [
    '서론: ${outline['intro'] ?? ''}',
    '본론: ${outline['body'] ?? ''}',
    '결론: ${outline['conclusion'] ?? ''}',
  ].join('\n');
}

int _countEnglishSentences(String text) {
  final lines = text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(line))
      .length;
  if (lines > 0) return lines;
  return RegExp(r'[^.!?]+[.!?]').allMatches(text).length;
}

int _countTranslationSentences(String text) {
  final lines = _splitEditedTranslation(text);
  return lines.length;
}

List<String> _splitEditedTranslation(String text) {
  final lines = text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.length > 1) return lines;
  final compact = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (compact.isEmpty) return const [];
  final parts = RegExp(r'[^.!?。！？]+[.!?。！？]?')
      .allMatches(compact)
      .map((match) => match.group(0)?.trim() ?? '')
      .where((part) => part.isNotEmpty)
      .toList();
  return parts.isEmpty ? [compact] : parts;
}

List<Map<String, dynamic>> _applyEditedTranslations(
  List<Map<String, dynamic>> details,
  List<String> translations,
) {
  if (details.isEmpty) {
    return [
      for (var i = 0; i < translations.length; i++)
        {
          'sentence_no': i + 1,
          'original': '',
          'bracketed': '',
          'translation': translations[i],
          'translation_bracketed': translations[i],
        },
    ];
  }
  return [
    for (var i = 0; i < details.length; i++)
      {
        ...details[i],
        if (i < translations.length) 'translation': translations[i],
        if (i < translations.length) 'translation_bracketed': translations[i],
      },
  ];
}
