import 'package:flutter/material.dart';
import '../../services/student_api.dart';
import '../../models/student_models.dart';
import 'student_exam_take_screen.dart';

class StudentExamListScreen extends StatefulWidget {
  const StudentExamListScreen({
    super.key,
    this.initialBookFolderId,
    this.initialBookFolderName,
    this.initialUnitFolderId,
    this.initialUnitFolderName,
  });

  final int? initialBookFolderId;
  final String? initialBookFolderName;
  final int? initialUnitFolderId;
  final String? initialUnitFolderName;

  @override
  State<StudentExamListScreen> createState() => _StudentExamListScreenState();
}

class _StudentExamListScreenState extends State<StudentExamListScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _blue = Color(0xFF2563EB);
  static const _line = Color(0xFFE5E7EB);

  bool _isLoading = true;
  String? _error;
  List<StudentExamSummary> _exams = [];
  List<StudentExamFolder> _folders = [];
  StudentExamFolder? _bookFolder;
  StudentExamFolder? _unitFolder;

  @override
  void initState() {
    super.initState();
    final bookId = widget.initialBookFolderId;
    final unitId = widget.initialUnitFolderId;

    if (bookId != null) {
      _bookFolder = StudentExamFolder(
        id: bookId,
        parentId: null,
        name: widget.initialBookFolderName?.trim().isNotEmpty == true
            ? widget.initialBookFolderName!.trim()
            : 'Textbook Folder',
        count: 0,
        hasChildren: true,
        isUnfiled: false,
        isDirectBucket: false,
      );
    }

    if (unitId != null) {
      _unitFolder = StudentExamFolder(
        id: unitId,
        parentId: bookId,
        name: widget.initialUnitFolderName?.trim().isNotEmpty == true
            ? widget.initialUnitFolderName!.trim()
            : 'Unit Folder',
        count: 0,
        hasChildren: false,
        isUnfiled: false,
        isDirectBucket: false,
      );
    }

    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_unitFolder == null) {
        final folders =
            await StudentApi.fetchExamFolders(parentId: _bookFolder?.id);
        if (!mounted) return;
        setState(() {
          _folders = folders;
          _exams = [];
        });
      } else {
        final data = await StudentApi.fetchMyExams(
          folderId: _unitFolder!.isUnfiled ? null : _unitFolder!.id,
          unfiled: _unitFolder!.isUnfiled,
        );
        if (!mounted) return;
        setState(() {
          _exams = data;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openFolder(StudentExamFolder folder) {
    if (_bookFolder == null && !folder.isUnfiled) {
      setState(() {
        _bookFolder = folder;
        _unitFolder = null;
      });
      _loadCurrent();
      return;
    }

    setState(() => _unitFolder = folder);
    _loadCurrent();
  }

  void _goBackLevel() {
    if (_unitFolder != null) {
      setState(() => _unitFolder = null);
      _loadCurrent();
      return;
    }

    if (_bookFolder != null) {
      setState(() => _bookFolder = null);
      _loadCurrent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = _bookFolder != null || _unitFolder != null;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: _surface,
        leading: canGoBack
            ? IconButton(
                tooltip: '상위 폴더',
                onPressed: _goBackLevel,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: const Text(
          'Available Exams',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _loadCurrent,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCurrent,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 120),
          _MessageCard(
            icon: Icons.error_outline_rounded,
            title: '시험 목록을 불러오지 못했습니다.',
            message: _error!,
            buttonLabel: '다시 시도',
            onPressed: _loadCurrent,
          ),
        ],
      );
    }

    if (_unitFolder == null) {
      return _buildFolderBody();
    }

    if (_exams.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 120),
          _MessageCard(
            icon: Icons.folder_open_rounded,
            title: 'No exam sets in this folder.',
            message:
                'Choose another unit folder or ask your teacher to add exam sets.',
            buttonLabel: 'Back',
            onPressed: _goBackLevel,
          ),
        ],
      );
    }

    final completed = _exams.where((exam) => exam.isCompleted).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _HeaderCard(
          totalCount: _exams.length,
          completedCount: completed,
        ),
        const SizedBox(height: 16),
        if (_bookFolder != null)
          _Breadcrumb(text: '${_bookFolder!.name} / ${_unitFolder!.name}'),
        if (_bookFolder != null) const SizedBox(height: 18),
        const Text(
          'Exam Sets',
          style: TextStyle(
            color: _ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (final exam in _exams) ...[
          _ExamSetCard(exam: exam),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildFolderBody() {
    if (_folders.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 120),
          _MessageCard(
            icon: Icons.assignment_outlined,
            title: _bookFolder == null
                ? '아직 응시 가능한 시험이 없습니다.'
                : '이 교재 아래에 단원 폴더가 없습니다.',
            message: _bookFolder == null
                ? '선생님이 문제세트를 생성하면 여기에 표시됩니다.'
                : '다른 교재를 선택하거나 새 문제세트를 생성해 주세요.',
            buttonLabel: _bookFolder == null ? null : 'Back',
            onPressed: _bookFolder == null ? null : _goBackLevel,
          ),
        ],
      );
    }

    final total = _folders.fold<int>(0, (sum, folder) => sum + folder.count);
    final title =
        _bookFolder == null ? 'Textbook Folders' : '${_bookFolder!.name} Units';
    final subtitle = _bookFolder == null
        ? 'Choose a textbook folder to see units.'
        : 'Choose a unit folder to see exam sets.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _HeaderCard(
          totalCount: total,
          completedCount: 0,
        ),
        const SizedBox(height: 16),
        _FolderSectionTitle(title: title, subtitle: subtitle),
        const SizedBox(height: 12),
        _FolderGrid(
          folders: _folders,
          onTap: _openFolder,
        ),
      ],
    );
  }
}

