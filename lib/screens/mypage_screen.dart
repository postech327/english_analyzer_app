import 'package:flutter/material.dart';

import '../config/auth_store.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import 'final_touch_list_screen.dart';
import 'student/mock_exam_list_screen.dart';
import 'student/student_results_hub_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF64748B);
  static const _blue = Color(0xFF2563EB);
  static const _purple = Color(0xFF7C3AED);
  static const _line = Color(0xFFE2E8F0);

  late Future<Map<String, dynamic>> _profileFuture;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = CommunityService.fetchMyProfile();
  }

  Future<void> _reload() async {
    setState(() {
      _profileFuture = CommunityService.fetchMyProfile();
    });
    await _profileFuture;
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
          '마이페이지',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(onRetry: _reload);
          }

          final user = snapshot.data ?? const <String, dynamic>{};
          final nickname = _text(
            user['nickname'],
            fallback: AuthStore.nickname ?? 'student',
          );
          final level = _intValue(user['level'], fallback: 1);
          final points = _intValue(user['points']);
          final coins = _intValue(user['coins']);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
              children: [
                _ProfileHeroCard(
                  nickname: nickname,
                  level: level,
                ),
                const SizedBox(height: 14),
                _LearningStreakCard(),
                const SizedBox(height: 14),
                _StatusGrid(
                  level: level,
                  points: points,
                  coins: coins,
                ),
                const SizedBox(height: 14),
                _RecentActivityCard(),
                const SizedBox(height: 14),
                _QuickLinksCard(
                  onFinalTouch: () => _push(const FinalTouchListScreen()),
                  onMockExam: () => _push(const MockExamListScreen()),
                  onResults: () => _push(const StudentResultsHubScreen()),
                  onWrongReview: () => _push(const StudentResultsHubScreen()),
                ),
                const SizedBox(height: 14),
                _AccountCard(
                  nickname: nickname,
                  role: _text(user['role'], fallback: 'student'),
                  loggingOut: _loggingOut,
                  onNotification: () => _showSoon('알림 설정은 다음 단계에서 연결됩니다.'),
                  onLogout: _logout,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $error')),
      );
    }
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.nickname,
    required this.level,
  });

  final String nickname;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [_MyPageScreenState._blue, _MyPageScreenState._purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _MyPageScreenState._purple.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: _MyPageScreenState._blue,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
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
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '오늘도 차근차근 학습해 볼까요?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    'Lv. $level 학생',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
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

class _LearningStreakCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.local_fire_department_rounded,
            title: '연속 학습',
          ),
          SizedBox(height: 12),
          Text(
            '아직 오늘의 학습 기록을 확인할 수 없습니다.',
            style: TextStyle(
              color: _MyPageScreenState._ink,
              fontWeight: FontWeight.w800,
              height: 1.45,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Final Touch 복습이나 모의고사를 완료하면 학습 기록이 쌓입니다.',
            style: TextStyle(
              color: _MyPageScreenState._muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({
    required this.level,
    required this.points,
    required this.coins,
  });

  final int level;
  final int points;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final cards = [
          _MetricCard(
            icon: Icons.workspace_premium_rounded,
            label: '레벨',
            value: 'Lv. $level',
            color: _MyPageScreenState._blue,
          ),
          _MetricCard(
            icon: Icons.bolt_rounded,
            label: '포인트',
            value: '$points P',
            color: _MyPageScreenState._purple,
          ),
          _MetricCard(
            icon: Icons.monetization_on_rounded,
            label: '코인',
            value: '$coins',
            color: const Color(0xFF0F766E),
          ),
        ];

        if (compact) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                if (card != cards.last) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (final card in cards) ...[
              Expanded(child: card),
              if (card != cards.last) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.history_rounded,
            title: '최근 학습 활동',
          ),
          SizedBox(height: 12),
          _ActivityPlaceholder(
            title: '아직 최근 학습 활동이 없습니다.',
            message: 'Final Touch 복습이나 모의고사를 완료하면 이곳에 표시됩니다.',
          ),
        ],
      ),
    );
  }
}

class _QuickLinksCard extends StatelessWidget {
  const _QuickLinksCard({
    required this.onFinalTouch,
    required this.onMockExam,
    required this.onWrongReview,
    required this.onResults,
  });

  final VoidCallback onFinalTouch;
  final VoidCallback onMockExam;
  final VoidCallback onWrongReview;
  final VoidCallback onResults;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.near_me_rounded,
            title: '바로가기',
          ),
          const SizedBox(height: 12),
          _QuickLinkTile(
            icon: Icons.auto_stories_rounded,
            title: 'Final Touch 복습',
            subtitle: '저장된 분석 자료를 다시 확인해요.',
            onTap: onFinalTouch,
          ),
          _QuickLinkTile(
            icon: Icons.assignment_rounded,
            title: '모의고사 보기',
            subtitle: '20문항 실전 모의고사를 풀어 봐요.',
            onTap: onMockExam,
          ),
          _QuickLinkTile(
            icon: Icons.replay_rounded,
            title: '오답 다시보기',
            subtitle: '틀린 문제와 약점 유형을 점검해요.',
            onTap: onWrongReview,
          ),
          _QuickLinkTile(
            icon: Icons.insights_rounded,
            title: '학습 리포트',
            subtitle: '내신과 모의고사 결과를 한곳에서 확인해요.',
            onTap: onResults,
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.nickname,
    required this.role,
    required this.loggingOut,
    required this.onNotification,
    required this.onLogout,
  });

  final String nickname;
  final String role;
  final bool loggingOut;
  final VoidCallback onNotification;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.settings_rounded,
            title: '계정 / 설정',
          ),
          const SizedBox(height: 12),
          _AccountRow(
            icon: Icons.badge_outlined,
            title: '내 정보',
            subtitle: '$nickname · ${_roleLabel(role)}',
          ),
          _AccountRow(
            icon: Icons.notifications_none_rounded,
            title: '알림 설정',
            subtitle: '준비 중',
            onTap: onNotification,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: loggingOut ? null : onLogout,
              icon: loggingOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(loggingOut ? '로그아웃 중...' : '로그아웃'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _MyPageScreenState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _MyPageScreenState._blue, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: _MyPageScreenState._ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MyPageScreenState._line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _MyPageScreenState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: _MyPageScreenState._ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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

class _ActivityPlaceholder extends StatelessWidget {
  const _ActivityPlaceholder({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _MyPageScreenState._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _MyPageScreenState._ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            style: const TextStyle(
              color: _MyPageScreenState._muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  const _QuickLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _MyPageScreenState._line),
          ),
          child: Row(
            children: [
              Icon(icon, color: _MyPageScreenState._blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _MyPageScreenState._ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _MyPageScreenState._muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _MyPageScreenState._muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _MyPageScreenState._blue),
      title: Text(
        title,
        style: const TextStyle(
          color: _MyPageScreenState._ink,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded,
              color: _MyPageScreenState._muted),
      onTap: onTap,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: _MyPageScreenState._blue,
                size: 38,
              ),
              const SizedBox(height: 12),
              const Text(
                '프로필을 불러오지 못했습니다.',
                style: TextStyle(
                  color: _MyPageScreenState._ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _text(dynamic value, {String fallback = '-'}) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null') return fallback;
  return text;
}

int _intValue(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _roleLabel(String role) {
  switch (role.trim().toLowerCase()) {
    case 'teacher':
      return '선생님';
    case 'student':
      return '학생';
    case 'admin':
      return '관리자';
    default:
      return role.trim().isEmpty ? '학생' : role;
  }
}
