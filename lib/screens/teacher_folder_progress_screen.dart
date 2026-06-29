import 'package:flutter/material.dart';

import '../models/student_models.dart';
import '../services/teacher_problem_set_service.dart';
import 'teacher_student_progress_detail_screen.dart';

class TeacherFolderProgressScreen extends StatefulWidget {
  const TeacherFolderProgressScreen({super.key});

  @override
  State<TeacherFolderProgressScreen> createState() =>
      _TeacherFolderProgressScreenState();
}

class _TeacherFolderProgressScreenState
    extends State<TeacherFolderProgressScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);

  bool _loading = false;
  String? _error;
  List<StudentExamFolder> _folders = [];
  StudentExamFolder? _bookFolder;
  StudentExamFolder? _unitFolder;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_unitFolder == null) {
        final folders = await TeacherProblemSetService.fetchFolders(
          parentId: _bookFolder?.id,
        );
        if (!mounted) return;
        setState(() {
          _folders = folders;
          _report = null;
        });
      } else {
        final folderId = _unitFolder!.id;
        if (folderId == null) {
          throw Exception('미분류 폴더는 진도표를 아직 지원하지 않습니다.');
        }
        final report =
            await TeacherProblemSetService.fetchFolderProgressReport(folderId);
        if (!mounted) return;
        setState(() => _report = report);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '진도표 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openFolder(StudentExamFolder folder) {
    if (_bookFolder == null && !folder.isUnfiled) {
      setState(() {
        _bookFolder = folder;
        _unitFolder = null;
        _report = null;
      });
      _loadCurrent();
      return;
    }

    setState(() {
      _unitFolder = folder;
      _report = null;
    });
    _loadCurrent();
  }

  void _goBackLevel() {
    if (_unitFolder != null) {
      setState(() {
        _unitFolder = null;
        _report = null;
      });
      _loadCurrent();
      return;
    }

    if (_bookFolder != null) {
      setState(() {
        _bookFolder = null;
        _report = null;
      });
      _loadCurrent();
    }
  }

  String get _breadcrumbLabel {
    if (_unitFolder != null && _bookFolder != null) {
      return '${_bookFolder!.name} / ${_unitFolder!.name}';
    }
    if (_bookFolder != null) {
      return '${_bookFolder!.name} 아래 단원/강 폴더를 선택하세요.';
    }
    return '교재 폴더를 선택하면 단원별 진도표를 볼 수 있습니다.';
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = _bookFolder != null || _unitFolder != null;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: canGoBack
            ? IconButton(
                tooltip: '상위 폴더',
                onPressed: _goBackLevel,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: const Text(
          '폴더별 진도표',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _loading ? null : _loadCurrent,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeaderCard(),
                const SizedBox(height: 16),
                _AdminCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: _unitFolder == null ? '폴더 선택' : '학습 진행 리포트',
                          subtitle: _breadcrumbLabel,
                        ),
                        const SizedBox(height: 16),
                        _buildBody(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _MessagePanel(
        title: '진도표를 불러오지 못했습니다.',
        message: _error!,
        onPressed: _loadCurrent,
      );
    }

    if (_unitFolder == null) {
      if (_folders.isEmpty) {
        return _MessagePanel(
          title: '표시할 폴더가 없습니다.',
          message: '문제세트가 포함된 교재/단원 폴더가 생기면 여기에 표시됩니다.',
          onPressed: _loadCurrent,
        );
      }
      return _FolderGrid(folders: _folders, onTap: _openFolder);
    }

    final report = _report;
    if (report == null) {
      return _MessagePanel(
        title: '리포트 데이터가 없습니다.',
        message: '새로고침 후 다시 확인해 주세요.',
        onPressed: _loadCurrent,
      );
    }
    return _ProgressReport(data: report);
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.timeline_rounded,
                color: _TeacherFolderProgressScreenState._blue,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '단원별 학습 진행 리포트',
                    style: TextStyle(
                      color: _TeacherFolderProgressScreenState._ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '교재와 단원 폴더 기준으로 응시율, 평균 점수, 학생별 약점을 확인합니다.',
                    style: TextStyle(
                      color: _TeacherFolderProgressScreenState._muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderGrid extends StatelessWidget {
  const _FolderGrid({required this.folders, required this.onTap});

  final List<StudentExamFolder> folders;
  final ValueChanged<StudentExamFolder> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: folders.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 1 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: compact ? 3.6 : 3.1,
          ),
          itemBuilder: (context, index) {
            final folder = folders[index];
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onTap(folder),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _TeacherFolderProgressScreenState._line,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: _TeacherFolderProgressScreenState._blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _TeacherFolderProgressScreenState._ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${folder.count}개 문제세트',
                            style: const TextStyle(
                              color: _TeacherFolderProgressScreenState._muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: _TeacherFolderProgressScreenState._muted,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProgressReport extends StatelessWidget {
  const _ProgressReport({required this.data});

  final Map<String, dynamic> data;

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _asString(dynamic value, [String fallback = '-']) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  List<dynamic> _asList(dynamic value) => value is List ? value : const [];

  @override
  Widget build(BuildContext context) {
    final book = _asString(data['book_folder_name'], '교재 미지정');
    final unit = _asString(data['unit_folder_name'], '단원 미지정');
    final finalTouchCount = _asInt(data['final_touch_count']);
    final problemSetCount = _asInt(data['problem_set_count']);
    final folderId = _asInt(data['folder_id'] ?? data['unit_folder_id']);
    final students = _asList(data['students']);
    final weakTypes =
        _asList(data['weak_types']).map((e) => e.toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Badge(label: book),
            _Badge(label: unit),
            _Badge(label: 'Final Touch $finalTouchCount개'),
            _Badge(label: '문제세트 $problemSetCount개'),
          ],
        ),
        const SizedBox(height: 16),
        _MetricGrid(data: data),
        const SizedBox(height: 16),
        _WeakCard(weakTypes: weakTypes),
        const SizedBox(height: 16),
        _StudentProgressTable(students: students, folderId: folderId),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.data});

  final Map<String, dynamic> data;

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _score(dynamic value) {
    if (value == null) return '-';
    if (value is num && value % 1 != 0) return value.toStringAsFixed(1);
    return '${_asInt(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final finalTouchTracking = data['final_touch_tracking_available'] == true;
    final items = [
      (
        'Final Touch 열람률',
        finalTouchTracking
            ? '${_asInt(data['final_touch_view_rate'])}%'
            : '추적 전',
        Icons.auto_awesome_rounded,
      ),
      (
        '문제세트 응시율',
        '${_asInt(data['problem_set_attempt_rate'])}%',
        Icons.fact_check_rounded,
      ),
      (
        '평균 점수',
        '${_score(data['average_score'])}점',
        Icons.trending_up_rounded,
      ),
      (
        '완료 학생',
        '${_asInt(data['completed_student_count'])}명',
        Icons.task_alt_rounded,
      ),
      (
        '미완료 학생',
        '${_asInt(data['incomplete_student_count'])}명',
        Icons.pending_actions_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 2 : 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: compact ? 1.55 : 1.2,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _MetricCard(label: item.$1, value: item.$2, icon: item.$3);
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _TeacherFolderProgressScreenState._blue),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: _TeacherFolderProgressScreenState._muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: _TeacherFolderProgressScreenState._ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeakCard extends StatelessWidget {
  const _WeakCard({required this.weakTypes});

  final List<String> weakTypes;

  @override
  Widget build(BuildContext context) {
    final text = weakTypes.isEmpty ? '아직 약점 데이터가 없습니다.' : weakTypes.join(', ');
    final recommendation = weakTypes.isEmpty
        ? '학생들이 문제세트를 제출하면 폴더별 약점 유형이 표시됩니다.'
        : '${weakTypes.take(2).join(', ')} 유형 보충 자료를 준비해 보세요.';

    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: '폴더 전체 약점',
              subtitle: '이 단원에서 가장 많이 틀린 유형입니다.',
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: _TeacherFolderProgressScreenState._ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation,
                    style: const TextStyle(
                      color: _TeacherFolderProgressScreenState._muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentProgressTable extends StatelessWidget {
  const _StudentProgressTable({
    required this.students,
    required this.folderId,
  });

  final List<dynamic> students;
  final int folderId;

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _asString(dynamic value, [String fallback = '-']) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _score(dynamic value) {
    if (value == null) return '-';
    if (value is num && value % 1 != 0) return value.toStringAsFixed(1);
    return '${_asInt(value)}';
  }

  List<String> _weakTypes(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString() ?? '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '-';
    final now = DateTime.now();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';
    if (parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day) {
      return '오늘 $time';
    }
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '$month.$day $time';
  }

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: '학생별 진도표',
              subtitle: '문제세트 응시 기록은 실제 제출 기준입니다.',
            ),
            const SizedBox(height: 14),
            if (students.isEmpty)
              const Text(
                '등록된 학생이 없습니다.',
                style:
                    TextStyle(color: _TeacherFolderProgressScreenState._muted),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columns: const [
                    DataColumn(label: Text('학생')),
                    DataColumn(label: Text('Final Touch')),
                    DataColumn(label: Text('문제세트')),
                    DataColumn(label: Text('평균 점수')),
                    DataColumn(label: Text('약점 유형')),
                    DataColumn(label: Text('최근 학습일')),
                  ],
                  rows: students.map((item) {
                    final data = item is Map ? item : const {};
                    final viewed = data['final_touch_viewed_count'];
                    final finalTouchText = viewed == null
                        ? '추적 전/${_asInt(data['final_touch_total'])}'
                        : '${_asInt(viewed)}/${_asInt(data['final_touch_total'])}';
                    final weakTypes = _weakTypes(data['weak_types']);
                    final studentId = _asInt(data['user_id']);
                    return DataRow(
                      onSelectChanged: folderId <= 0 || studentId <= 0
                          ? null
                          : (_) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TeacherStudentProgressDetailScreen(
                                    folderId: folderId,
                                    studentId: studentId,
                                  ),
                                ),
                              );
                            },
                      cells: [
                        DataCell(Text(_asString(data['nickname']))),
                        DataCell(Text(finalTouchText)),
                        DataCell(
                          Text(
                            '${_asInt(data['problem_set_taken_count'])}/${_asInt(data['problem_set_total'])}',
                          ),
                        ),
                        DataCell(Text('${_score(data['average_score'])}점')),
                        DataCell(Text(
                            weakTypes.isEmpty ? '-' : weakTypes.join(', '))),
                        DataCell(
                          Text(
                            _formatDate(data['recent_learning_at']),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _TeacherFolderProgressScreenState._ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _TeacherFolderProgressScreenState._muted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _TeacherFolderProgressScreenState._blue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TeacherFolderProgressScreenState._line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.message,
    required this.onPressed,
  });

  final String title;
  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TeacherFolderProgressScreenState._line),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _TeacherFolderProgressScreenState._blue,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _TeacherFolderProgressScreenState._ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _TeacherFolderProgressScreenState._muted,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
