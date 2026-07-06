// lib/screens/final_touch_list_screen.dart
import 'package:flutter/material.dart';

import '../config/auth_store.dart';
import '../models/final_touch.dart';
import '../models/final_touch_practice_result.dart';
import '../models/final_touch_report.dart';
import '../models/learning_assignment.dart';
import '../services/final_touch_service.dart';
import '../services/final_touch_practice_result_service.dart';
import '../services/learning_assignment_service.dart';
import '../utils/final_touch_pdf_generator.dart';
import '../widgets/final_touch_core_analysis.dart';
import '../widgets/final_touch_sentence_analysis.dart';
import '../widgets/teacher_assignment_dialog.dart';
import 'final_touch_sentence_practice_screen.dart';

class FinalTouchListScreen extends StatefulWidget {
  const FinalTouchListScreen({
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
  State<FinalTouchListScreen> createState() => _FinalTouchListScreenState();
}

class _FinalTouchListScreenState extends State<FinalTouchListScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FB);

  final _service = const FinalTouchService();
  final _searchController = TextEditingController();
  late Future<List<FinalTouchFolder>> _foldersFuture;
  late Future<List<FinalTouchSummary>> _allItemsFuture;
  Future<List<FinalTouchSummary>>? _itemsFuture;
  FinalTouchFolder? _bookFolder;
  FinalTouchFolder? _unitFolder;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final bookId = widget.initialBookFolderId;
    final unitId = widget.initialUnitFolderId;
    _allItemsFuture = _service.fetchFinalTouches(limit: 100);

    if (unitId != null) {
      _bookFolder = bookId == null
          ? null
          : FinalTouchFolder(
              id: bookId,
              parentId: null,
              name: widget.initialBookFolderName?.trim().isNotEmpty == true
                  ? widget.initialBookFolderName!.trim()
                  : '교재 폴더',
              count: 0,
              hasChildren: true,
              isUnfiled: false,
              isDirectBucket: false,
            );
      _unitFolder = FinalTouchFolder(
        id: unitId,
        parentId: bookId,
        name: widget.initialUnitFolderName?.trim().isNotEmpty == true
            ? widget.initialUnitFolderName!.trim()
            : '단원 폴더',
        count: 0,
        hasChildren: false,
        isUnfiled: false,
        isDirectBucket: false,
      );
      _foldersFuture = _service.fetchFolders(parentId: bookId);
      _itemsFuture = _service.fetchFinalTouches(folderId: unitId);
      return;
    }

    if (bookId != null) {
      _bookFolder = FinalTouchFolder(
        id: bookId,
        parentId: null,
        name: widget.initialBookFolderName?.trim().isNotEmpty == true
            ? widget.initialBookFolderName!.trim()
            : '교재 폴더',
        count: 0,
        hasChildren: true,
        isUnfiled: false,
        isDirectBucket: false,
      );
      _foldersFuture = _service.fetchFolders(parentId: bookId);
      return;
    }

