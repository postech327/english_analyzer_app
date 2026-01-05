// lib/screens/student/student_weak_concept_screen.dart
import 'package:flutter/material.dart';

class StudentWeakConceptScreen extends StatelessWidget {
  final int userId;

  const StudentWeakConceptScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 🔥 임시 약점 유형 (다음 단계에서 API 연동)
    const String weakType = 'grammar';

    // 🔥 유형별 개념 설명 (지금은 하드코딩 → GPT/DB로 확장 가능)
    final Map<String, String> conceptExplanation = {
      'grammar': '''
문법 유형에서 자주 틀리는 이유는 다음과 같습니다.

• 문장 구조(S-V-O)를 끝까지 확인하지 않음
• 수식 관계(관계절, 분사구문)를 놓침
• 시제·수일치보다 의미에만 집중함

👉 해결 방법
1. 동사 먼저 찾기
2. 수식어는 괄호로 묶기
3. 문장의 핵심 구조를 먼저 파악
''',
      'vocabulary': '''
어휘 문제에서 틀리는 주된 이유는 다음과 같습니다.

• 아는 뜻만 떠올리고 문맥을 안 봄
• 비슷한 의미 단어에 속음
• 추상어의 정확한 뉘앙스 부족

👉 해결 방법
1. 단어 단독 암기 ❌
2. 항상 문장 속 의미로 판단
3. 반대말·대조 표현 확인
''',
      'inference': '''
추론 문제에서 어려움을 겪는 이유는 다음과 같습니다.

• 글에 없는 내용을 추측함
• 부분 정보만 보고 결론을 냄
• 글쓴이 의도를 고려하지 않음

👉 해결 방법
1. 근거 문장 찾기
2. ‘가장 적절한’ 선택지에 집중
3. 과도한 해석 경계
''',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('개념 설명'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─────────────────────────
          // ① 약점 유형 요약
          // ─────────────────────────
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '나의 약점 유형',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weakType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─────────────────────────
          // ② 개념 설명 카드
          // ─────────────────────────
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                conceptExplanation[weakType] ?? '해당 유형의 개념 설명이 준비 중입니다.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─────────────────────────
          // ③ 학습 액션 버튼
          // ─────────────────────────
          FilledButton.icon(
            icon: const Icon(Icons.quiz),
            label: const Text('이 개념 문제 풀기'),
            onPressed: () {
              // 👉 다음 단계: 추천 문제 화면으로 이동
            },
          ),
        ],
      ),
    );
  }
}
