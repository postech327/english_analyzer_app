import 'package:flutter/material.dart';

import '../services/teacher_mock_exam_service.dart';
import 'teacher_mock_exam_delete_dialog.dart';
import 'teacher_mock_exam_detail_screen.dart';
import 'teacher_mock_student_report_list_screen.dart';

class TeacherMockExamListScreen extends StatefulWidget {
  const TeacherMockExamListScreen({super.key});

  @override
  State<TeacherMockExamListScreen> createState() =>
      _TeacherMockExamListScreenState();
}

class _TeacherMockExamListScreenState extends State<TeacherMockExamListScreen> {
  static const _ink = Color(0xFF172033);
  static const _blue = Color(0xFF2563EB);
  static const _surface = Color(0xFFF4F7FB);

  bool _loading = false;
  String? _error;
  List<dynamic> _items = [];
  String? _selectedGrade;
  int? _selectedYear;
  int? _selectedMonth;

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
      final items = await TeacherMockExamService.fetchMockExams();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final created = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _CreateMockExamDialog(),
    );
    if (created == null || !mounted) return;
    setState(() {
      _selectedGrade = _asText(created['grade']);
      _selectedYear = _asInt(created['year']);
      _selectedMonth = _asInt(created['month']);
    });
    await _load();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherMockExamDetailScreen(
          mockExamId: _asInt(created['id']),
        ),
      ),
    ).then((_) => _load());
  }

  void _goBackLevel() {
    if (_selectedMonth != null) {
      setState(() => _selectedMonth = null);
      return;
    }
    if (_selectedYear != null) {
      setState(() => _selectedYear = null);
      return;
    }
    if (_selectedGrade != null) {
      setState(() => _selectedGrade = null);
    }
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherMockExamDetailScreen(
          mockExamId: _asInt(item['id']),
        ),
      ),
    ).then((_) => _load());
  }

  void _openStudentReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TeacherMockStudentReportListScreen(),
      ),
    );
  }

  Future<void> _deleteExam(Map<String, dynamic> item) async {
    final ok = await showTeacherMockExamDeleteDialog(
      context: context,
      title: _asText(item['title'], '제목 없음'),
    );
    if (ok != true) return;

    try {
      await TeacherMockExamService.deleteMockExam(_asInt(item['id']));
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모의고사가 삭제되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          '모의고사 관리',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('새 모의고사'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderCard(),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _openStudentReports,
                      icon: const Icon(Icons.groups_2_outlined),
                      label: const Text('학생별 리포트'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _blue,
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BreadcrumbBar(
                    label: _breadcrumbLabel,
                    canGoBack: _selectedGrade != null,
                    onBack: _goBackLevel,
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const SizedBox(
                      height: 320,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _MessagePanel(
                      icon: Icons.error_outline_rounded,
                      title: '목록을 불러오지 못했습니다.',
                      message: _error!,
                      actionLabel: '다시 시도',
                      onTap: _load,
                    )
                  else if (_items.isEmpty)
                    _MessagePanel(
                      icon: Icons.fact_check_outlined,
                      title: '등록된 모의고사가 없습니다.',
                      message: '새 모의고사를 만든 뒤 상세 화면에서 Excel/XLSX 파일을 업로드하세요.',
                      actionLabel: '새 모의고사 만들기',
                      onTap: _showCreateDialog,
                    )
                  else
                    _buildCurrentLevel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _breadcrumbLabel {
    final parts = ['모의고사 관리'];
    if (_selectedGrade != null) parts.add(_selectedGrade!);
    if (_selectedYear != null) parts.add('$_selectedYear');
    if (_selectedMonth != null) parts.add('$_selectedMonth월');
    return parts.join(' / ');
  }

  Widget _buildCurrentLevel() {
    if (_selectedGrade == null) {
      final folders = const ['고1', '고2', '고3'].map((grade) {
        return _FolderNode(
          title: grade,
          subtitle: '${_filterItems(grade: grade).length}개 시험',
          icon: Icons.school_outlined,
          onTap: () => setState(() => _selectedGrade = grade),
        );
      }).toList();
      return _FolderGrid(folders: folders);
    }

    if (_selectedYear == null) {
      final years = _filterItems(grade: _selectedGrade)
          .map((item) => _asInt((item as Map)['year']))
          .where((year) => year > 0)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
      if (years.isEmpty) {
        return _MessagePanel(
          icon: Icons.folder_off_outlined,
          title: '연도 폴더가 없습니다.',
          message: '이 학년에 등록된 모의고사가 없습니다.',
          actionLabel: '상위로',
          onTap: _goBackLevel,
        );
      }
      return _FolderGrid(
        folders: years.map((year) {
          return _FolderNode(
            title: '$year',
            subtitle:
                '${_filterItems(grade: _selectedGrade, year: year).length}개 시험',
            icon: Icons.calendar_month_outlined,
            onTap: () => setState(() => _selectedYear = year),
          );
        }).toList(),
      );
    }

    if (_selectedMonth == null) {
      final months = _filterItems(grade: _selectedGrade, year: _selectedYear)
          .map((item) => _asInt((item as Map)['month']))
          .where((month) => month > 0)
          .toSet()
          .toList()
        ..sort();
      if (months.isEmpty) {
        return _MessagePanel(
          icon: Icons.folder_off_outlined,
          title: '월 폴더가 없습니다.',
          message: '이 연도에 등록된 모의고사가 없습니다.',
          actionLabel: '상위로',
          onTap: _goBackLevel,
        );
      }
      return _FolderGrid(
        folders: months.map((month) {
          return _FolderNode(
            title: '$month월',
            subtitle:
                '${_filterItems(grade: _selectedGrade, year: _selectedYear, month: month).length}개 시험',
            icon: Icons.folder_rounded,
            onTap: () => setState(() => _selectedMonth = month),
          );
        }).toList(),
      );
    }

    final exams = _filterItems(
      grade: _selectedGrade,
      year: _selectedYear,
      month: _selectedMonth,
    );
    if (exams.isEmpty) {
      return _MessagePanel(
        icon: Icons.inventory_2_outlined,
        title: '이 폴더에는 모의고사가 없습니다.',
        message: '새 모의고사를 만들거나 다른 월 폴더를 선택해 주세요.',
        actionLabel: '상위로',
        onTap: _goBackLevel,
      );
    }
    return _ExamGrid(
      items: exams,
      onOpen: _openDetail,
      onDelete: _deleteExam,
    );
  }

  List<dynamic> _filterItems({
    String? grade,
    int? year,
    int? month,
  }) {
    return _items.where((item) {
      final data = item as Map;
      if (grade != null && _asText(data['grade']) != grade) return false;
      if (year != null && _asInt(data['year']) != year) return false;
      if (month != null && _asInt(data['month']) != month) return false;
      return true;
    }).toList();
  }
}

class _CreateMockExamDialog extends StatefulWidget {
  const _CreateMockExamDialog();

  @override
  State<_CreateMockExamDialog> createState() => _CreateMockExamDialogState();
}

class _CreateMockExamDialogState extends State<_CreateMockExamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController(text: '${DateTime.now().year}');
  final _monthController = TextEditingController(text: '9');
  final _titleController = TextEditingController();
  String _grade = '고2';
  bool _hasListening = false;
  bool _saving = false;

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final year = int.parse(_yearController.text.trim());
      final month = int.parse(_monthController.text.trim());
      final title = _titleController.text.trim().isEmpty
          ? '$year년 $month월 $_grade 모의고사'
          : _titleController.text.trim();
      final created = await TeacherMockExamService.createMockExam(
        grade: _grade,
        year: year,
        month: month,
        title: title,
        hasListening: _hasListening,
      );
      if (mounted) Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('생성 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _TeacherMockColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _IconBox(icon: Icons.add_task_rounded),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '새 모의고사 만들기',
                              style: TextStyle(
                                color: _TeacherMockColors.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '시험 틀을 만든 뒤 상세 화면에서 Excel/XLSX를 업로드합니다.',
                              style: TextStyle(
                                color: _TeacherMockColors.muted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  DropdownButtonFormField<String>(
                    value: _grade,
                    decoration: _dialogInputDecoration('학년'),
                    items: const ['고1', '고2', '고3']
                        .map((grade) => DropdownMenuItem(
                              value: grade,
                              child: Text(grade),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _grade = value ?? '고2'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _yearController,
                          decoration: _dialogInputDecoration('연도'),
                          keyboardType: TextInputType.number,
                          validator: _intValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _monthController,
                          decoration: _dialogInputDecoration('월'),
                          keyboardType: TextInputType.number,
                          validator: _intValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    decoration: _dialogInputDecoration(
                      '제목',
                      hint: '예: 2024년 9월 고2 모의고사',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _TeacherMockColors.line),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _hasListening,
                      activeColor: _TeacherMockColors.blue,
                      title: const Text(
                        '듣기 포함',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text('현재는 듣기 제외가 기본입니다.'),
                      onChanged: (value) =>
                          setState(() => _hasListening = value),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(
                              color: _TeacherMockColors.line,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _TeacherMockColors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('생성'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _TeacherMockColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _TeacherMockColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: _TeacherMockColors.blue, width: 1.5),
      ),
    );
  }

  String? _intValidator(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null) return '숫자로 입력하세요.';
    return null;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          _IconBox(icon: Icons.assignment_outlined),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '수능/모의고사 DB',
                  style: TextStyle(
                    color: _TeacherMockColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '등록된 20문항 모의고사를 확인하고 Excel/XLSX로 문항을 관리합니다.',
                  style: TextStyle(
                    color: _TeacherMockColors.muted,
                    height: 1.5,
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

class _MockExamCard extends StatelessWidget {
  const _MockExamCard({
    required this.exam,
    required this.onTap,
    required this.onDelete,
  });

  final Map<String, dynamic> exam;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final count = _asInt(exam['question_count']);
    final total = _asInt(exam['total_questions'], 20);
    final complete = exam['is_complete'] == true;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconBox(icon: Icons.fact_check_outlined, small: true),
                const Spacer(),
                _StatusBadge(complete: complete),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: '삭제',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _asText(exam['title'], '제목 없음'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _TeacherMockColors.ink,
                fontSize: 17,
                height: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_asText(exam['grade'])} · ${_asInt(exam['year'])}년 ${_asInt(exam['month'])}월',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _TeacherMockColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _CountBadge(label: '$count/$total문항'),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: onTap,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('상세 보기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({
    required this.label,
    required this.canGoBack,
    required this.onBack,
  });

  final String label;
  final bool canGoBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          IconButton(
            tooltip: '상위 폴더',
            onPressed: canGoBack ? onBack : null,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _TeacherMockColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderNode {
  const _FolderNode({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _FolderGrid extends StatelessWidget {
  const _FolderGrid({required this.folders});

  final List<_FolderNode> folders;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: folders.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 1 : 3,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: compact ? 3.4 : 2.6,
          ),
          itemBuilder: (context, index) {
            final folder = folders[index];
            return _FolderCard(folder: folder);
          },
        );
      },
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.folder});

  final _FolderNode folder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: folder.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(folder.icon, color: _TeacherMockColors.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _TeacherMockColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    folder.subtitle,
                    style: const TextStyle(
                      color: _TeacherMockColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _TeacherMockColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ExamGrid extends StatelessWidget {
  const _ExamGrid({
    required this.items,
    required this.onOpen,
    required this.onDelete,
  });

  final List<dynamic> items;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final ValueChanged<Map<String, dynamic>> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 1 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: compact ? 2.05 : 2.18,
          ),
          itemBuilder: (context, index) {
            final item = items[index] as Map<String, dynamic>;
            return _MockExamCard(
              exam: item,
              onTap: () => onOpen(item),
              onDelete: () => onDelete(item),
            );
          },
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.complete});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: complete ? const Color(0xFFEFF6FF) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: complete ? const Color(0xFFBFDBFE) : const Color(0xFFFED7AA),
        ),
      ),
      child: Text(
        complete ? '완료' : '미완성',
        style: TextStyle(
          color: complete ? _TeacherMockColors.blue : const Color(0xFFC2410C),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _TeacherMockColors.line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _TeacherMockColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: _TeacherMockColors.blue, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: _TeacherMockColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _TeacherMockColors.muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, this.small = false});

  final IconData icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: small ? 40 : 48,
      height: small ? 40 : 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: _TeacherMockColors.blue),
    );
  }
}

class _TeacherMockColors {
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const blue = Color(0xFF2563EB);
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _TeacherMockColors.line),
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
