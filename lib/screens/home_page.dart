// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import '../services/analyzer_service.dart';
import 'mcq_quick_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _svc = AnalyzerService();

  // 필터 (기간)
  String _period = '7d';
  bool _loading = false;

  // KPI
  int _streakDays = 0;
  int _totalAnalyses = 0;
  int _learnedWords = 0;
  String _level = '-';

  // 차트 데이터
  List<String> _barLabels = [];
  List<int> _barValues = [];
  List<String> _donutLegends = [];
  List<int> _donutValues = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.fetchDashboard(period: _period);

      setState(() {
        _streakDays = data.streakDays;
        _totalAnalyses = data.totalAnalyses;
        _learnedWords = data.learnedWords;
        _level = data.level;

        _barLabels = data.wrongTypes.map((e) => e.label).toList();
        _barValues = data.wrongTypes.map((e) => e.count).toList();

        _donutLegends = data.ratios.map((e) => e.label).toList();
        _donutValues = data.ratios.map((e) => e.value).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('대시보드 로드 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // 필터 + 새로고침
            Row(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '7d', label: Text('7일')),
                    ButtonSegment(value: '30d', label: Text('30일')),
                    ButtonSegment(value: 'all', label: Text('전체')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) {
                    setState(() => _period = s.first);
                    _loadDashboard();
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: '새로고침',
                  onPressed: _loading ? null : _loadDashboard,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // KPI 4칸
            Row(
              children: [
                Expanded(
                    child: _KpiTile(title: '연속 학습', value: '$_streakDays일')),
                const SizedBox(width: 10),
                Expanded(
                    child: _KpiTile(title: '총 분석', value: '$_totalAnalyses회')),
                const SizedBox(width: 10),
                Expanded(
                    child: _KpiTile(title: '학습 단어', value: '$_learnedWords개')),
                const SizedBox(width: 10),
                Expanded(child: _KpiTile(title: '레벨', value: _level)),
              ],
            ),
            const SizedBox(height: 18),

            // 빠른 실행
            _QuickActions(
              onTapAnalyzer: () => widget.onOpenTab(0),
              onTapTopic: () => widget.onOpenTab(1),
              onTapWord: () => widget.onOpenTab(2),
              onTapChat: () => widget.onOpenTab(3),
            ),
            const SizedBox(height: 18),

            // 차트 2개
            Row(
              children: [
                Expanded(
                  child: _CardBox(
                    title: '유형별 오답',
                    child: _MiniBarChart(
                      data: _barValues.map((e) => e.toDouble()).toList(),
                      labels: _barLabels,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardBox(
                    title: '오답 내 비율',
                    child: _DonutChart(
                      values: _donutValues.map((e) => e.toDouble()).toList(),
                      legends: _donutLegends,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 다음 학습 추천 (예시)
            _CardBox(
              title: '다음 학습 추천',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NextItem(
                    emoji: '📝',
                    title: '문단분석 연습 계속하기',
                    subtitle: '어제 풀던 문단의 후속 문항이 준비되어 있어요.',
                    onTap: () => widget.onOpenTab(0),
                  ),
                  const SizedBox(height: 10),
                  _NextItem(
                    emoji: '🎯',
                    title: '파이널터치(주제/요지) 집중',
                    subtitle: '핵심 흐름을 잡는 연습을 10문제 추천해요.',
                    onTap: () => widget.onOpenTab(1),
                  ),
                  const SizedBox(height: 10),
                  _NextItem(
                    emoji: '🧩',
                    title: '유의어·반의어 퀴즈',
                    subtitle: '어제 약했던 어휘를 자동 구성했어요.',
                    onTap: () => widget.onOpenTab(2),
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

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onTapAnalyzer,
    required this.onTapTopic,
    required this.onTapWord,
    required this.onTapChat,
  });

  final VoidCallback onTapAnalyzer;
  final VoidCallback onTapTopic;
  final VoidCallback onTapWord;
  final VoidCallback onTapChat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
            child: _ActionTile(
                emoji: '📝',
                label: '문단분석',
                color: cs.primaryContainer,
                onTap: onTapAnalyzer)),
        const SizedBox(width: 12),
        Expanded(
            child: _ActionTile(
                emoji: '🎯',
                label: '주제/요지',
                color: cs.secondaryContainer,
                onTap: onTapTopic)),
        const SizedBox(width: 12),
        Expanded(
            child: _ActionTile(
                emoji: '🧩',
                label: '단어/유의어',
                color: cs.tertiaryContainer,
                onTap: onTapWord)),
        const SizedBox(width: 12),
        Expanded(
            child: _ActionTile(
                emoji: '💬',
                label: '챗봇',
                color: cs.surfaceTint.withValues(alpha: .25),
                onTap: onTapChat)),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            emoji: '🧠',
            label: '객관식(구조화)',
            color: cs.primaryContainer.withValues(alpha: .55),
            onTap: () => _openMcqQuick(context),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.emoji,
      required this.label,
      required this.color,
      required this.onTap});
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
            color: color.withValues(alpha: .65),
            borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: cs.onSurface, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.data, required this.labels});
  final List<double> data;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxV = (data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b))
        .clamp(1, double.infinity);
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: LayoutBuilder(builder: (context, c) {
            final barW = (c.maxWidth - (data.length - 1) * 6) /
                (data.isEmpty ? 1 : data.length);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < data.length; i++) ...[
                  Container(
                    width: barW,
                    height: 10 + (110 * (data[i] / maxV)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5EE7DF), Color(0xFFB490CA)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  if (i != data.length - 1) const SizedBox(width: 6),
                ],
              ],
            );
          }),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: labels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) => SizedBox(
              width: 56,
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.values, required this.legends});
  final List<double> values;
  final List<String> legends;

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final parts = total == 0
        ? values.map((_) => 0.0).toList()
        : values.map((v) => v / total).toList();

    final colors = [
      const Color(0xFF6EE7B7),
      const Color(0xFFA78BFA),
      const Color(0xFFFCA5A5),
      const Color(0xFFFCD34D),
      const Color(0xFF60A5FA),
      const Color(0xFFF472B6),
    ];

    final centerPercent = parts.isEmpty ? 0 : (parts[0] * 100);

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: CustomPaint(
            painter: _DonutPainter(parts: parts, colors: colors),
            child: Center(
              child: Text('${centerPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (var i = 0; i < legends.length && i < parts.length; i++)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                Text('${legends[i]} ${(parts[i] * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12)),
              ]),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.parts, required this.colors});
  final List<double> parts;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (parts.isEmpty) return;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 6;

    var start = -90 * (3.14159265 / 180); // 12시 방향
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;

    for (var i = 0; i < parts.length; i++) {
      final sweep = parts[i] * 2 * 3.14159265;
      paint.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
          sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.parts != parts || oldDelegate.colors != colors;
}

class _NextItem extends StatelessWidget {
  const _NextItem(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: .4),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12)),
                  ]),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

Future<void> _openMcqQuick(BuildContext context) async {
  final controller = TextEditingController();
  final word = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('객관식(구조화) 단어 입력'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '예) disrupt',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('생성'),
        ),
      ],
    ),
  );

  if (word == null || word.isEmpty) return;

  // API 호출 후 미리보기 화면으로 이동
  try {
    final svc = AnalyzerService();
    final mcq = await svc.generateWordMcqStruct(word);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => McqQuickPage(mcq: mcq, word: word)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('문항 생성 실패: $e')),
    );
  }
}
