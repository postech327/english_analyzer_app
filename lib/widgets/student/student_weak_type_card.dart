import 'package:flutter/material.dart';
import '../../services/student_exam_service.dart';

class StudentWeakTypeCard extends StatelessWidget {
  final int userId;

  const StudentWeakTypeCard({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<Map<String, dynamic>>(
      future: StudentExamService.fetchWeakTypes(userId: userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('에러: ${snapshot.error}');
        }

        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Text('아직 약점 데이터가 없습니다.');
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '나의 약점 유형',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...data.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _label(e.key),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${e.value}문제',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _label(String key) {
    switch (key) {
      case 'grammar':
        return '문법';
      case 'vocabulary':
        return '어휘';
      case 'inference':
        return '추론';
      case 'context':
        return '문맥';
      case 'trap':
        return '함정';
      default:
        return key;
    }
  }
}
