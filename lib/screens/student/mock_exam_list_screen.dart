import 'package:flutter/material.dart';

import '../../services/student_mock_exam_service.dart';
import 'mock_exam_take_screen.dart';

class MockExamListScreen extends StatefulWidget {
  const MockExamListScreen({super.key});

  @override
  State<MockExamListScreen> createState() => _MockExamListScreenState();
}

class _MockExamListScreenState extends State<MockExamListScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _blue = Color(0xFF2563EB);
  static const _line = Color(0xFFE5E7EB);

  String? _selectedGrade;
  int? _selectedYear;
  int? _selectedMonth;
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() {
    return StudentMockExamService.fetchMockExams();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _asText(dynamic value, [String fallback = '-']) {
    final text = value?.toString() ?? '';
    return text.trim().isEmpty || text == 'null' ? fallback : text;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mock Exam',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const [];
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  _headerCard(),
                  const SizedBox(height: 14),
                  _breadcrumbBar(),
                  const SizedBox(height: 14),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    _messageCard(
                      title: '목록을 불러오지 못했습니다.',
                      message: snapshot.error.toString(),
                    )
                  else if (items.isEmpty)
                    _messageCard(
                      title: '등록된 모의고사가 없습니다.',
                      message: '선생님이 업로드한 모의고사가 여기에 표시됩니다.',
                    )
                  else
                    _buildCurrentLevel(items),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '모의고사 목록',
            style: TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '학년, 연도, 월을 확인하고 20문항 모의고사를 시작하세요.',
            style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _breadcrumbBar() {
    final parts = ['Mock Exam'];
    if (_selectedGrade != null) parts.add(_selectedGrade!);
    if (_selectedYear != null) parts.add('$_selectedYear');
    if (_selectedMonth != null) parts.add('$_selectedMonth월');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          IconButton(
            tooltip: '상위 폴더',
            onPressed: _selectedGrade == null ? null : _goBackLevel,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              parts.join(' / '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLevel(List<dynamic> allItems) {
    if (_selectedGrade == null) {
      return _folderGrid(
        const ['고1', '고2', '고3'].map((grade) {
          return _FolderNode(
            title: grade,
            subtitle: '${_filterItems(allItems, grade: grade).length} exams',
            icon: Icons.school_outlined,
            onTap: () => setState(() => _selectedGrade = grade),
          );
        }).toList(),
      );
    }

    if (_selectedYear == null) {
      final years = _filterItems(allItems, grade: _selectedGrade)
          .map((item) => _asInt((item as Map)['year']))
          .where((year) => year > 0)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
      if (years.isEmpty) {
        return _messageCard(title: '연도 폴더가 없습니다.', message: '다른 학년을 선택해 주세요.');
      }
      return _folderGrid(
        years.map((year) {
          return _FolderNode(
            title: '$year',
            subtitle:
                '${_filterItems(allItems, grade: _selectedGrade, year: year).length} exams',
            icon: Icons.calendar_month_outlined,
            onTap: () => setState(() => _selectedYear = year),
          );
        }).toList(),
      );
    }

    if (_selectedMonth == null) {
      final months = _filterItems(
        allItems,
        grade: _selectedGrade,
        year: _selectedYear,
      )
          .map((item) => _asInt((item as Map)['month']))
          .where((month) => month > 0)
          .toSet()
          .toList()
        ..sort();
      if (months.isEmpty) {
        return _messageCard(title: '월 폴더가 없습니다.', message: '다른 연도를 선택해 주세요.');
      }
      return _folderGrid(
        months.map((month) {
          return _FolderNode(
            title: '$month월',
            subtitle:
                '${_filterItems(allItems, grade: _selectedGrade, year: _selectedYear, month: month).length} exams',
            icon: Icons.folder_rounded,
            onTap: () => setState(() => _selectedMonth = month),
          );
        }).toList(),
      );
    }

    final exams = _filterItems(
      allItems,
      grade: _selectedGrade,
      year: _selectedYear,
      month: _selectedMonth,
    );
    if (exams.isEmpty) {
      return _messageCard(
        title: '이 폴더에는 모의고사가 없습니다.',
        message: '다른 월 폴더를 선택해 주세요.',
      );
    }
    return Column(children: exams.map(_examCard).toList());
  }

  List<dynamic> _filterItems(
    List<dynamic> items, {
    String? grade,
    int? year,
    int? month,
  }) {
    return items.where((item) {
      final data = item as Map;
      if (grade != null && _asText(data['grade']) != grade) return false;
      if (year != null && _asInt(data['year']) != year) return false;
      if (month != null && _asInt(data['month']) != month) return false;
      return true;
    }).toList();
  }

  Widget _folderGrid(List<_FolderNode> folders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: folders.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 1 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: compact ? 3.2 : 2.25,
          ),
          itemBuilder: (context, index) => _folderCard(folders[index]),
        );
      },
    );
  }

  Widget _folderCard(_FolderNode folder) {
    return InkWell(
      onTap: folder.onTap,
      borderRadius: BorderRadius.circular(24),
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(folder.icon, color: _blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    folder.subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _examCard(dynamic item) {
    final data = item is Map ? item : const {};
    final id = _asInt(data['id']);
    final title = _asText(data['title'], '모의고사');
    final grade = _asText(data['grade']);
    final year = _asInt(data['year']);
    final month = _asInt(data['month']);
    final questionCount = _asInt(data['question_count']);
    final total = _asInt(data['total_questions'], 20);
    final isComplete = data['is_complete'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.assignment_rounded, color: _blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$grade · $year년 $month월',
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _pill('$questionCount/$total문항'),
              const SizedBox(width: 8),
              _pill(isComplete ? '응시 가능' : '등록 중'),
              const Spacer(),
              FilledButton.icon(
                onPressed: !isComplete || id <= 0
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MockExamTakeScreen(
                              mockExamId: id,
                              title: title,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start'),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _messageCard({required String title, required String message}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded, color: _blue, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
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
