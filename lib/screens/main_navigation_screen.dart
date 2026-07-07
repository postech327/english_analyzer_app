import 'package:flutter/material.dart';

import '../config/auth_store.dart';
import '../services/auth_service.dart';
import 'final_touch_list_screen.dart';
import 'mypage_screen.dart';
import 'student/mock_exam_list_screen.dart';
import 'student/student_results_hub_screen.dart';
import 'student_dashboard_screen.dart';
import 'student_learning_lounge_screen.dart';
import 'student_learning_assignments_screen.dart';
import 'student_vocabulary_screens.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _muted = Color(0xFF64748B);
  static const _blue = Color(0xFF2563EB);
  static const _line = Color(0xFFE2E8F0);

  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final screens = [
      StudentDashboardScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      const StudentLearningLoungeScreen(),
      const MyPageScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _surface,
      drawer: _StudentDrawer(
        onHome: () => _selectTab(0),
        onMyPage: () => _selectTab(2),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                _BottomNavItem(
                  icon: Icons.home_rounded,
                  label: '홈',
                  selected: _currentIndex == 0,
                  onTap: () => _selectTab(0),
                ),
                _BottomNavItem(
                  icon: Icons.forum_rounded,
                  label: '커뮤니티',
                  selected: _currentIndex == 1,
                  onTap: () => _selectTab(1),
                ),
                _BottomNavItem(
                  icon: Icons.person_rounded,
                  label: '마이페이지',
                  selected: _currentIndex == 2,
                  onTap: () => _selectTab(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.maybePop(context);
    }
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }
}

class _StudentDrawer extends StatelessWidget {
  const _StudentDrawer({
    required this.onHome,
    required this.onMyPage,
  });

  final VoidCallback onHome;
  final VoidCallback onMyPage;

  @override
  Widget build(BuildContext context) {
    final nickname = AuthStore.nickname?.trim().isNotEmpty == true
        ? AuthStore.nickname!.trim()
        : 'student1';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          '학생 계정',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                children: [
                  _StudentDrawerItem(
                    icon: Icons.today_rounded,
                    label: '오늘의 학습',
                    onTap: onHome,
                  ),
                  _StudentDrawerItem(
                    icon: Icons.auto_fix_high_rounded,
                    label: 'Final Touch 복습',
                    onTap: () => _push(context, const FinalTouchListScreen()),
                  ),
                  _StudentDrawerItem(
                    icon: Icons.menu_book_rounded,
                    label: '워크북 학습',
                    onTap: () => _push(
                      context,
                      const StudentLearningAssignmentsScreen(),
                    ),
                  ),
                  _StudentDrawerItem(
                    icon: Icons.translate_rounded,
                    label: '단어장 학습',
                    onTap: () => _push(
                      context,
                      const StudentVocabularyListScreen(),
                    ),
                  ),
                  _StudentDrawerItem(
                    icon: Icons.assignment_turned_in_rounded,
                    label: '모의고사 풀기',
                    onTap: () => _push(context, const MockExamListScreen()),
                  ),
                  _StudentDrawerItem(
                    icon: Icons.bar_chart_rounded,
                    label: '내 결과',
                    onTap: () => _push(
                      context,
                      const StudentResultsHubScreen(),
                    ),
                  ),
                  _StudentDrawerItem(
                    icon: Icons.person_rounded,
                    label: '마이페이지',
                    onTap: onMyPage,
                  ),
                  const Divider(height: 24),
                  _StudentDrawerItem(
                    icon: Icons.logout_rounded,
                    label: '로그아웃',
                    danger: true,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.maybePop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  static Future<void> _logout(BuildContext context) async {
    Navigator.maybePop(context);
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}

class _StudentDrawerItem extends StatelessWidget {
  const _StudentDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFDC2626) : const Color(0xFF334155);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _MainNavigationScreenState._blue
        : _MainNavigationScreenState._muted;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? _MainNavigationScreenState._blue.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
