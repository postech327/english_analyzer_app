import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'recommended_question_screen.dart';

class ConceptDetailScreen extends StatefulWidget {
  final String errorType;
  const ConceptDetailScreen({super.key, required this.errorType});

  @override
  State<ConceptDetailScreen> createState() => _ConceptDetailScreenState();
}

class _ConceptDetailScreenState extends State<ConceptDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchConcept(widget.errorType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개념 설명')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          final c = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  c['title_ko'],
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  c['title_en'],
                  style: const TextStyle(color: Colors.grey),
                ),
                const Divider(height: 32),
                Text(
                  c['description_ko'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  c['description_en'],
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const Divider(height: 32),
                Text(
                  '예문',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(c['example']),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('이 개념 문제 다시 풀기'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecommendedQuestionScreen(
                          userId: 1, // 실제 로그인 유저 ID
                          errorType: widget.errorType,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
