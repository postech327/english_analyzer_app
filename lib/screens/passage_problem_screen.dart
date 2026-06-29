import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'problem_take_screen.dart';

class PassageProblemScreen extends StatefulWidget {
  final int passageId;

  const PassageProblemScreen({super.key, required this.passageId});

  @override
  State<PassageProblemScreen> createState() => _PassageProblemScreenState();
}

class _PassageProblemScreenState extends State<PassageProblemScreen> {
  List problemSets = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadProblems();
  }

  Future<void> loadProblems() async {
    try {
      final res = await ApiService.getProblemSets(widget.passageId);
      setState(() {
        problemSets = res;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문제 목록 로드 실패: $e')),
      );
    }
  }

  /// 🔥 핵심: 시험 시작 → attemptId 받기
  Future<void> _startExam(dynamic ps) async {
    try {
      setState(() {
        isLoading = true;
      });

      final attemptId = await ApiService.startExam(ps['id']);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProblemTakeScreen(
            problemSetId: ps['id'],
            attemptId: attemptId, // 🔥 여기서 전달
            title: ps['name'] ?? '문제 세트',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시험 시작 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("문제 목록")),
      body: problemSets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: problemSets.length,
              itemBuilder: (context, index) {
                final ps = problemSets[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(ps['name'] ?? '문제 세트 ${ps['id']}'),
                    subtitle: const Text('문제 풀기'),
                    trailing: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: isLoading ? null : () => _startExam(ps),
                  ),
                );
              },
            ),
    );
  }
}
