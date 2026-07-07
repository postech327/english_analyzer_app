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

class TeacherFinalTouchImportScreen extends StatefulWidget {
  const TeacherFinalTouchImportScreen({super.key, this.folderId});

  final int? folderId;

  @override
  State<TeacherFinalTouchImportScreen> createState() =>
      _TeacherFinalTouchImportScreenState();
}

class _TeacherFinalTouchImportScreenState
    extends State<TeacherFinalTouchImportScreen> {
  final _service = const FinalTouchService();
  FinalTouchImportResult? _result;
  final Set<int> _selectedIndexes = {};
  String? _fileName;
  String? _error;
  bool _reading = false;
  bool _saving = false;

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
        throw const FormatException('구형 HWP 파일은 HWPX로 변환 후 사용해 주세요.');
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
        _result = result;
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
        _result = null;
        _selectedIndexes.clear();
        _error = error is FormatException ? error.message : '$error';
      });
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _save() async {
    final result = _result;
    final selected = result?.drafts
            .where(
              (draft) =>
                  draft.canSave && _selectedIndexes.contains(draft.index),
            )
            .toList() ??
        const <FinalTouchImportDraft>[];
    if (selected.isEmpty || _saving) return;
    setState(() => _saving = true);
    final succeeded = <String>[];
    final failed = <String>[];
    try {
      for (final draft in selected) {
        try {
          await _service.createFromImport(draft, folderId: widget.folderId);
          succeeded.add(draft.displayLabel);
        } catch (error) {
          failed.add('${draft.displayLabel}: $error');
        }
      }
      if (!mounted) return;
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
                const SizedBox(height: 12),
                for (final label in succeeded)
                  Text(
                    '✓ $label 성공',
                    style: const TextStyle(color: Color(0xFF047857)),
                  ),
                for (final message in failed)
                  Text(
                    '✕ $message',
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
      if (close == true && mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final drafts = result?.drafts ?? const <FinalTouchImportDraft>[];
    final saveableCount = drafts.where((draft) => draft.canSave).length;
    final warningCount =
        drafts.fold<int>(0, (sum, draft) => sum + draft.warnings.length);
    final selectedCount = drafts
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
                  '정해진 표제가 있는 HWPX 분석지를 가져옵니다.',
                  style: TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '[출처] [제목] [주제] [요지] [글의 흐름] [영어 지문] [한글 해석]을 인식합니다. 파일은 브라우저에서만 읽습니다.',
                  style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  '구형 HWP는 한글 프로그램에서 다른 이름으로 저장 → HWPX 형식으로 변환한 뒤 선택해 주세요.',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
          if (result != null) ...[
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
                        '후보 ${drafts.length}개',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '저장 가능 $saveableCount개 · 경고 $warningCount개',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: saveableCount > 0 && selectedCount == saveableCount,
                    tristate:
                        selectedCount > 0 && selectedCount < saveableCount,
                    onChanged: saveableCount == 0
                        ? null
                        : (selected) {
                            setState(() {
                              _selectedIndexes.clear();
                              if (selected == true) {
                                _selectedIndexes.addAll(
                                  drafts
                                      .where((draft) => draft.canSave)
                                      .map((draft) => draft.index),
                                );
                              }
                            });
                          },
                    title: const Text(
                      '저장 가능한 후보 전체 선택',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            for (final draft in drafts) ...[
              const SizedBox(height: 14),
              _DraftPreviewCard(
                draft: draft,
                selected: _selectedIndexes.contains(draft.index),
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

class _DraftPreviewCard extends StatelessWidget {
  const _DraftPreviewCard({
    required this.draft,
    required this.selected,
    required this.onSelected,
  });

  final FinalTouchImportDraft draft;
  final bool selected;
  final ValueChanged<bool?>? onSelected;

  @override
  Widget build(BuildContext context) {
    final translations = draft.sentenceDetails
        .map((item) => '${item['translation'] ?? ''}'.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final hasOriginalTranslation = RegExp(
      '(?:\\[\\s*(?:\\uD55C\\uAE00\\s*)?\\uD574\\uC11D\\s*\\]|(?:\\uD55C\\uAE00\\s*)?\\uD574\\uC11D\\s*:)',
      caseSensitive: false,
    ).hasMatch(draft.rawText);
    return _ImportCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Checkbox(
          value: selected,
          onChanged: onSelected,
        ),
        title: Text(
          finalTouchImportPreviewTitle(draft),
          style: const TextStyle(
            color: Color(0xFF172033),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoPill(text: '영어 ${draft.sentenceDetails.length}문장'),
              _InfoPill(text: '해석 ${translations.length}문장'),
              _InfoPill(
                text: hasOriginalTranslation
                    ? '\uC6D0\uBCF8 \uD574\uC11D \uBC18\uC601'
                    : translations.isEmpty
                        ? '\uC6D0\uBCF8 \uD574\uC11D \uC5C6\uC74C - fallback \uC0AC\uC6A9 \uC911'
                        : '\uD574\uC11D \uCD94\uC815 \uBC18\uC601',
                warning: !hasOriginalTranslation,
              ),
              _InfoPill(
                text: draft.canSave ? '저장 가능' : '저장 불가',
                warning: !draft.canSave,
              ),
              if (draft.warnings.isNotEmpty)
                _InfoPill(
                  text: '경고 ${draft.warnings.length}',
                  warning: true,
                ),
            ],
          ),
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
                  label: '글의 흐름',
                  value: [
                    '서론: ${draft.outline['intro']}',
                    '본론: ${draft.outline['body']}',
                    '결론: ${draft.outline['conclusion']}',
                  ].join('\n'),
                ),
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
                _PreviewField(
                  label: '한글 해석',
                  value: translations.join('\n\n'),
                ),
                if (draft.warnings.isNotEmpty) ...[
                  const Text(
                    '확인할 내용',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final warning in draft.warnings)
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
            style: const TextStyle(
              color: Color(0xFF25324A),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
