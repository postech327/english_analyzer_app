import 'package:flutter/material.dart';

import '../services/mock_exam_file_picker.dart';
import '../services/teacher_mock_exam_service.dart';
import 'teacher_mock_exam_delete_dialog.dart';
import 'teacher_mock_exam_report_screen.dart';
import 'teacher_mock_question_edit_screen.dart';

class TeacherMockExamDetailScreen extends StatefulWidget {
  const TeacherMockExamDetailScreen({
    super.key,
    required this.mockExamId,
  });

  final int mockExamId;

  @override
  State<TeacherMockExamDetailScreen> createState() =>
      _TeacherMockExamDetailScreenState();
}

class _TeacherMockExamDetailScreenState
    extends State<TeacherMockExamDetailScreen> {
  static const _ink = Color(0xFF172033);
  static const _surface = Color(0xFFF4F7FB);

  bool _loading = false;
  bool _uploading = false;
  String? _error;
  Map<String, dynamic>? _exam;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final exam =
          await TeacherMockExamService.fetchMockExamDetail(widget.mockExamId);
      if (!mounted) return;
      setState(() => _exam = exam);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    final picked = await pickMockExamUploadFile();
    if (picked == null) return;

    final lower = picked.name.toLowerCase();
    if (!(lower.endsWith('.xlsx') ||
        lower.endsWith('.xlsm') ||
        lower.endsWith('.csv'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('xlsx, xlsm, csv 파일만 업로드할 수 있습니다.')),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      await TeacherMockExamService.uploadQuestions(
        mockExamId: widget.mockExamId,
        filename: picked.name,
        bytes: picked.bytes,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('20문항 업로드가 완료되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _openQuestion(Map<String, dynamic> question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherMockQuestionEditScreen(
          mockExamId: widget.mockExamId,
          question: question,
        ),
      ),
    ).then((changed) {
      if (changed == true) _load();
    });
  }

  Future<void> _deleteExam() async {
    final exam = _exam;
    if (exam == null) return;

    final ok = await showTeacherMockExamDeleteDialog(
      context: context,
      title: _asText(exam['title'], '제목 없음'),
    );
    if (ok != true) return;

    try {
      await TeacherMockExamService.deleteMockExam(widget.mockExamId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모의고사가 삭제되었습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = _exam;
    final questions = exam == null
        ? <dynamic>[]
        : (exam['questions'] as List? ?? const <dynamic>[]);

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          '모의고사 상세',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: '다시 불러오기',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: '모의고사 삭제',
            onPressed: _exam == null ? null : _deleteExam,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: _loading && exam == null
                ? const SizedBox(
                    height: 420,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null && exam == null
                    ? _MessagePanel(
                        title: '상세 정보를 불러오지 못했습니다.',
                        message: _error!,
                        onTap: _load,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ExamHeader(
                            exam: exam ?? const {},
                            uploading: _uploading,
                            onUpload: _upload,
                            onReport: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeacherMockExamReportScreen(
                                  mockExamId: widget.mockExamId,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _QuestionListCard(
                            questions: questions,
                            onTap: _openQuestion,
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

class _ExamHeader extends StatelessWidget {
  const _ExamHeader({
    required this.exam,
    required this.uploading,
    required this.onUpload,
    required this.onReport,
  });

  final Map<String, dynamic> exam;
  final bool uploading;
  final VoidCallback onUpload;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final count = _asInt(exam['question_count']);
    final total = _asInt(exam['total_questions'], 20);
    final complete = exam['is_complete'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusBadge(complete: complete),
                  const SizedBox(width: 8),
                  _MetaBadge(label: '$count/$total문항'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _asText(exam['title'], '제목 없음'),
                style: const TextStyle(
                  color: _MockDetailColors.ink,
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_asText(exam['grade'])} · ${_asInt(exam['year'])}년 ${_asInt(exam['month'])}월',
                style: const TextStyle(
                  color: _MockDetailColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: uploading ? null : onUpload,
                icon: uploading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(uploading ? '업로드 중' : 'Excel/XLSX 업로드'),
              ),
              OutlinedButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('응시 결과'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('목록으로'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 16),
                actions,
                const SizedBox(height: 14),
                const _UploadGuide(),
              ],
            );
          }

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 18),
                  actions,
                ],
              ),
              const SizedBox(height: 14),
              const _UploadGuide(),
            ],
          );
        },
      ),
    );
  }
}

class _UploadGuide extends StatelessWidget {
  const _UploadGuide();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _MockDetailColors.line),
      ),
      child: const Text(
        '업로드 엑셀 필수 컬럼: number, question_type, question_text, option_1, option_2, option_3, option_4, option_5, answer\n'
        '선택 컬럼: source, passage, explanation, passage_group\n'
        '한글 컬럼도 가능합니다: 번호, 유형, 문제, 선택지1~5, 정답, 해설',
        style: TextStyle(
          color: _MockDetailColors.muted,
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuestionListCard extends StatelessWidget {
  const _QuestionListCard({
    required this.questions,
    required this.onTap,
  });

  final List<dynamic> questions;
  final ValueChanged<Map<String, dynamic>> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '문항 목록',
                style: TextStyle(
                  color: _MockDetailColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Spacer(),
              Text(
                '문항을 클릭하면 상세/수정 화면이 열립니다.',
                style: TextStyle(
                  color: _MockDetailColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (questions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _MockDetailColors.line),
              ),
              child: const Text(
                '아직 등록된 문항이 없습니다. Excel/XLSX 업로드로 20문항을 등록하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _MockDetailColors.muted),
              ),
            )
          else
            Column(
              children: questions.map((item) {
                final question = item as Map<String, dynamic>;
                return _QuestionTile(
                  question: question,
                  onTap: () => onTap(question),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.question,
    required this.onTap,
  });

  final Map<String, dynamic> question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _MockDetailColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_asInt(question['number'])}',
                style: const TextStyle(
                  color: _MockDetailColors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${_asInt(question['number'])}번 ${_asText(question['type_label'], _asText(question['question_type']))}',
                        style: const TextStyle(
                          color: _MockDetailColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (_asText(question['source']).isNotEmpty)
                        _MetaBadge(label: _asText(question['source'])),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _asText(question['question_text'], '질문 없음')
                        .replaceAll(RegExp(r'<[^>]+>'), ''),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _MockDetailColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: _MockDetailColors.muted),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.complete});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    return _MetaBadge(
      label: complete ? '완료' : '미완성',
      color: complete ? _MockDetailColors.blue : const Color(0xFFC2410C),
      background: complete ? const Color(0xFFEFF6FF) : const Color(0xFFFFF7ED),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.label,
    this.color = _MockDetailColors.muted,
    this.background = const Color(0xFFF8FAFC),
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _MockDetailColors.line),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.message,
    required this.onTap,
  });

  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _MockDetailColors.blue,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: _MockDetailColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _MockDetailColors.muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _MockDetailColors {
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const blue = Color(0xFF2563EB);
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _MockDetailColors.line),
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
