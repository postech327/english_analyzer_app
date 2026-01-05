import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProblemSetPreviewScreen extends StatefulWidget {
  const ProblemSetPreviewScreen({super.key});

  @override
  State<ProblemSetPreviewScreen> createState() =>
      _ProblemSetPreviewScreenState();
}

class _ProblemSetPreviewScreenState extends State<ProblemSetPreviewScreen> {
  bool _busy = true;
  String? _error;
  Map<String, dynamic>? _data;

  int? _problemSetId;
  bool _didInitArgs = false;

  static const _baseUrl = 'http://127.0.0.1:8000';

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
      _data = null;
    });

    try {
      // ✅ FastAPI에 맞춰서 endpoint를 여기로 맞추면 됨
      final url = Uri.parse('$_baseUrl/teacher/problem_sets/$_problemSetId');
      final res = await http.get(url);

      if (res.statusCode != 200) {
        throw Exception('${res.statusCode} ${res.body}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _data = decoded);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '불러오기 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(
        title: Text(_problemSetId == null
            ? '문제세트 미리보기'
            : '문제세트 미리보기 (ID: $_problemSetId)'),
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
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _data == null
                  ? const Center(child: Text('데이터 없음'))
                  : _buildPreview(_data!),
    );
  }

  Widget _buildPreview(Map<String, dynamic> data) {
    final passageTitle = (data['passage_title'] ?? '').toString();
    final passageContent = (data['passage_content'] ?? '').toString();
    final questions = (data['questions'] as List<dynamic>? ?? []);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('지문 제목',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(passageTitle.isEmpty ? '(제목 없음)' : passageTitle),
                const SizedBox(height: 12),
                const Text('지문', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                SelectableText(passageContent),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < questions.length; i++) ...[
          _questionCard(i + 1, questions[i] as Map<String, dynamic>),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _questionCard(int no, Map<String, dynamic> q) {
    final stem = (q['stem'] ?? q['text'] ?? '').toString();
    final options = (q['options'] as List<dynamic>? ?? []);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('[$no] $stem',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final opt in options)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${opt['label'] ?? ''} ${opt['text'] ?? ''}'),
            ),
        ]),
      ),
    );
  }
}
