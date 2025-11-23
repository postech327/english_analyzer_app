import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 홈 대시보드(간단 차트/지표 포함)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 데모용 더미 데이터 (필요 시 API 연결로 교체)
    const weeklyBars = [6, 3, 5, 7, 4, 2, 5]; // 요일별 학습량
    const trendLine = [40, 46, 42, 55, 58, 53, 60, 64, 62, 70]; // 성취 추세(%)

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _HeaderCard(
                  name: 'Student',
                  progress: 0.72, // 72%
                ),
              ),
            ),

            // 핵심 지표 카드 4개 (연속학습/총분석/학습단어/레벨)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                        child: _MetricCard(
                            label: '연속 학습',
                            value: '23일',
                            icon: Icons.local_fire_department)),
                    SizedBox(width: 12),
                    Expanded(
                        child: _MetricCard(
                            label: '총 분석',
                            value: '157회',
                            icon: Icons.analytics_outlined)),
                    SizedBox(width: 12),
                    Expanded(
                        child: _MetricCard(
                            label: '학습 단어',
                            value: '132개',
                            icon: Icons.auto_stories_outlined)),
                    SizedBox(width: 12),
                    Expanded(
                        child: _MetricCard(
                            label: '레벨',
                            value: 'B2',
                            icon: Icons.rocket_launch_outlined)),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 요일별 학습량 (막대 차트)
            const SliverToBoxAdapter(
              child: _Section(
                title: '요일별 학습량',
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _BarChart(
                  values: weeklyBars,
                  maxValue: 8,
                  labels: ['일', '월', '화', '수', '목', '금', '토'],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 성취 추세 (라인 차트)
            const SliverToBoxAdapter(
              child: _Section(
                title: '성취 추세',
                subtitle: '최근 10회 분석 결과(%)',
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SizedBox(
                  height: 160,
                  child: _LineChart(values: trendLine, min: 0, max: 100),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 바로 분석하기 CTA
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _Section(
                  title: '바로 분석하기',
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: '영어 문단을 붙여넣고 분석해 보세요',
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: .35),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/app', arguments: 0),
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('분석'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 상단 헤더(프로필 + 진행률 게이지)
class _HeaderCard extends StatelessWidget {
  final String name;
  final double progress;
  const _HeaderCard({required this.name, required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7), Color(0xFF91EAE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 26, child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, $name 👋',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                )),
                    Text('오늘도 한 걸음씩! 영어 분석을 시작해볼까요?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: .9),
                            )),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .85),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: .35),
            ),
          ),
        ],
      ),
    );
  }
}

/// 작은 지표 카드
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: .35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 6),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// 섹션 공통 래퍼
class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final EdgeInsetsGeometry padding;
  final Widget child;
  const _Section({
    required this.title,
    this.subtitle,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// 단순 막대 차트 (패키지 없이 구현)
class _BarChart extends StatelessWidget {
  final List<int> values;
  final int maxValue;
  final List<String> labels;
  const _BarChart(
      {required this.values, required this.maxValue, required this.labels});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bars = values.map((v) => (v / maxValue).clamp(0.0, 1.0)).toList();

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 20,
                      height: 120 * bars[i],
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(labels[i], style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// 단순 라인 차트 (CustomPainter)
class _LineChart extends StatelessWidget {
  final List<int> values;
  final double min;
  final double max;
  const _LineChart(
      {required this.values, required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _LineChartPainter(values, min, max, cs.primary),
      child: Container(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<int> values;
  final double min;
  final double max;
  final Color color;

  _LineChartPainter(this.values, this.min, this.max, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final bg = Paint()
      ..color = color.withOpacity(.12)
      ..style = PaintingStyle.fill;

    if (values.length < 2) return;

    // 좌/우 여백
    const padX = 12.0;
    final w = size.width - padX * 2;
    final h = size.height;

    double xFor(int i) => padX + (w * (i / (values.length - 1)));
    double yFor(int v) {
      final t = ((v - min) / math.max(1, (max - min))).clamp(0.0, 1.0);
      return h - (h * t);
    }

    final pts = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      pts.add(Offset(xFor(i), yFor(values[i])));
    }

    // 부드러운 곡선(간단한 quadratic)
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    // 영역 채우기
    final area = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(area, bg);

    // 선 그리기
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
