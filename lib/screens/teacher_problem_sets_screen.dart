// lib/screens/teacher_problem_sets_screen.dart
import 'package:flutter/material.dart';

import '../models/student_models.dart';
import '../services/teacher_problem_set_service.dart';
import '../widgets/problem_set_assignment_dialog.dart';
import 'teacher/teacher_problem_set_preview_screen.dart';

class TeacherProblemSetsScreen extends StatefulWidget {
  const TeacherProblemSetsScreen({super.key});

  @override
  State<TeacherProblemSetsScreen> createState() =>
      _TeacherProblemSetsScreenState();
}

class _TeacherProblemSetsScreenState extends State<TeacherProblemSetsScreen> {
  static const _ink = Color(0xFF172033);
  static const _surface = Color(0xFFF4F7FB);

  bool _loading = false;
  String? _error;
  List<StudentExamFolder> _folders = [];
  List<StudentExamSummary> _items = [];
  StudentExamFolder? _bookFolder;
  StudentExamFolder? _unitFolder;

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
          _items = [];
        });
      } else {
        final list = await TeacherProblemSetService.fetchProblemSets(
          folderId: _unitFolder!.isUnfiled ? null : _unitFolder!.id,
          unfiled: _unitFolder!.isUnfiled,
        );
        if (!mounted) return;
        setState(() => _items = list);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '문제세트 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _showAssignmentDialog(StudentExamSummary item) async {
    final result = await showDialog<ProblemSetAssignmentResult>(
      context: context,
      builder: (_) => ProblemSetAssignmentDialog(
        problemSetId: item.problemSetId,
        title: item.name,
      ),
    );
    if (!mounted || result == null) return;
    final message = result.failed.isEmpty
        ? '${result.successCount}명에게 문제세트를 배포했습니다.'
        : '${result.successCount}명 배포 완료 · ${result.failed.length}명 실패/중복';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '새로고침',
          onPressed: _loadCurrent,
        ),
      ),
    );
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
          '문제세트',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _loading ? null : _loadCurrent,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeaderCard(
                  icon: Icons.folder_copy_outlined,
                  title: '저장된 문제세트 목록',
                  subtitle: '교재와 단원 폴더를 따라가며 생성된 문제세트를 확인합니다.',
                ),
                const SizedBox(height: 16),
                _AdminCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: _unitFolder == null
                              ? (_bookFolder == null ? '교재 폴더' : '단원/강 폴더')
                              : '문제세트 목록',
                          subtitle: _breadcrumbLabel,
                        ),
                        const SizedBox(height: 16),
                        _buildListBody(),
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

  String get _breadcrumbLabel {
    if (_unitFolder != null && _bookFolder != null) {
      return '${_bookFolder!.name} / ${_unitFolder!.name}';
    }
    if (_bookFolder != null) {
      return '${_bookFolder!.name} 아래 단원/강 폴더를 선택하세요.';
    }
    return '교재 폴더를 선택하면 단원/강 폴더가 표시됩니다.';
  }

  Widget _buildListBody() {
    if (_loading) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _MessagePanel(
        icon: Icons.error_outline,
        title: '목록을 불러오지 못했습니다.',
        message: _error!,
        actionLabel: '다시 시도',
        onTap: _loadCurrent,
      );
    }

    if (_unitFolder == null) {
      if (_folders.isEmpty) {
        return _MessagePanel(
          icon: Icons.inventory_2_outlined,
          title: _bookFolder == null ? '저장된 문제세트가 없습니다.' : '단원 폴더가 없습니다.',
          message: _bookFolder == null
              ? '문제 제작 화면에서 문제세트를 생성해 보세요.'
              : '다른 교재를 선택하거나 새 단원 자료를 생성해 주세요.',
          actionLabel: '새로고침',
          onTap: _loadCurrent,
        );
      }

      return _FolderGrid(
        folders: _folders,
        onTap: _openFolder,
      );
    }

    if (_items.isEmpty) {
      return _MessagePanel(
        icon: Icons.inventory_2_outlined,
        title: '이 폴더에는 문제세트가 없습니다.',
        message: '다른 단원 폴더를 선택하거나 문제세트를 생성해 주세요.',
        actionLabel: '상위 폴더',
        onTap: _goBackLevel,
      );
    }

    return Column(
      children: [
        ..._items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ProblemSetRowTile(
              title: item.name,
              folderLabel: item.folderName,
              count: item.questionCount,
              onAssign: () => _showAssignmentDialog(item),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherProblemSetPreviewScreen(
                      problemSetId: item.problemSetId,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
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
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _TeacherColors.line),
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
                color: _TeacherColors.blue,
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
                      color: _TeacherColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${folder.count}개 문제세트',
                    style: const TextStyle(
                      color: _TeacherColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _TeacherColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ProblemSetRowTile extends StatelessWidget {
  const _ProblemSetRowTile({
    required this.title,
    required this.folderLabel,
    required this.count,
    required this.onAssign,
    required this.onTap,
  });

  final String title;
  final String folderLabel;
  final int count;
  final VoidCallback onAssign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _TeacherColors.line),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final info = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.quiz_outlined,
                    size: 22,
                    color: _TeacherColors.blue,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _TeacherColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge(label: folderLabel),
                          _Badge(label: '$count문항'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: compact ? WrapAlignment.start : WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onAssign,
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: const Text('학생에게 배포'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _TeacherColors.blue,
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onTap,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('미리보기'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  info,
                  const SizedBox(height: 14),
                  actions,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: info),
                const SizedBox(width: 16),
                actions,
              ],
            );
          },
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
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _TeacherColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, color: _TeacherColors.blue, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _TeacherColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _TeacherColors.muted),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(actionLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: _TeacherColors.blue,
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
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
          color: _TeacherColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _TeacherColors.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _TeacherColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _TeacherColors.muted,
                      fontSize: 13,
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
            color: _TeacherColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _TeacherColors.muted,
            fontSize: 13,
          ),
        ),
      ],
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
        border: Border.all(color: _TeacherColors.line),
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

class _TeacherColors {
  static const blue = Color(0xFF2563EB);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
}
