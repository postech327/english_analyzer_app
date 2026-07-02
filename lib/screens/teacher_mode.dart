// lib/screens/teacher_mode.dart
import 'package:flutter/material.dart';

import '../config/auth_store.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard_overview_screen.dart';
import 'admin/admin_exam_auto_generate_screen.dart';
import 'admin/admin_student_summary_screen.dart';
import 'final_touch_list_screen.dart';
import 'teacher_folder_progress_screen.dart';
import 'teacher_mock_exam_list_screen.dart';
import 'teacher_mock_student_report_list_screen.dart';
import 'teacher_problem_sets_screen.dart';
import 'teacher_question_maker_screen.dart';
import 'teacher_workbook_list_screen.dart';
import 'teacher_vocabulary_list_screen.dart';
import 'text_analysis_hub_screen.dart';

class TeacherModePage extends StatelessWidget {
  const TeacherModePage({super.key});

  static const _brandBlue = Color(0xFF183B56);
  static const _teal = Color(0xFF0F766E);
  static const _slateBlue = Color(0xFF2F5D7C);
  static const _ink = Color(0xFF102A43);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Color(0xFFF4F7FA);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;

    return Scaffold(
      backgroundColor: _surface,
      drawer: isWide ? null : const Drawer(child: _Sidebar(compact: false)),
      body: Row(
        children: [
          if (isWide) const _Sidebar(compact: false),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  _TopBar(showMenuButton: !isWide),
                  const Expanded(child: _DashboardBody()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  static void showPreparing(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중입니다.')),
    );
  }

  static Future<void> confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '로그아웃하시겠습니까?',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            '현재 선생님 계정에서 로그아웃하고 로그인 화면으로 돌아갑니다.',
            style: TextStyle(color: _muted, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 88 : 256,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: TeacherModePage._line)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandHeader(),
              const SizedBox(height: 28),
              _NavItem(
                icon: Icons.dashboard_outlined,
                label: '오늘의 현황',
                selected: true,
                onTap: () => Navigator.maybePop(context),
              ),
              _NavItem(
                icon: Icons.article_outlined,
                label: '지문 분석',
                onTap: () {
                  Navigator.maybePop(context);
                  TeacherModePage.openPage(
                    context,
                    const TextAnalysisHubScreen(),
                  );
                },
              ),
              _NavItem(
                icon: Icons.auto_fix_high_outlined,
                label: 'Final Touch 모음',
                onTap: () {
                  Navigator.maybePop(context);
                  TeacherModePage.openPage(
                    context,
                    const FinalTouchListScreen(),
                  );
                },
              ),
              _NavItem(
                icon: Icons.edit_note_outlined,
                label: '문제 제작',
                onTap: () {
                  Navigator.maybePop(context);
                  TeacherModePage.openPage(
                    context,
                    const TeacherQuestionMakerScreen(),
                  );
                },
              ),
              _NavItem(
                icon: Icons.folder_copy_outlined,
                label: '문제세트 관리',
                onTap: () {
                  Navigator.maybePop(context);
                  TeacherModePage.openPage(
                    context,
                    const TeacherProblemSetsScreen(),
                  );
                },
              ),
              _NavItem(
                icon: Icons.assignment_outlined,
                label: '모의고사 관리',
                onTap: () {
                  Navigator.maybePop(context);
                  TeacherModePage.openPage(
                    context,
                    const TeacherMockExamListScreen(),
                  );
                },
              ),
              _NavItem(
                icon: Icons.query_stats_rounded,
                label: '모의고사 학생 리포트',
                onTap: () {
                  Navigator.maybePop(context);
                  TeacherModePage.openPage(
                    context,
                    const TeacherMockStudentReportListScreen(),
                  );
                },
              ),
              _NavItem(
                icon: Icons.groups_outlined,
                label: '학생 관리',
                onTap: () {
                  Navigator.maybePop(context);
                  TeacherModePage.openPage(
                    context,
                    const AdminStudentSummaryScreen(),
                  );
                },
              ),
              _NavItem(
                icon: Icons.timeline_rounded,
                label: '진도표',
                onTap: () {
                  Navigator.maybePop(context);
                  TeacherModePage.openPage(
                    context,
                    const TeacherFolderProgressScreen(),
                  );
                },
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                label: '결과 분석',
                onTap: () {
                  Navigator.maybePop(context);
                  TeacherModePage.openPage(
                    context,
                    const AdminDashboardOverviewScreen(),
                  );
                },
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: '설정',
                onTap: () {
                  Navigator.maybePop(context);
                  TeacherModePage.showPreparing(context);
                },
              ),
              const Spacer(),
              _NavItem(
                icon: Icons.logout_rounded,
                label: '로그아웃',
                onTap: () async {
                  Navigator.maybePop(context);
                  await TeacherModePage.confirmLogout(context);
                },
              ),
              const SizedBox(height: 8),
              const _SupportBox(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: TeacherModePage._brandBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.school_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPENIT',
                style: TextStyle(
                  color: TeacherModePage._ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '열린아카데미 영어',
                style: TextStyle(
                  color: TeacherModePage._muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? TeacherModePage._brandBlue : TeacherModePage._muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? TeacherModePage._brandBlue.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportBox extends StatelessWidget {
  const _SupportBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TeacherModePage._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '운영 메모',
            style: TextStyle(
              color: TeacherModePage._ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '오늘 생성한 자료와 시험 결과를 확인하고 수업 전 보완 지문을 준비하세요.',
            style: TextStyle(
              color: TeacherModePage._muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TeacherModePage._brandBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => TeacherModePage.openPage(
                context,
                const AdminExamAutoGenerateScreen(),
              ),
              child: const Text('시험지 자동 생성'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showMenuButton});

  final bool showMenuButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: TeacherModePage._line)),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 8),
          ],
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '선생님 운영 대시보드',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: TeacherModePage._ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '자료 제작, 문제세트, 학생 결과를 한 곳에서 관리합니다.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: TeacherModePage._muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: TeacherModePage._brandBlue,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => TeacherModePage.openPage(
              context,
              const TeacherQuestionMakerScreen(),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('새 자료'),
          ),
          const SizedBox(width: 14),
          const _TeacherProfileMenu(),
        ],
      ),
    );
  }
}