    _foldersFuture = _service.fetchFolders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _allItemsFuture = _service.fetchFinalTouches(limit: 100);
      if (_unitFolder != null) {
        _itemsFuture = _service.fetchFinalTouches(
          folderId: _unitFolder!.isUnfiled ? null : _unitFolder!.id,
          unfiled: _unitFolder!.isUnfiled,
        );
      } else {
        _foldersFuture = _service.fetchFolders(parentId: _bookFolder?.id);
      }
    });
  }

  void _openFolder(FinalTouchFolder folder) {
    if (_bookFolder == null && !folder.isUnfiled) {
      setState(() {
        _bookFolder = folder;
        _unitFolder = null;
        _itemsFuture = null;
        _foldersFuture = _service.fetchFolders(parentId: folder.id);
      });
      return;
    }

    setState(() {
      _unitFolder = folder;
      _itemsFuture = _service.fetchFinalTouches(
        folderId: folder.isUnfiled ? null : folder.id,
        unfiled: folder.isUnfiled,
      );
    });
  }

  void _goBackLevel() {
    if (_unitFolder != null) {
      setState(() {
        _unitFolder = null;
        _itemsFuture = null;
        _searchQuery = '';
        _searchController.clear();
        _foldersFuture = _service.fetchFolders(parentId: _bookFolder?.id);
      });
      return;
    }

    if (_bookFolder != null) {
      setState(() {
        _bookFolder = null;
        _searchQuery = '';
        _searchController.clear();
        _foldersFuture = _service.fetchFolders();
      });
    }
  }

  List<FinalTouchSummary> _filterAndSortItems(List<FinalTouchSummary> items) {
    final sorted = List<FinalTouchSummary>.from(items)
      ..sort(
          (a, b) => _dateScore(b.createdAt).compareTo(_dateScore(a.createdAt)));

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return sorted;

    return sorted.where((item) {
      final target = [
        item.source,
        item.folderName,
        item.titleEn,
        item.titleKo,
        item.topicEn,
        item.topicKo,
        item.gistEn,
        item.gistKo,
        item.createdAt,
      ].join(' ').toLowerCase();
      return target.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = _bookFolder != null || _unitFolder != null;
    final isTeacher = AuthStore.isTeacher;

    return Scaffold(
      backgroundColor: isTeacher ? const Color(0xFFF4F7FA) : _surface,
      appBar: AppBar(
        backgroundColor: isTeacher ? const Color(0xFF183B56) : Colors.white,
        foregroundColor: isTeacher ? Colors.white : _ink,
        elevation: 0,
        surfaceTintColor: isTeacher ? const Color(0xFF183B56) : Colors.white,
        centerTitle: true,
        leading: canGoBack
            ? IconButton(
                tooltip: '상위 폴더',
                onPressed: _goBackLevel,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: const Text(
          'Final Touch',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _unitFolder == null ? _buildFolderPage() : _buildItemPage(),
    );
  }

  Widget _buildFolderPage() {
    return FutureBuilder<List<FinalTouchFolder>>(
      future: _foldersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.error_outline,
            title: '폴더를 불러오지 못했습니다.',
            message: '${snapshot.error}',
            buttonLabel: '다시 시도',
            onPressed: _reload,
          );
        }

        final folders = snapshot.data ?? const [];
        if (folders.isEmpty) {
          return _MessageState(
            icon: Icons.inventory_2_outlined,
            title:
                _bookFolder == null ? '저장된 Final Touch가 없습니다.' : '단원 폴더가 없습니다.',
            message: _bookFolder == null
                ? '선생님이 지문 분석 허브에서 분석을 완료하면 여기에 표시됩니다.'
                : '이 교재 아래에 아직 단원 자료가 없습니다.',
            buttonLabel: '새로고침',
            onPressed: _reload,
          );
        }

        final total = folders.fold<int>(0, (sum, folder) => sum + folder.count);
        final title = _bookFolder == null ? '교재 폴더' : '${_bookFolder!.name} 단원';
        final subtitle = _bookFolder == null
            ? '교재를 선택한 뒤 단원별 Final Touch를 확인하세요.'
            : '단원/강 폴더를 선택하면 분석 자료 목록이 열립니다.';

        if (_searchQuery.trim().isNotEmpty) {
          return FutureBuilder<List<FinalTouchSummary>>(
            future: _allItemsFuture,
            builder: (context, itemSnapshot) {
              final rawItems = itemSnapshot.data ?? const <FinalTouchSummary>[];
              final items = itemSnapshot.hasData
                  ? _filterAndSortItems(rawItems)
                  : <FinalTouchSummary>[];

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                children: [
                  _HeaderCard(
                    title: title,
                    subtitle: subtitle,
                    count: total,
                    icon: Icons.folder_rounded,
                  ),
                  const SizedBox(height: 18),
                  if (_bookFolder != null) _Breadcrumb(text: _bookFolder!.name),
                  if (_bookFolder != null) const SizedBox(height: 12),
                  _SearchPanel(
                    controller: _searchController,
                    query: _searchQuery,
                    totalCount: rawItems.isEmpty ? total : rawItems.length,
                    resultCount: items.length,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    onClear: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  if (itemSnapshot.connectionState == ConnectionState.waiting)
                    const _InlineLoadingCard(
                      message: '전체 Final Touch 자료를 검색하는 중입니다.',
                    )
                  else if (itemSnapshot.hasError)
                    _InlineMessageCard(
                      icon: Icons.error_outline,
                      title: '검색 자료를 불러오지 못했습니다.',
                      message: '${itemSnapshot.error}',
                      onRetry: _reload,
                    )
                  else if (items.isEmpty)
                    const _MessageState(
                      icon: Icons.search_off_rounded,
                      title: '검색 결과가 없습니다.',
                      message: '다른 검색어를 입력해 주세요.',
                    )
                  else ...[
                    Text(
                      '검색 결과 ${items.length}개',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map(
                      (item) => _FinalTouchCard(
                        item: item,
                        onChanged: _reload,
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            _HeaderCard(
              title: title,
              subtitle: subtitle,
              count: total,
              icon: Icons.folder_rounded,
            ),
            const SizedBox(height: 18),
            if (_bookFolder != null) _Breadcrumb(text: _bookFolder!.name),
            if (_bookFolder != null) const SizedBox(height: 12),
            _SearchPanel(
              controller: _searchController,
              query: _searchQuery,
              totalCount: total,
              resultCount: total,
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
            const SizedBox(height: 14),
            _FolderGrid(
              folders: folders,
              onTap: _openFolder,
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemPage() {
    final future = _itemsFuture ?? _service.fetchFinalTouches();
    return FutureBuilder<List<FinalTouchSummary>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.error_outline,
            title: 'Final Touch를 불러오지 못했습니다.',
            message: '${snapshot.error}',
            buttonLabel: '다시 시도',
            onPressed: _reload,
          );
        }

        final rawItems = snapshot.data ?? const [];
        final items = _filterAndSortItems(rawItems);
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            _HeaderCard(
              title: _unitFolder?.name ?? '자료 목록',
              subtitle: '선택한 폴더의 분석 결과 ${items.length}개를 확인할 수 있습니다.',
              count: items.length,
              icon: Icons.auto_fix_high_rounded,
            ),
            const SizedBox(height: 18),
            if (_bookFolder != null)
              _Breadcrumb(text: '${_bookFolder!.name} / ${_unitFolder!.name}'),
            if (_bookFolder != null) const SizedBox(height: 12),
            _SearchPanel(
              controller: _searchController,
              query: _searchQuery,
              totalCount: rawItems.length,
              resultCount: items.length,
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Saved Analysis',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 12),
            if (rawItems.isEmpty)
              _MessageState(
                icon: Icons.folder_open_rounded,
                title: '이 폴더에는 Final Touch가 없습니다.',
                message: '다른 폴더를 선택하거나 새 분석 자료를 생성해 주세요.',
                buttonLabel: '상위 폴더',
                onPressed: _goBackLevel,
              )
            else if (items.isEmpty)
              const _MessageState(
                icon: Icons.search_off_rounded,
                title: '검색 결과가 없습니다.',
                message: '다른 검색어를 입력해 주세요.',
              )
            else
              ...items.map(
                (item) => _FinalTouchCard(
                  item: item,
                  onChanged: _reload,
                ),
              ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  Widget _headerCard(int count) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_fix_high_rounded,
              color: _blue,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Final Touch 모음',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '저장된 지문 분석 결과 $count개를 확인할 수 있습니다.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isTeacher = AuthStore.isTeacher;
    if (isTeacher) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0F766E),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF102A43),
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: Text(
                '총 $count개',
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final gradient = isTeacher
        ? const LinearGradient(
            colors: [Color(0xFF183B56), Color(0xFF0F766E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final primary =
        isTeacher ? const Color(0xFF0F766E) : _FinalTouchListScreenState._blue;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$subtitle ($count)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _FinalTouchListScreenState._muted,
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

  final List<FinalTouchFolder> folders;
  final ValueChanged<FinalTouchFolder> onTap;

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

  final FinalTouchFolder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTeacher = AuthStore.isTeacher;
    final iconBackground =
        isTeacher ? const Color(0xFFE0F2F1) : const Color(0xFFEFF6FF);
    final iconColor =
        isTeacher ? const Color(0xFF0F766E) : _FinalTouchListScreenState._blue;
    final borderColor =
        isTeacher ? const Color(0xFFCBD5E1) : _FinalTouchListScreenState._line;
    final arrowColor =
        isTeacher ? const Color(0xFF0F766E) : _FinalTouchListScreenState._muted;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
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
                color: iconBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: iconColor,
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
                      color: _FinalTouchListScreenState._ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${folder.count} items',
                    style: const TextStyle(
                      color: _FinalTouchListScreenState._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: arrowColor,
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

  final List<FinalTouchFolder> folders;
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
            label: '전체',
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
        ? _FinalTouchListScreenState._blue
        : _FinalTouchListScreenState._muted;

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
                ? _FinalTouchListScreenState._blue
                : _FinalTouchListScreenState._line,
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
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineLoadingCard extends StatelessWidget {
  const _InlineLoadingCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _FinalTouchListScreenState._line),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _FinalTouchListScreenState._muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessageCard extends StatelessWidget {
  const _InlineMessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _FinalTouchListScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _FinalTouchListScreenState._blue),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _FinalTouchListScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: _FinalTouchListScreenState._muted,
              height: 1.45,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.query,
    required this.totalCount,
    required this.resultCount,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final int totalCount;
  final int resultCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isTeacher = AuthStore.isTeacher;
    final focusColor =
        isTeacher ? const Color(0xFF0F766E) : _FinalTouchListScreenState._blue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _FinalTouchListScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: '출처, 제목, 주제, 지문 내용으로 검색',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: '검색어 지우기',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: focusColor,
                  width: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallInfoChip(text: '전체 $totalCount개'),
              _SmallInfoChip(text: '검색 결과 $resultCount개'),
              const _SmallInfoChip(text: '최신순'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinalTouchCard extends StatefulWidget {
  const _FinalTouchCard({
    required this.item,
    required this.onChanged,
  });

  final FinalTouchSummary item;
  final VoidCallback onChanged;

  @override
  State<_FinalTouchCard> createState() => _FinalTouchCardState();
}

class _FinalTouchCardState extends State<_FinalTouchCard> {
  final _service = const FinalTouchService();
  final _practiceResultService = const FinalTouchPracticeResultService();
  final _assignmentService = const LearningAssignmentService();
  Future<FinalTouchPracticeResult?>? _latestPracticeFuture;
  Future<List<LearningAssignment>>? _assignmentStatusFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (AuthStore.isStudent) {
      _latestPracticeFuture =
          _practiceResultService.fetchLatest(widget.item.id);
    }
    if (AuthStore.isTeacher) {
      _assignmentStatusFuture =
          _assignmentService.fetchTeacherFinalTouchStatus(widget.item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final title = item.titleEn.trim().isNotEmpty ? item.titleEn : item.titleKo;
    final topic = item.topicKo.trim().isNotEmpty ? item.topicKo : item.topicEn;

    final isTeacher = AuthStore.isTeacher;
    final primary =
        isTeacher ? const Color(0xFF183B56) : _FinalTouchListScreenState._blue;
    final soft = isTeacher ? const Color(0xFFE0F2F1) : const Color(0xFFEFF6FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _FinalTouchListScreenState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.article_rounded,
                  color: primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.source.trim().isEmpty
                          ? 'Final Touch #${item.id}'
                          : item.source,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _FinalTouchListScreenState._ink,
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _SmallInfoChip(text: item.folderName),
                        if (item.createdAt.trim().isNotEmpty)
                          _SmallInfoChip(
                            text: '생성일 ${_formatDateText(item.createdAt)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CardField(label: '제목', value: title),
          const SizedBox(height: 9),
          _CardField(label: '주제', value: topic),
          if (AuthStore.isStudent) ...[
            const SizedBox(height: 13),
            _CardPracticeResult(future: _latestPracticeFuture),
          ],
          if (AuthStore.isTeacher) ...[
            const SizedBox(height: 13),
            _TeacherCardAssignmentSummary(future: _assignmentStatusFuture),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CardActionButton(
                icon: Icons.open_in_new_rounded,
                label: '상세 보기',
                onPressed: _busy ? null : _openDetail,
              ),
              _CardActionButton(
                icon: Icons.print_outlined,
                label: 'PDF',
                onPressed: _busy ? null : _printPdf,
              ),
              _CardActionButton(
                icon: Icons.extension_rounded,
                label: '문장 조립',
                onPressed: _busy ? null : _openPractice,
              ),
              if (AuthStore.isTeacher)
                _CardActionButton(
                  icon: Icons.send_rounded,
                  label: '학생에게 배포',
                  onPressed: _busy ? null : _openAssignDialog,
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinalTouchDetailScreen(id: widget.item.id),
      ),
    );
  }

  Future<void> _openAssignDialog() async {
    final result = await showDialog<AssignmentCreateResult>(
      context: context,
      builder: (_) => TeacherAssignmentDialog(finalTouch: widget.item),
    );
    if (result == null || !mounted) return;
    setState(() {
      _assignmentStatusFuture =
          _assignmentService.fetchTeacherFinalTouchStatus(widget.item.id);
    });
    final skipped =
        result.skippedCount > 0 ? ' · ${result.skippedCount}명은 이미 배포됨' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.createdCount}명에게 배포했습니다$skipped'),
        action: SnackBarAction(
          label: '현황 보기',
          onPressed: _openDetail,
        ),
      ),
    );
  }

  Future<FinalTouchDetail?> _loadDetail() async {
    setState(() => _busy = true);
    try {
      return await _service.fetchFinalTouch(widget.item.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Final Touch 상세를 불러오지 못했습니다: $error')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _printPdf() async {
    final detail = await _loadDetail();
    if (detail == null) return;
    try {
      await FinalTouchPdfGenerator.previewOrPrint(
        FinalTouchReport.fromDetail(detail),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 생성 중 오류가 발생했습니다: $error')),
      );
    }
  }

  Future<void> _openPractice() async {
    final detail = await _loadDetail();
    if (detail == null || !mounted) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FinalTouchSentencePracticeScreen(detail: detail),
      ),
    );
    if (changed == true && mounted && AuthStore.isStudent) {
      setState(() {
        _latestPracticeFuture =
            _practiceResultService.fetchLatest(widget.item.id);
      });
      widget.onChanged();
    }
  }
}

class _CardField extends StatelessWidget {
  const _CardField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _FinalTouchListScreenState._ink,
          height: 1.45,
          fontSize: 14,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: _FinalTouchListScreenState._blue,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: value.trim().isEmpty ? '-' : value.trim(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CardPracticeResult extends StatelessWidget {
  const _CardPracticeResult({required this.future});

  final Future<FinalTouchPracticeResult?>? future;

  @override
  Widget build(BuildContext context) {
    final future = this.future;
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<FinalTouchPracticeResult?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _PracticeNote(text: '최근 문장 조립 기록을 확인하는 중입니다.');
        }
        if (snapshot.hasError) {
          return const _PracticeNote(text: '최근 기록 불러오기 실패');
        }
        final result = snapshot.data;
        if (result == null) {
          return const _PracticeNote(text: '아직 문장 조립 연습 기록 없음');
        }
        final wrong = result.wrongTypes.isEmpty
            ? '보완 없음'
            : '보완: ${result.wrongTypes.map(_practiceTypeLabelForDetail).join(', ')}';
        return _PracticeNote(
          text:
              '최근 결과: ${result.totalQuestions}문제 중 ${result.correctCount}문제 정답 · 정답률 ${result.accuracyRate.round()}% · $wrong',
        );
      },
    );
  }
}

class _PracticeNote extends StatelessWidget {
  const _PracticeNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _FinalTouchListScreenState._muted,
          height: 1.45,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _FinalTouchListScreenState._blue,
        side: const BorderSide(color: Color(0xFFBFDBFE)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _TeacherCardAssignmentSummary extends StatelessWidget {
  const _TeacherCardAssignmentSummary({required this.future});

  final Future<List<LearningAssignment>>? future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LearningAssignment>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TeacherSummaryBox(text: '배포 현황 확인 중...');
        }
        if (snapshot.hasError) {
          return const _TeacherSummaryBox(text: '배포 현황을 불러오지 못했습니다.');
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const _TeacherSummaryBox(text: '배포 현황: 아직 배포 없음');
        }
        final completed = items.where((item) => item.isCompleted).length;
        final inProgress = items.where((item) => item.isInProgress).length;
        final assigned = items.where((item) => item.isAssigned).length;
        return _TeacherSummaryBox(
          text:
              '배포 ${items.length}명 · 완료 $completed · 진행 중 $inProgress · 미시작 $assigned',
          emphasized: true,
        );
      },
    );
  }
}

class _TeacherSummaryBox extends StatelessWidget {
  const _TeacherSummaryBox({
    required this.text,
    this.emphasized = false,
  });

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: emphasized ? const Color(0xFFE0F2F1) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: emphasized ? const Color(0xFF99F6E4) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.manage_accounts_rounded,
            color: Color(0xFF0F766E),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  const _SmallInfoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.trim().isEmpty ? '-' : text.trim(),
        style: const TextStyle(
          color: _FinalTouchListScreenState._muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class FinalTouchDetailScreen extends StatefulWidget {
  const FinalTouchDetailScreen({
    super.key,
    required this.id,
    this.assignment,
  });

  final int id;
  final LearningAssignment? assignment;

  @override
  State<FinalTouchDetailScreen> createState() => _FinalTouchDetailScreenState();
}

class _FinalTouchDetailScreenState extends State<FinalTouchDetailScreen> {
  final _service = const FinalTouchService();
  final _practiceResultService = const FinalTouchPracticeResultService();
  final _assignmentService = const LearningAssignmentService();
  late Future<FinalTouchDetail> _future;
  Future<FinalTouchPracticeResult?>? _latestPracticeFuture;
  Future<List<LearningAssignment>>? _assignmentStatusFuture;
  LearningAssignment? _assignment;
  bool _completeBusy = false;

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
    _future = _service.fetchFinalTouch(widget.id);
    if (AuthStore.isTeacher) {
      _assignmentStatusFuture =
          _assignmentService.fetchTeacherFinalTouchStatus(widget.id);
    }
    _reloadPracticeResult();
  }

  void _reloadPracticeResult() {
    _latestPracticeFuture = AuthStore.isStudent
        ? _practiceResultService.fetchLatest(widget.id)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FinalTouchListScreenState._surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _FinalTouchListScreenState._ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Final Touch 상세',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<FinalTouchDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline,
              title: '상세 결과를 불러오지 못했습니다.',
              message: '${snapshot.error}',
              buttonLabel: '뒤로가기',
              onPressed: () => Navigator.pop(context),
            );
          }

          final item = snapshot.data;
          if (item == null) {
            return const _MessageState(
              icon: Icons.inventory_2_outlined,
              title: '데이터가 없습니다.',
              message: 'Final Touch 결과를 찾을 수 없습니다.',
            );
          }

          final teacherPrimary = AuthStore.isTeacher
              ? const Color(0xFF183B56)
              : _FinalTouchListScreenState._blue;
          final teacherTeal = AuthStore.isTeacher
              ? const Color(0xFF0F766E)
              : _FinalTouchListScreenState._blue;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _DetailHeader(item: item),
              if (_assignment != null) ...[
                const SizedBox(height: 14),
                _StudentAssignmentNotice(
                  assignment: _assignment!,
                  isBusy: _completeBusy,
                  onComplete: _assignment!.isCompleted
                      ? null
                      : () => _confirmCompleteAssignment(),
                ),
              ],
              if (AuthStore.isTeacher) ...[
                const SizedBox(height: 14),
                _TeacherAssignmentStatusCard(
                  future: _assignmentStatusFuture,
                  onAssign: () => _openAssignDialog(item),
                  onChanged: _reloadAssignmentStatus,
                ),
              ],
              const SizedBox(height: 14),
              FinalTouchFullBracketedPassage(
                body: item.passageBracketed.isNotEmpty
                    ? item.passageBracketed
                    : item.passage,
                plainBody: item.passage,
                sentenceDetails: item.sentenceDetails,
                topic: _preferredAnalysisText(item.topicKo, item.topicEn),
                title: _preferredAnalysisText(item.titleKo, item.titleEn),
                gist: _preferredAnalysisText(item.gistKo, item.gistEn),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: () => _printPdf(item),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('PDF 출력'),
                  style: FilledButton.styleFrom(
                    backgroundColor: teacherPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FinalTouchSentencePracticeScreen(
                          detail: item,
                        ),
                      ),
                    );
                    if (changed == true && mounted) {
                      setState(_reloadPracticeResult);
                    }
                  },
                  icon: const Icon(Icons.extension_rounded),
                  label: const Text('문장 조립 연습'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: teacherTeal,
                    side: BorderSide(
                      color: AuthStore.isTeacher
                          ? const Color(0xFF99F6E4)
                          : const Color(0xFFBFDBFE),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _PracticeLatestResultCard(
                isStudent: AuthStore.isStudent,
                latestFuture: _latestPracticeFuture,
              ),
              const SizedBox(height: 14),
              _FlowSection(outline: item.outline),
              const SizedBox(height: 14),
              FinalTouchCoreAnalysis(
                topicEn: item.topicEn,
                topicKo: item.topicKo,
                titleEn: item.titleEn,
                titleKo: item.titleKo,
                gistEn: item.gistEn,
                gistKo: item.gistKo,
              ),
              const SizedBox(height: 14),
              FinalTouchSentenceAnalysis(details: item.sentenceDetails),
            ],
          );
        },
      ),
    );
  }

  Future<void> _printPdf(FinalTouchDetail item) async {
    try {
      await FinalTouchPdfGenerator.previewOrPrint(
        FinalTouchReport.fromDetail(item),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF 생성 중 오류가 발생했습니다.')),
      );
    }
  }

  void _reloadAssignmentStatus() {
    _reloadAssignmentStatus();
  }

  Future<void> _openAssignDialog(FinalTouchSummary item) async {
    final result = await showDialog<AssignmentCreateResult>(
      context: context,
      builder: (_) => TeacherAssignmentDialog(finalTouch: item),
    );
    if (result == null || !mounted) return;
    _reloadAssignmentStatus();
    final skipped =
        result.skippedCount > 0 ? ' · ${result.skippedCount}명은 이미 배포됨' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.createdCount}명에게 배포했습니다$skipped'),
        action: SnackBarAction(
          label: '배포현황 보기',
          onPressed: _reloadAssignmentStatus,
        ),
      ),
    );
  }

  Future<void> _confirmCompleteAssignment() async {
    final assignment = _assignment;
    if (assignment == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => const _StudentCompleteDialog(),
    );
    if (ok != true) return;

    setState(() => _completeBusy = true);
    try {
      final updated =
          await _assignmentService.completeAssignment(assignment.id);
      if (!mounted) return;
      setState(() => _assignment = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학습 완료로 저장했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('완료 처리 실패: $error')),
      );
    } finally {
      if (mounted) setState(() => _completeBusy = false);
    }
  }
}

class _StudentAssignmentNotice extends StatelessWidget {
  const _StudentAssignmentNotice({
    required this.assignment,
    required this.isBusy,
    required this.onComplete,
  });

  final LearningAssignment assignment;
  final bool isBusy;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_ind_rounded,
                color: _FinalTouchListScreenState._blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  assignment.isCompleted ? '완료한 배포 학습입니다.' : '선생님이 배포한 학습입니다.',
                  style: const TextStyle(
                    color: _FinalTouchListScreenState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallInfoChip(
                  text: '상태 ${_assignmentStatusLabel(assignment.status)}'),
              if ((assignment.dueAt ?? '').isNotEmpty)
                _SmallInfoChip(
                    text: '마감 ${_formatDateText(assignment.dueAt!)}'),
              if ((assignment.teacherName ?? '').isNotEmpty)
                _SmallInfoChip(text: '선생님 ${assignment.teacherName}'),
            ],
          ),
          if ((assignment.teacherMessage ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              assignment.teacherMessage!,
              style: const TextStyle(
                color: _FinalTouchListScreenState._muted,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: isBusy ? null : onComplete,
              icon: Icon(assignment.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.done_rounded),
              label: Text(assignment.isCompleted ? '학습 완료됨' : '학습 완료'),
              style: FilledButton.styleFrom(
                backgroundColor: assignment.isCompleted
                    ? const Color(0xFF16A34A)
                    : _FinalTouchListScreenState._blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCompleteDialog extends StatelessWidget {
  const _StudentCompleteDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: _FinalTouchListScreenState._blue,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '학습 완료',
              style: TextStyle(
                color: _FinalTouchListScreenState._ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '이 Final Touch 학습을 완료 처리할까요?',
              style: TextStyle(
                color: _FinalTouchListScreenState._ink,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '완료 후 내 학습 화면에서 상태가 완료로 표시됩니다.',
              style: TextStyle(
                color: _FinalTouchListScreenState._muted,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _FinalTouchListScreenState._blue,
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('계속 학습'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _FinalTouchListScreenState._blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('완료하기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherAssignmentStatusCard extends StatefulWidget {
  const _TeacherAssignmentStatusCard({
    required this.future,
    required this.onAssign,
    required this.onChanged,
  });

  final Future<List<LearningAssignment>>? future;
  final VoidCallback onAssign;
  final VoidCallback onChanged;

  @override
  State<_TeacherAssignmentStatusCard> createState() =>
      _TeacherAssignmentStatusCardState();
}

class _TeacherAssignmentStatusCardState
    extends State<_TeacherAssignmentStatusCard> {
  final _service = const LearningAssignmentService();
  final _searchController = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LearningAssignment> _filterItems(List<LearningAssignment> items) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = items.where((item) {
      final status = item.displayStatus ?? item.status;
      final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
      final target = [
        item.studentName,
        item.studentId.toString(),
        item.assignedAt,
        item.dueAt,
        item.completedAt,
      ].whereType<String>().join(' ').toLowerCase();
      return matchesStatus && (query.isEmpty || target.contains(query));
    }).toList();

    const order = {
      'assigned': 0,
      'overdue': 1,
      'in_progress': 2,
      'completed': 3,
    };
    filtered.sort((a, b) {
      final aStatus = a.displayStatus ?? a.status;
      final bStatus = b.displayStatus ?? b.status;
      final byStatus = (order[aStatus] ?? 9).compareTo(order[bStatus] ?? 9);
      if (byStatus != 0) return byStatus;
      return b.assignedAt.compareTo(a.assignedAt);
    });
    return filtered;
  }

  Future<void> _confirmCancel(LearningAssignment item) async {
    if (item.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('완료된 배포 학습은 취소할 수 없습니다.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('배포 취소'),
        content: Text(
          '${item.studentName ?? '학생'}에게 배포한 학습을 취소할까요?\n'
          '취소하면 학생의 내 학습 목록에서 제거됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.cancelTeacherAssignment(item.id);
      if (!mounted) return;
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('배포를 취소했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('배포 취소 실패: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF183B56),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.manage_accounts_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '배포 현황',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '학생별 미시작, 진행 중, 완료 상태를 확인합니다.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onAssign,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('학생에게 배포'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<List<LearningAssignment>>(
              future: widget.future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    '배포 현황을 불러오지 못했습니다: ${snapshot.error}',
                    style: const TextStyle(
                        color: _FinalTouchListScreenState._muted),
                  );
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const Text(
                    '아직 배포된 학생이 없습니다.',
                    style: TextStyle(
                      color: _FinalTouchListScreenState._muted,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                final completed =
                    items.where((item) => item.isCompleted).length;
                final inProgress =
                    items.where((item) => item.isInProgress).length;
                final assigned = items.where((item) => item.isAssigned).length;
                final visibleItems = _filterItems(items);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TeacherMetricPill(
                            label: '총', value: '${items.length}명'),
                        _TeacherMetricPill(label: '완료', value: '$completed명'),
                        _TeacherMetricPill(
                            label: '진행 중', value: '$inProgress명'),
                        _TeacherMetricPill(label: '미시작', value: '$assigned명'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TeacherAssignmentTools(
                      controller: _searchController,
                      selectedStatus: _statusFilter,
                      onStatusChanged: (value) =>
                          setState(() => _statusFilter = value),
                      onSearchChanged: (_) => setState(() {}),
                      onClear: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    if (visibleItems.isEmpty)
                      const _InlineMessageCard(
                        icon: Icons.search_off_rounded,
                        title: '조건에 맞는 학생이 없습니다.',
                        message: '상태 필터나 검색어를 다시 확인해 주세요.',
                      )
                    else
                      ...visibleItems.map(
                        (item) => _TeacherAssignmentStudentRow(
                          item: item,
                          onCancel: item.isCompleted
                              ? null
                              : () => _confirmCancel(item),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherMetricPill extends StatelessWidget {
  const _TeacherMetricPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF102A43),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherAssignmentTools extends StatelessWidget {
  const _TeacherAssignmentTools({
    required this.controller,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    const statuses = [
      ('all', '전체'),
      ('assigned', '미시작'),
      ('in_progress', '진행 중'),
      ('completed', '완료'),
      ('overdue', '마감 지남'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: '학생 이름 또는 이메일 검색',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.trim().isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF0F766E), width: 1.3),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in statuses)
              ChoiceChip(
                label: Text(entry.$2),
                selected: selectedStatus == entry.$1,
                onSelected: (_) => onStatusChanged(entry.$1),
                selectedColor: const Color(0xFFE0F2F1),
                backgroundColor: const Color(0xFFF8FAFC),
                labelStyle: TextStyle(
                  color: selectedStatus == entry.$1
                      ? const Color(0xFF0F766E)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selectedStatus == entry.$1
                      ? const Color(0xFF5EEAD4)
                      : const Color(0xFFE2E8F0),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TeacherAssignmentStudentRow extends StatelessWidget {
  const _TeacherAssignmentStudentRow({
    required this.item,
    this.onCancel,
  });

  final LearningAssignment item;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final status = item.displayStatus ?? item.status;
    final dateText = item.completedAt?.isNotEmpty == true
        ? '완료 ${_formatDateText(item.completedAt!)}'
        : item.dueAt?.isNotEmpty == true
            ? '마감 ${_formatDateText(item.dueAt!)}'
            : '배포 ${_formatDateText(item.assignedAt)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF0F766E),
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.studentName ?? '학생',
                  style: const TextStyle(
                    color: Color(0xFF102A43),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateText,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _AssignmentStatusPill(status: status),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: onCancel == null
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFFDC2626),
              side: BorderSide(
                color: onCancel == null
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFFFCA5A5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}

class _AssignmentStatusPill extends StatelessWidget {
  const _AssignmentStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => const Color(0xFF16A34A),
      'in_progress' => _FinalTouchListScreenState._blue,
      'overdue' => const Color(0xFFEA580C),
      _ => _FinalTouchListScreenState._muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _assignmentStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PracticeLatestResultCard extends StatelessWidget {
  const _PracticeLatestResultCard({
    required this.isStudent,
    required this.latestFuture,
  });

  final bool isStudent;
  final Future<FinalTouchPracticeResult?>? latestFuture;

  @override
  Widget build(BuildContext context) {
    if (!isStudent) {
      return const _DetailCard(
        child: _PracticeStatusBody(
          icon: Icons.visibility_outlined,
          title: '문장 조립 연습',
          message: '교사용 미리보기에서는 학생 연습 결과가 저장되지 않습니다.',
        ),
      );
    }

    final future = latestFuture;
    if (future == null) {
      return const _DetailCard(
        child: _PracticeStatusBody(
          icon: Icons.extension_rounded,
          title: '문장 조립 연습',
          message: '아직 문장 조립 연습 기록이 없습니다.',
        ),
      );
    }

    return FutureBuilder<FinalTouchPracticeResult?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _DetailCard(
            child: _PracticeStatusBody(
              icon: Icons.extension_rounded,
              title: '문장 조립 연습',
              message: '최근 연습 기록을 불러오는 중입니다.',
            ),
          );
        }

        if (snapshot.hasError) {
          return _DetailCard(
            child: _PracticeStatusBody(
              icon: Icons.error_outline,
              title: '문장 조립 연습',
              message: '최근 연습 기록을 불러오지 못했습니다.',
              footnote: '${snapshot.error}',
            ),
          );
        }

        final result = snapshot.data;
        if (result == null) {
          return const _DetailCard(
            child: _PracticeStatusBody(
              icon: Icons.extension_rounded,
              title: '문장 조립 연습',
              message: '아직 문장 조립 연습 기록이 없습니다.',
            ),
          );
        }

        final accuracy = result.accuracyRate.round();
        final wrongText = result.wrongTypes.isEmpty
            ? '보완 유형 없음'
            : result.wrongTypes.map(_practiceTypeLabelForDetail).join(', ');
        return _DetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PracticeStatusHeader(
                icon: Icons.extension_rounded,
                title: '문장 조립 연습 최근 결과',
              ),
              const SizedBox(height: 10),
              Text(
                '최근 결과: ${result.totalQuestions}문제 중 ${result.correctCount}문제 정답',
                style: const TextStyle(
                  color: _FinalTouchListScreenState._ink,
                  fontWeight: FontWeight.w900,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PracticeMiniChip(text: '정답률 $accuracy%'),
                  _PracticeMiniChip(text: wrongText),
                  if (result.createdAt != null)
                    _PracticeMiniChip(
                        text: _formatPracticeDate(result.createdAt!)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PracticeStatusBody extends StatelessWidget {
  const _PracticeStatusBody({
    required this.icon,
    required this.title,
    required this.message,
    this.footnote,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PracticeStatusHeader(icon: icon, title: title),
        const SizedBox(height: 9),
        Text(
          message,
          style: const TextStyle(
            color: _FinalTouchListScreenState._muted,
            height: 1.45,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (footnote != null && footnote!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            footnote!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _FinalTouchListScreenState._muted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _PracticeStatusHeader extends StatelessWidget {
  const _PracticeStatusHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _FinalTouchListScreenState._blue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _FinalTouchListScreenState._ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PracticeMiniChip extends StatelessWidget {
  const _PracticeMiniChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _FinalTouchListScreenState._blue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.item});

  final FinalTouchDetail item;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.source,
            style: const TextStyle(
              color: _FinalTouchListScreenState._ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.createdAt,
            style: const TextStyle(
              color: _FinalTouchListScreenState._muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

String _preferredAnalysisText(String korean, String english) {
  final primary = korean.trim();
  if (primary.isNotEmpty) return primary;
  return english.trim();
}

class _FlowSection extends StatelessWidget {
  const _FlowSection({required this.outline});

  final Map<String, String> outline;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DetailTitle('글의 흐름'),
          const SizedBox(height: 10),
          _FlowRow(label: '서론', value: outline['intro'] ?? ''),
          _FlowRow(label: '본론', value: outline['body'] ?? ''),
          _FlowRow(label: '결론', value: outline['conclusion'] ?? ''),
        ],
      ),
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: const TextStyle(
                color: _FinalTouchListScreenState._blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _FinalTouchListScreenState._ink,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTitle extends StatelessWidget {
  const _DetailTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _FinalTouchListScreenState._ink,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _FinalTouchListScreenState._line),
      ),
      child: child,
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: _FinalTouchListScreenState._blue),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _FinalTouchListScreenState._ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _FinalTouchListScreenState._muted),
            ),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onPressed,
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _practiceTypeLabelForDetail(String kind) {
  switch (kind) {
    case 'title':
      return '제목';
    case 'topic':
      return '주제';
    case 'gist':
      return '요지';
    default:
      return kind;
  }
}

String _formatPracticeDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}.${two(value.month)}.${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}

int _dateScore(String value) {
  final parsed = DateTime.tryParse(value.trim());
  if (parsed != null) return parsed.millisecondsSinceEpoch;
  return 0;
}

String _formatDateText(String value) {
  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) return value;
  String two(int number) => number.toString().padLeft(2, '0');
  return '${parsed.year}.${two(parsed.month)}.${two(parsed.day)}';
}

String _assignmentStatusLabel(String status) {
  return switch (status) {
    'completed' => '완료',
    'in_progress' => '진행 중',
    'overdue' => '마감 지남',
    _ => '미시작',
  };
}
