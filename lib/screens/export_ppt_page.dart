// lib/screens/export_ppt_page.dart
import 'package:flutter/material.dart';

import '../services/export_service.dart';
import '../models/export_models.dart';
import 'package:english_analyzer_app/config/api.dart'; // ✅ 추가

class ExportPptPage extends StatefulWidget {
  const ExportPptPage({super.key});
  @override
  State<ExportPptPage> createState() => _ExportPptPageState();
}

class _ExportPptPageState extends State<ExportPptPage> {
  bool _busy = false;

  /// ✅ 현재 단순 모델(passage, dateStr, maxWords)로 샘플 생성
  ExportPptRequest _buildSample() {
    return const ExportPptRequest(
      passage:
          "Rome was said to have been a melting pot from the very start. The historian Livy claimed the city's original population was comprised of immigrants flooding in from all directions, attracted by Romulus’s deliberate policy of nondiscrimination. It was this initial openness, Livy asserts, that laid the foundations for the later strength and success of the city.",
      dateStr: "2025 03 23", // PPT 2페이지 왼쪽 상단 배지
      maxWords: 12, // 유의어 최대 12개
    );
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      final req = _buildSample();

      // ✅ 서비스 인스턴스 생성 (Base URL 주입)
      final service = ExportService(ApiConfig.baseUrl);

      // ✅ 인스턴스 메서드 호출
      await service.downloadPpt(
        passage: req.passage,
        passageBracketed: null, // 필요 시 괄호 적용 텍스트 전달
        dateStr: req.dateStr,
        filename: 'analysis.pptx', // (옵션) 파일명 지정
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PPT 저장 완료!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PPT 생성 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('통합 PPT 만들기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: cs.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '문단분석 + 주제/요지 + 유의어 → PPT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('샘플 데이터로 먼저 PPT를 생성합니다. 이후 실제 분석 결과로 교체하세요.'),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _busy ? null : _run,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.slideshow_outlined),
                  label: const Text('PPT 생성 & 저장'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
