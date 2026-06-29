import 'package:flutter/material.dart';
import 'student_exam_take_screen.dart';

class StudentWeakConceptScreen extends StatelessWidget {
  final int userId;

  const StudentWeakConceptScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Weak Concepts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ConceptCard(
            title: 'Vocabulary',
            description:
                'You struggled with word meanings and synonyms. Review key vocabulary.',
            example: 'The word "significant" means important or meaningful.',
            problemSetId: 201,
          ),
          SizedBox(height: 16),
          _ConceptCard(
            title: 'Inference',
            description:
                'You had difficulty inferring implicit meanings from the passage.',
            example:
                'From the passage, we can infer that education affects society.',
            problemSetId: 202,
          ),
        ],
      ),
    );
  }
}

class _ConceptCard extends StatelessWidget {
  final String title;
  final String description;
  final String example;
  final int problemSetId;

  const _ConceptCard({
    required this.title,
    required this.description,
    required this.example,
    required this.problemSetId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 12),
          const Text(
            'Example',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            example,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentExamTakeScreen(
                      problemSetId: problemSetId,
                    ),
                  ),
                );
              },
              child: const Text('Practice This Concept'),
            ),
          ),
        ],
      ),
    );
  }
}
