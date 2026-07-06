import 'package:flutter/material.dart';

import '../models/final_touch_import_draft.dart';
import '../services/final_touch_import_file_picker.dart';
import '../services/final_touch_service.dart';
import '../utils/final_touch_import_parser.dart';
import '../utils/workbook_hwpx_text_extractor.dart';
import '../widgets/bracket_colored_text.dart';

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
  FinalTouchImportDraft? _draft;
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
      final draft = parseFinalTouchImportText(extracted.text);
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _draft = draft;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _draft = null;
        _error = error is FormatException ? error.message : '$error';
      });
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !draft.canSave || _saving) return;
    setState(() => _saving = true);
    try {
      await _service.createFromImport(draft, folderId: widget.folderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Final Touch 자료를 저장했습니다.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
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
          if (draft != null) ...[
            const SizedBox(height: 14),
            _ImportCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '파싱 미리보기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ImportCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '괄호 구조 영어 지문',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const BracketLegend(),
                  const SizedBox(height: 12),
                  BracketColoredText(
                    text: draft.passageBracketed,
                    style: const TextStyle(fontSize: 15, height: 1.7),
                  ),
                  const SizedBox(height: 16),
                  _PreviewField(
                    label: '한글 해석',
                    value: draft.sentenceDetails
                        .map((item) => item['translation'])
                        .where((value) => '$value'.trim().isNotEmpty)
                        .join('\n\n'),
                  ),
                ],
              ),
            ),
            if (draft.warnings.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ImportCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '확인할 내용',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final warning in draft.warnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text('• $warning'),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: draft.canSave && !_saving ? _save : null,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? '저장 중...' : 'Final Touch로 저장'),
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