class _FolderSectionTitle extends StatelessWidget {
  const _FolderSectionTitle({
    required this.title,
    required this.subtitle,
  });

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
            color: _StudentExamListScreenState._ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _StudentExamListScreenState._muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _StudentExamListScreenState._muted,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FolderGrid extends StatelessWidget {
  const _FolderGrid({
    required this.folders,
    required this.onTap,
  });

  final List<StudentExamFolder> folders;
  final ValueChanged<StudentExamFolder> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: folders.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 1 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: compact ? 3.3 : 2.8,
          ),
          itemBuilder: (context, index) {
            final folder = folders[index];
            return _FolderCard(
              folder: folder,
              onTap: () => onTap(folder),
            );
          },
        );
      },
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.onTap,
  });

  final StudentExamFolder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _StudentExamListScreenState._line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.folder_rounded,
                color: _StudentExamListScreenState._blue,
              ),
            ),
            const SizedBox(width: 13),
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
                      color: _StudentExamListScreenState._ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${folder.count} exam sets',
                    style: const TextStyle(
                      color: _StudentExamListScreenState._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _StudentExamListScreenState._muted,
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _FolderStrip extends StatelessWidget {
  const _FolderStrip({
    required this.folders,
    required this.selectedFolderId,
    required this.onSelected,
  });

  final List<StudentExamFolder> folders;
  final int? selectedFolderId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final totalCount =
        folders.fold<int>(0, (sum, folder) => sum + folder.count);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FolderChip(
            label: 'All',
            count: totalCount,
            selected: selectedFolderId == null,
            onTap: () => onSelected(null),
          ),
          for (final folder in folders) ...[
            const SizedBox(width: 8),
            _FolderChip(
              label: folder.name,
              count: folder.count,
              selected: selectedFolderId == folder.id,
              onTap: () => onSelected(folder.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _StudentExamListScreenState._blue
        : _StudentExamListScreenState._muted;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? _StudentExamListScreenState._blue
                : _StudentExamListScreenState._line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_rounded, size: 16, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamSetCard extends StatelessWidget {
  const _ExamSetCard({required this.exam});

  final StudentExamSummary exam;

  @override
  Widget build(BuildContext context) {
    final progressLabel = exam.isCompleted ? 'Completed' : 'Ready';
    final createdLabel = _formatDate(exam.createdAt);
    final questionLabel = exam.questionCount > 0
        ? '${exam.questionCount} questions'
        : 'Questions ready';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentExamTakeScreen(
              problemSetId: exam.problemSetId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _StudentExamListScreenState._line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: _StudentExamListScreenState._blue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.name.isEmpty ? 'Untitled Exam' : exam.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _StudentExamListScreenState._ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      if (exam.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          exam.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _StudentExamListScreenState._muted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusChip(
                  label: progressLabel,
                  completed: exam.isCompleted,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaPill(
                  icon: Icons.quiz_rounded,
                  label: questionLabel,
                ),
                _MetaPill(
                  icon: Icons.calendar_month_rounded,
                  label: createdLabel,
                ),
                _MetaPill(
                  icon: Icons.folder_rounded,
                  label: exam.folderName,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: exam.isCompleted ? 1 : 0.08,
                      backgroundColor: const Color(0xFFEFF6FF),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        exam.isCompleted
                            ? const Color(0xFF22C55E)
                            : _StudentExamListScreenState._blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentExamTakeScreen(
                          problemSetId: exam.problemSetId,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    exam.isCompleted
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(exam.isCompleted ? 'Review' : 'Start'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _StudentExamListScreenState._blue,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
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

  static String _formatDate(String raw) {
    if (raw.trim().isEmpty) return 'Created date -';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year}.${_two(parsed.month)}.${_two(parsed.day)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.totalCount,
    required this.completedCount,
  });

  final int totalCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final readyCount = totalCount - completedCount;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF22C7C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: _StudentExamListScreenState._blue,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Start?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Choose an exam set and begin practice.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(label: 'Available', value: '$readyCount'),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(alpha: 0.24),
              ),
              Expanded(
                child:
                    _HeaderStat(label: 'Completed', value: '$completedCount'),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(alpha: 0.24),
              ),
              Expanded(
                child: _HeaderStat(label: 'Total', value: '$totalCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.completed});

  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color =
        completed ? const Color(0xFF16A34A) : _StudentExamListScreenState._blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _StudentExamListScreenState._line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: _StudentExamListScreenState._blue,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _StudentExamListScreenState._muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _StudentExamListScreenState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: _StudentExamListScreenState._blue),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _StudentExamListScreenState._ink,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _StudentExamListScreenState._muted,
              height: 1.35,
            ),
          ),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onPressed,
              child: Text(buttonLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
