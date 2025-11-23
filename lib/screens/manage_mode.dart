// lib/screens/manage_mode.dart
import 'dart:math';
import 'package:flutter/material.dart';

class ManageModePage extends StatefulWidget {
  const ManageModePage({super.key});

  @override
  State<ManageModePage> createState() => _ManageModePageState();
}

class _ManageModePageState extends State<ManageModePage> {
  // ----- 샘플/플레이스홀더 데이터 -----
  // 좌측 "나의 클래스" 목록 (랜덤 생성 느낌의 플레이스홀더)
  final List<String> _classes = List.generate(
    18,
    (i) {
      const seeds = [
        '중2_리딩A',
        '중2_리스닝B',
        '중3_내신스킬',
        '고1_문법드릴',
        '고2_수능독해',
        '중1_스타터',
        '중3_파이널',
        '내신_심화1',
        '내신_심화2',
        '수특_라이트',
        '수완_핵심',
        'VOCA_마스터',
        '원서_프로젝트',
        '프리미엄_튜터',
        '주간_테스트',
        '주제요지_워크샵',
        '문장구조_집중',
        '실전모의_A'
      ];
      return '${seeds[i % seeds.length]} #${100 + i}';
    },
  );

  // 학생 샘플
  final List<String> _students = const [
    '박시우',
    '김한별',
    '서지원',
    '신도윤',
    '최연우',
    '이서율',
    '정하린',
  ];

  // 선택된 클래스 인덱스
  int _selectedClassIdx = 0;

  // 출결 집계(상단 카드) – 임시 값
  final Map<String, int> _stats = {
    '출석': 0,
    '결석': 0,
    '지각': 0,
    '조퇴': 0,
    '보강': 0,
  };

  // 출결 버튼 누를 때 사용할 색상/아이콘
  static const _statusMeta = <String, (IconData, Color)>{
    '출석': (Icons.check_circle, Color(0xFF2ecc71)),
    '결석': (Icons.cancel, Color(0xFFe74c3c)),
    '지각': (Icons.schedule, Color(0xFFf39c12)),
    '조퇴': (Icons.outbond, Color(0xFF16a085)),
    '보강': (Icons.autorenew, Color(0xFF9b59b6)),
  };

  void _setStatus(String student, String status) {
    // TODO: 여기에 실제 저장/요청 로직 연결
    setState(() {
      // 데모용: 해당 상태만 +1 증가
      _stats[status] = (_stats[status] ?? 0) + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$student: $status 처리 (데모)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리형 모드'),
        actions: [
          IconButton(
            tooltip: '새 클래스',
            onPressed: () {
              // TODO: 클래스 생성 다이얼로그
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('클래스 생성(데모)')),
              );
            },
            icon: const Icon(Icons.add_box_outlined),
          ),
          IconButton(
            tooltip: '검색',
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          // 사이드바 고정폭
          const sideWidth = 260.0;
          return Row(
            children: [
              // ------------------ 좌측: 나의 클래스 ------------------
              ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: sideWidth),
                child: Container(
                  color: cs.surfaceContainerHighest.withOpacity(.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SideHeader(),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _classes.length,
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final selected = i == _selectedClassIdx;
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () =>
                                  setState(() => _selectedClassIdx = i),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? cs.primaryContainer.withOpacity(.6)
                                      : cs.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor:
                                          cs.primary.withOpacity(.15),
                                      child: Text(
                                        // 간단한 초성 느낌으로 라벨
                                        _classes[i].characters.first,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _classes[i],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ------------------ 우측: 메인 보드 ------------------
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 선택된 클래스 타이틀
                      Text(
                        _classes[_selectedClassIdx],
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),

                      // 상단 출결 집계 카드 5개
                      _AttendanceSummaryRow(stats: _stats),

                      const SizedBox(height: 16),

                      // 학생 테이블
                      _StudentAttendanceTable(
                        students: _students,
                        onTap: _setStatus,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 사이드 헤더
class _SideHeader extends StatelessWidget {
  const _SideHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withOpacity(.5),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '나의 클래스',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withOpacity(.6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '관리',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// 상단 출결 요약
class _AttendanceSummaryRow extends StatelessWidget {
  final Map<String, int> stats;
  const _AttendanceSummaryRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    const items = ['출석', '결석', '지각', '조퇴', '보강'];
    const colors = [
      Color(0xFF2ecc71),
      Color(0xFFe74c3c),
      Color(0xFFf39c12),
      Color(0xFF16a085),
      Color(0xFF9b59b6),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 700;
        final children = List.generate(items.length, (i) {
          return _SummaryCard(
            title: items[i],
            value: stats[items[i]] ?? 0,
            color: colors[i],
          );
        });

        if (isNarrow) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: children
                .map((w) => SizedBox(
                      width: (c.maxWidth - 10) / 2,
                      child: w,
                    ))
                .toList(),
          );
        }

        return Row(
          children: children
              .map((w) => Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: w,
                  )))
              .toList()
            ..last = Expanded(child: children.last),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withOpacity(.35),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.circle, size: 14, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$value',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// 학생 테이블 + 출결 버튼들
class _StudentAttendanceTable extends StatelessWidget {
  final List<String> students;
  final void Function(String student, String status) onTap;

  const _StudentAttendanceTable({
    required this.students,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final headerStyle = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.w700);

    return Card(
      elevation: 0,
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('출결사항', style: headerStyle),
            const SizedBox(height: 10),
            _TableHeader(),
            const Divider(height: 1),
            ...students.map((s) => _StudentRow(
                  name: s,
                  onTap: onTap,
                )),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget cell(String t, {double flex = 1}) => Expanded(
          flex: (flex * 1000).toInt(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Text(
              t,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
        );

    return Container(
      color: cs.surfaceContainerHighest.withOpacity(.35),
      child: Row(
        children: [
          cell('학생', flex: 1.4),
          cell('출석'),
          cell('결석'),
          cell('지각'),
          cell('조퇴'),
          cell('보강'),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final String name;
  final void Function(String student, String status) onTap;
  const _StudentRow({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget action(String label, IconData icon, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            side: BorderSide(color: color.withOpacity(.45)),
          ),
          onPressed: () => onTap(name, label),
          icon: Icon(icon, size: 18, color: color),
          label: Text(label, style: TextStyle(color: color)),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 1400,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Row(
              children: [
                const Icon(Icons.edit, size: 18),
                const SizedBox(width: 8),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1000,
          child: action('출석', Icons.check_circle, const Color(0xFF2ecc71)),
        ),
        Expanded(
          flex: 1000,
          child: action('결석', Icons.cancel, const Color(0xFFe74c3c)),
        ),
        Expanded(
          flex: 1000,
          child: action('지각', Icons.schedule, const Color(0xFFf39c12)),
        ),
        Expanded(
          flex: 1000,
          child: action('조퇴', Icons.outbond, const Color(0xFF16a085)),
        ),
        Expanded(
          flex: 1000,
          child: action('보강', Icons.autorenew, const Color(0xFF9b59b6)),
        ),
      ],
    );
  }
}
