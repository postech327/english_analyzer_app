// lib/screens/question_from_hub_screen.dart
import 'package:flutter/material.dart';

import '../models/analyzer_models.dart';

/// 지문 분석 허브에서 넘어와서
/// - 어떤 허브 ID인지
/// - 어떤 지문인지
/// - (필요하면) 분석 결과까지
/// 를 가지고 문제를 만드는 화면의 뼈대
class QuestionFromHubScreen extends StatelessWidget {
  final int hubId;
  final String passageText;
  final TextAnalysisHubResult hub; // 주제/제목/요지/요약도 필요하면 사용

  const QuestionFromHubScreen({
    super.key,
    required this.hubId,
    required this.passageText,
    required this.hub,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('문제 만들기 (Hub ID: $hubId)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) 지문 정보 간단 표시
            const Text(
              '지문 정보',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  passageText,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2) 분석 결과(주제/제목/요지/요약) 간단 표시
            const Text(
              '분석 요약',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text('Topic: ${hub.topic}'),
            Text('Title: ${hub.title}'),
            Text('Gist (EN): ${hub.gistEn}'),
            Text('요지 (Korean): ${hub.gistKo}'),
            const SizedBox(height: 12),

            // 3) 문제 유형 선택 버튼(뼈대)
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '문제 유형 선택 (추후 구현 예정)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TypeButton(label: '주제'),
                _TypeButton(label: '제목'),
                _TypeButton(label: '요지'),
                _TypeButton(label: '요약'),
                _TypeButton(label: '빈칸'),
                _TypeButton(label: '삽입'),
                _TypeButton(label: '순서'),
                _TypeButton(label: '전체'),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '※ 나중에 각 버튼을 누르면 해당 유형 문제를 만드는 화면/함수로 연결하면 됩니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;

  const _TypeButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        // TODO: 여기서 실제 문제 제작 로직/화면으로 연결
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label 문제 만들기 (추후 구현 예정)')),
        );
      },
      child: Text(label),
    );
  }
}