class _TeacherProfileMenu extends StatelessWidget {
  const _TeacherProfileMenu();

  @override
  Widget build(BuildContext context) {
    final nickname = AuthStore.nickname?.trim().isNotEmpty == true
        ? AuthStore.nickname!.trim()
        : 'teacher1';
    final initial = nickname.characters.isNotEmpty
        ? nickname.characters.first.toUpperCase()
        : 'T';

    return PopupMenuButton<String>(
      tooltip: '계정 메뉴',
      position: PopupMenuPosition.under,
      color: Colors.white,
      elevation: 14,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (value) async {
        if (value == 'profile' || value == 'settings') {
          TeacherModePage.showPreparing(context);
          return;
        }
        if (value == 'logout') {
          await TeacherModePage.confirmLogout(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: _ProfileMenuHeader(nickname: nickname, initial: initial),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'profile',
          child: _ProfileMenuRow(
            icon: Icons.person_outline_rounded,
            label: '내 정보',
          ),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: _ProfileMenuRow(
            icon: Icons.settings_outlined,
            label: '계정 설정',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: _ProfileMenuRow(
            icon: Icons.logout_rounded,
            label: '로그아웃',
            color: Color(0xFFDC2626),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: TeacherModePage._line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFE0F2F1),
              child: Text(
                initial,
                style: const TextStyle(
                  color: TeacherModePage._teal,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 126),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TeacherModePage._ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '선생님 계정',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: TeacherModePage._teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: TeacherModePage._muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuHeader extends StatelessWidget {
  const _ProfileMenuHeader({
    required this.nickname,
    required this.initial,
  });

  final String nickname;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: const Color(0xFFE0F2F1),
          child: Text(
            initial,
            style: const TextStyle(
              color: TeacherModePage._teal,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TeacherModePage._ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '선생님 계정',
                style: TextStyle(
                  color: TeacherModePage._teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.label,
    this.color = TeacherModePage._ink,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1120;
        final statColumns = constraints.maxWidth >= 900 ? 4 : 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroPanel(isWide: isWide),
              const SizedBox(height: 18),
              const _TeacherFeatureMenuSection(),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: statColumns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: constraints.maxWidth >= 900 ? 1.35 : 1.15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _MetricCard(
                    label: '오늘 생성한 자료',
                    value: '-',
                    change: '데이터 준비 중',
                    icon: Icons.description_outlined,
                    tint: TeacherModePage._brandBlue,
                  ),
                  _MetricCard(
                    label: '진행 중 문제세트',
                    value: '-',
                    change: '데이터 준비 중',
                    icon: Icons.pending_actions_outlined,
                    tint: TeacherModePage._teal,
                  ),
                  _MetricCard(
                    label: '완료된 문제세트',
                    value: '-',
                    change: '데이터 준비 중',
                    icon: Icons.task_alt_outlined,
                    tint: Color(0xFF16A34A),
                  ),
                  _MetricCard(
                    label: '최근 시험 평균',
                    value: '-',
                    change: '데이터 준비 중',
                    icon: Icons.insights_outlined,
                    tint: Color(0xFFEA580C),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (isWide)
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _ProblemSetTableCard()),
                    SizedBox(width: 18),
                    Expanded(flex: 4, child: _RecentTouchCard()),
                  ],
                )
              else ...[
                const _ProblemSetTableCard(),
                const SizedBox(height: 18),
                const _RecentTouchCard(),
              ],
              const SizedBox(height: 18),
              const _ExamResultCard(),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: isWide ? 1 : 0,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘 수업 운영',
                    style: TextStyle(
                      color: TeacherModePage._ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '오늘 사용할 주요 기능을 빠르게 실행해 보세요. 자료 제작, 문제세트 관리, 모의고사 리포트를 한 화면에서 운영합니다.',
                    style: TextStyle(
                      color: TeacherModePage._muted,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickAction(
                  icon: Icons.article_outlined,
                  label: '지문 분석',
                  onTap: () => TeacherModePage.openPage(
                    context,
                    const TextAnalysisHubScreen(),
                  ),
                ),
                _QuickAction(
                  icon: Icons.edit_note_outlined,
                  label: '문제 제작',
                  primary: true,
                  onTap: () => TeacherModePage.openPage(
                    context,
                    const TeacherQuestionMakerScreen(),
                  ),
                ),
                _QuickAction(
                  icon: Icons.folder_copy_outlined,
                  label: '문제세트',
                  onTap: () => TeacherModePage.openPage(
                    context,
                    const TeacherProblemSetsScreen(),
                  ),
                ),
                _QuickAction(
                  icon: Icons.assignment_outlined,
                  label: '모의고사',
                  onTap: () => TeacherModePage.openPage(
                    context,
                    const TeacherMockExamListScreen(),
                  ),
                ),
                _QuickAction(
                  icon: Icons.query_stats_rounded,
                  label: '학생 리포트',
                  onTap: () => TeacherModePage.openPage(
                    context,
                    const TeacherMockStudentReportListScreen(),
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

class _TeacherFeatureMenuSection extends StatelessWidget {
  const _TeacherFeatureMenuSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: '관리 메뉴',
          subtitle: '자료 제작, 평가 운영, 학생 관리를 역할별로 나누어 실행합니다.',
        ),
        const SizedBox(height: 14),
        _ToolGroup(
          icon: Icons.inventory_2_outlined,
          title: '자료 제작',
          subtitle: '지문 분석부터 문제세트 제작까지 수업 자료를 준비합니다.',
          color: TeacherModePage._brandBlue,
          maxColumns: 4,
          children: [
            _TeacherToolCard(
              title: '지문 분석',
              subtitle: '영어 지문을 분석하고 Final Touch 자료를 생성합니다.',
              icon: Icons.article_outlined,
              color: TeacherModePage._brandBlue,
              onTap: () => TeacherModePage.openPage(
                context,
                const TextAnalysisHubScreen(),
              ),
            ),
            _TeacherToolCard(
              title: 'Final Touch 모음',
              subtitle: '저장된 분석 자료를 교재와 단원별로 관리합니다.',
              icon: Icons.auto_fix_high_outlined,
              color: TeacherModePage._teal,
              onTap: () => TeacherModePage.openPage(
                context,
                const FinalTouchListScreen(),
              ),
            ),
            _TeacherToolCard(
              title: '문제 제작',
              subtitle: '지문을 바탕으로 내신 대비 문제를 자동 생성합니다.',
              icon: Icons.edit_note_outlined,
              color: TeacherModePage._slateBlue,
              onTap: () => TeacherModePage.openPage(
                context,
                const TeacherQuestionMakerScreen(),
              ),
            ),
            _TeacherToolCard(
              title: '문제세트 관리',
              subtitle: '생성된 문제세트를 확인하고 풀이 결과를 관리합니다.',
              icon: Icons.folder_copy_outlined,
              color: const Color(0xFF475569),
              onTap: () => TeacherModePage.openPage(
                context,
                const TeacherProblemSetsScreen(),
              ),
            ),
            _TeacherToolCard(
              title: '워크북 관리',
              subtitle: '여러 문제 유형을 묶어 학생용 워크북을 구성합니다.',
              icon: Icons.menu_book_outlined,
              color: const Color(0xFF0F766E),
              onTap: () => TeacherModePage.openPage(
                context,
                const TeacherWorkbookListScreen(),
              ),
            ),
            _TeacherToolCard(
              title: '단어장 관리',
              subtitle: '핵심 단어와 뜻을 등록하고 학생용 단어장을 게시합니다.',
              icon: Icons.translate_rounded,
              color: const Color(0xFF7C3AED),
              onTap: () => TeacherModePage.openPage(
                context,
                const TeacherVocabularyListScreen(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ToolGroup(
          icon: Icons.fact_check_outlined,
          title: '수업 및 평가',
          subtitle: '진도와 모의고사 결과를 확인하고 평가를 관리합니다.',
          color: TeacherModePage._teal,
          maxColumns: 3,
          children: [
            _TeacherToolCard(
              title: '진도표',
              subtitle: '학생별, 폴더별 학습 진행 상황을 확인합니다.',
              icon: Icons.timeline_rounded,
              color: const Color(0xFF16A34A),
              onTap: () => TeacherModePage.openPage(
                context,
                const TeacherFolderProgressScreen(),
              ),
            ),
            _TeacherToolCard(
              title: '모의고사 관리',
              subtitle: '실제 모의고사 문항을 업로드하고 관리합니다.',
              icon: Icons.assignment_outlined,
              color: const Color(0xFFEA580C),
              onTap: () => TeacherModePage.openPage(
                context,
                const TeacherMockExamListScreen(),
              ),
            ),
            _TeacherToolCard(
              title: '모의고사 학생 리포트',
              subtitle: '학생별 실전 모의고사 결과와 약점을 분석합니다.',
              icon: Icons.query_stats_rounded,
              color: const Color(0xFF0F766E),
              onTap: () => TeacherModePage.openPage(
                context,
                const TeacherMockStudentReportListScreen(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ToolGroup(
          icon: Icons.supervisor_account_outlined,
          title: '학생 관리',
          subtitle: '학생 계정과 학습 현황을 관리합니다.',
          color: const Color(0xFF475569),
          maxColumns: 1,
          maxContentWidth: 420,
          children: [
            _TeacherToolCard(
              title: '학생 관리',
              subtitle: '학생 계정과 학습 그룹을 관리합니다.',
              icon: Icons.groups_outlined,
              color: TeacherModePage._brandBlue,
              onTap: () => TeacherModePage.openPage(
                context,
                const AdminStudentSummaryScreen(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolGroup extends StatelessWidget {
  const _ToolGroup({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.maxColumns,
    required this.children,
    this.maxContentWidth,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int maxColumns;
  final List<Widget> children;
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: TeacherModePage._ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: TeacherModePage._muted,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: TeacherModePage._line),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final responsiveColumns = constraints.maxWidth >= 980
                    ? maxColumns
                    : constraints.maxWidth >= 620
                        ? 2
                        : 1;
                final columns = responsiveColumns.clamp(1, maxColumns).toInt();
                final grid = GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: children.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 132,
                  ),
                  itemBuilder: (context, index) => children[index],
                );

                if (maxContentWidth == null ||
                    constraints.maxWidth <= maxContentWidth!) {
                  return grid;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: children.length,
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: maxContentWidth!,
                    mainAxisExtent: 132,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) => children[index],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherToolCard extends StatelessWidget {
  const _TeacherToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.018),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color,
                    size: 15,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TeacherModePage._ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TeacherModePage._muted,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
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
            color: TeacherModePage._ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: TeacherModePage._muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SampleNotice extends StatelessWidget {
  const _SampleNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB45309),
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: TeacherModePage._teal,
          minimumSize: const Size(118, 44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: TeacherModePage._ink,
        minimumSize: const Size(118, 44),
        side: const BorderSide(color: TeacherModePage._line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: tint, size: 21),
                ),
                const Spacer(),
                Text(
                  change,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tint,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TeacherModePage._ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TeacherModePage._muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemSetTableCard extends StatelessWidget {
  const _ProblemSetTableCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      _ProblemSetRow('고2 5월 모의고사 빈칸', '수능 실전반', '진행 중', '18/24'),
      _ProblemSetRow('EBS Gateway 순서 배열', '고1 독해반', '검토 필요', '12/20'),
      _ProblemSetRow('윤리 지문 제목 추론', '고3 심화반', '완료', '31/31'),
      _ProblemSetRow('과학 기술 장문 독해', '고2 정규반', '배포 대기', '0/28'),
    ];

    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: '진행 중 문제세트',
              actionLabel: '전체 보기',
              onTap: () => TeacherModePage.openPage(
                context,
                const TeacherProblemSetsScreen(),
              ),
            ),
            const SizedBox(height: 8),
            const _SampleNotice(
              message: '실제 진행 데이터 연결 전까지 운영 화면 예시로 표시됩니다.',
            ),
            const SizedBox(height: 14),
            const _TableHeader(),
            const Divider(height: 1, color: TeacherModePage._line),
            ...rows.map((row) => _TableRowItem(row: row)),
          ],
        ),
      ),
    );
  }
}

class _ProblemSetRow {
  const _ProblemSetRow(this.title, this.group, this.status, this.progress);

  final String title;
  final String group;
  final String status;
  final String progress;
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: _HeaderText('자료명')),
          Expanded(flex: 2, child: _HeaderText('반')),
          Expanded(flex: 2, child: _HeaderText('상태')),
          SizedBox(width: 72, child: _HeaderText('진도')),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: TeacherModePage._muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TableRowItem extends StatelessWidget {
  const _TableRowItem({required this.row});

  final _ProblemSetRow row;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (row.status) {
      '완료' => const Color(0xFF16A34A),
      '검토 필요' => const Color(0xFFEA580C),
      '배포 대기' => const Color(0xFF64748B),
      _ => TeacherModePage._brandBlue,
    };

    return InkWell(
      onTap: () => TeacherModePage.openPage(
        context,
        const TeacherProblemSetsScreen(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                row.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TeacherModePage._ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                row.group,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TeacherModePage._muted,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    row.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                row.progress,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: TeacherModePage._ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTouchCard extends StatelessWidget {
  const _RecentTouchCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Contextual Influence on Art', '고2 독해반', '오늘 14:20'),
      ('Gene Editing Ethics', '수능 실전반', '어제 18:05'),
      ('Scientific Understanding', '고3 심화반', '05.13'),
    ];

    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: '최근 파이널터치',
              actionLabel: '열기',
              onTap: () => TeacherModePage.openPage(
                context,
                const FinalTouchListScreen(),
              ),
            ),
            const SizedBox(height: 8),
            const _SampleNotice(
              message: '최근 생성 자료 API 연결 전까지 예시 자료로 표시됩니다.',
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_fix_high_outlined,
                        color: TeacherModePage._brandBlue,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: TeacherModePage._ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.$2,
                            style: const TextStyle(
                              color: TeacherModePage._muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.$3,
                      style: const TextStyle(
                        color: TeacherModePage._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamResultCard extends StatelessWidget {
  const _ExamResultCard();

  @override
  Widget build(BuildContext context) {
    const results = [
      ('수능 실전반', '빈칸 추론', '78%', '오답률 높음'),
      ('고2 정규반', '주제 찾기', '86%', '안정권'),
      ('고3 심화반', '삽입/순서', '72%', '보강 필요'),
    ];

    return _AdminCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: '최근 시험 결과',
              actionLabel: '분석 보기',
              onTap: () => TeacherModePage.openPage(
                context,
                const AdminDashboardOverviewScreen(),
              ),
            ),
            const SizedBox(height: 8),
            const _SampleNotice(
              message: '시험 결과 통계 API 연결 전까지 예시 요약으로 표시됩니다.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: results
                  .map(
                    (item) => _ResultChip(
                      group: item.$1,
                      type: item.$2,
                      score: item.$3,
                      note: item.$4,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.group,
    required this.type,
    required this.score,
    required this.note,
  });

  final String group;
  final String type;
  final String score;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TeacherModePage._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherModePage._ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                score,
                style: const TextStyle(
                  color: TeacherModePage._brandBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            type,
            style: const TextStyle(
              color: TeacherModePage._muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: const TextStyle(
              color: TeacherModePage._muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: TeacherModePage._ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: TeacherModePage._brandBlue,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
          child: Text(actionLabel),
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
        border: Border.all(color: TeacherModePage._line),
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
