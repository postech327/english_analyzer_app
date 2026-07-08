import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../models/preview_question.dart';
import '../services/problem_set_api.dart';

class ProblemSetPreviewScreen extends StatefulWidget {
  const ProblemSetPreviewScreen({super.key});

  @override
  State<ProblemSetPreviewScreen> createState() =>
      _ProblemSetPreviewScreenState();
}

class _ProblemSetPreviewScreenState extends State<ProblemSetPreviewScreen> {
  bool _busy = true;
  String? _error;

  int? _problemSetId;
  bool _didInitArgs = false;

  String _passageTitle = '';
  String _passageContent = '';
  List<PreviewQuestion> _questions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['problemSetId'] != null) {
      final v = args['problemSetId'];
      _problemSetId = (v is int) ? v : int.tryParse(v.toString());
    }

    _didInitArgs = true;
    _load();
  }

  Future<void> _load() async {
    if (_problemSetId == null) {
      setState(() {
        _busy = false;
        _error = 'problemSetId가 없습니다.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _questions.clear();
    });

    try {
      final url = ApiConfig.u('/teacher/problem_sets/$_problemSetId');
      final res = await http.get(url);

      if (res.statusCode != 200) {
        throw Exception('${res.statusCode} ${res.body}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;

      _passageTitle = (decoded['passage_title'] ?? '').toString();
      _passageContent = (decoded['passage_content'] ?? '').toString();

      final rawQuestions = (decoded['questions'] as List<dynamic>? ?? []);
      _questions =
          rawQuestions.map((e) => PreviewQuestion.fromJson(e)).toList();

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '불러오기 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// ✅ 시험지 확정 저장
  Future<void> _commitProblemSet() async {
    if (_problemSetId == null) return;

    try {
      await ProblemSetApi.commitProblemSet(problemSetId: _problemSetId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시험지 저장 완료')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(
        title: Text(
          _problemSetId == null
              ? '문제세트 미리보기'
              : '문제세트 미리보기 (ID: $_problemSetId)',
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _buildPreview(),
    );
  }

  Widget _buildPreview() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        /// 📘 지문 카드
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('지문 제목',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(_passageTitle.isEmpty ? '(제목 없음)' : _passageTitle),
                const SizedBox(height: 12),
                const Text('지문', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                SelectableText(_passageContent),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        /// 📄 문제 리스트
        for (final q in _questions) ...[
          _questionCard(q),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 16),

        /// 💾 저장 버튼
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('시험지 저장'),
          onPressed: _busy ? null : _commitProblemSet,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _questionCard(PreviewQuestion q) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[${q.order}] ${q.text}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${String.fromCharCode(65 + i)}. ${q.options[i]}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
