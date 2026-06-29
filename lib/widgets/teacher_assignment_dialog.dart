import 'package:flutter/material.dart';

import '../models/final_touch.dart';
import '../models/learning_assignment.dart';
import '../services/learning_assignment_service.dart';

class TeacherAssignmentDialog extends StatefulWidget {
  const TeacherAssignmentDialog({
    super.key,
    required this.finalTouch,
  });

  final FinalTouchSummary finalTouch;

  @override
  State<TeacherAssignmentDialog> createState() =>
      _TeacherAssignmentDialogState();
}

class _TeacherAssignmentDialogState extends State<TeacherAssignmentDialog> {
  static const _primary = Color(0xFF183B56);
  static const _teal = Color(0xFF0F766E);
  static const _surface = Color(0xFFF4F7FA);
  static const _ink = Color(0xFF102A43);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);

  final _service = const LearningAssignmentService();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final Set<int> _selectedIds = {};

  late Future<List<AssignableStudent>> _studentsFuture;
  DateTime? _dueAt;
  bool _isSaving = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _studentsFuture = _service.fetchStudents();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: _dueAt ?? now.add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _ink,
              secondary: _teal,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _dueAt = DateTime(picked.year, picked.month, picked.day, 23, 59);
    });
  }

  Future<void> _assign() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('배포할 학생을 선택해 주세요.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final result = await _service.assignFinalTouch(
        finalTouchId: widget.finalTouch.id,
        studentIds: _selectedIds.toList(),
        title: widget.finalTouch.source.isNotEmpty
            ? widget.finalTouch.source
            : 'Final Touch #${widget.finalTouch.id}',
        teacherMessage: _messageController.text,
        dueAt: _dueAt,
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('배포 실패: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(Icons.send_rounded, color: _teal),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '학생에게 배포',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Final Touch 자료를 선택한 학생의 내 학습에 추가합니다.',
                            style: TextStyle(
                              color: _muted,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ContentSummary(finalTouch: widget.finalTouch),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: '학생 이름 또는 이메일 검색',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<AssignableStudent>>(
                  future: _studentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('학생 목록 로드 실패: ${snapshot.error}'));
                    }
                    final students =
                        (snapshot.data ?? const []).where((student) {
                      final q = _query.toLowerCase();
                      if (q.isEmpty) return true;
                      return student.nickname.toLowerCase().contains(q) ||
                          student.email.toLowerCase().contains(q);
                    }).toList();
                    if (students.isEmpty) {
                      return const Center(child: Text('표시할 학생이 없습니다.'));
                    }
                    return Column(
                      children: [
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedIds
                                    ..clear()
                                    ..addAll(
                                        students.map((student) => student.id));
                                });
                              },
                              icon: const Icon(Icons.done_all_rounded),
                              label: const Text('전체 선택'),
                            ),
                            TextButton(
                              onPressed: () => setState(_selectedIds.clear),
                              child: const Text('선택 해제'),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2F1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '선택됨 ${_selectedIds.length}명',
                                style: const TextStyle(
                                  color: _teal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              final student = students[index];
                              final selected =
                                  _selectedIds.contains(student.id);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFE0F2F1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF99F6E4)
                                        : _line,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: selected,
                                  activeColor: _teal,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedIds.add(student.id);
                                      } else {
                                        _selectedIds.remove(student.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    student.nickname,
                                    style: const TextStyle(
                                      color: _ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  subtitle: Text(student.email),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _isSaving ? null : _pickDueDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _line),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: _teal,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _dueAt == null
                                    ? '마감일 선택'
                                    : _formatDate(_dueAt!),
                                style: const TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '이 자료에서 주제와 요지를 중심으로 복습하세요.',
                  labelText: '선생님 안내 선택',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _isSaving || _selectedIds.isEmpty ? null : _assign,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(_isSaving ? '배포 중...' : '배포하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class _ContentSummary extends StatelessWidget {
  const _ContentSummary({required this.finalTouch});

  final FinalTouchSummary finalTouch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '배포 자료',
            style: TextStyle(
              color: _TeacherAssignmentDialogState._teal,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            finalTouch.source.isEmpty
                ? 'Final Touch #${finalTouch.id}'
                : finalTouch.source,
            style: const TextStyle(
              color: _TeacherAssignmentDialogState._ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            finalTouch.titleKo.isNotEmpty
                ? finalTouch.titleKo
                : finalTouch.titleEn,
            style: const TextStyle(
              color: _TeacherAssignmentDialogState._muted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _DialogInfoChip(finalTouch.folderName),
              _DialogInfoChip('ID ${finalTouch.id}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogInfoChip extends StatelessWidget {
  const _DialogInfoChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _TeacherAssignmentDialogState._muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
