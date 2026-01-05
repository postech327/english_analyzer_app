import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'concept_detail_screen.dart';

class WeaknessScreen extends StatefulWidget {
  final int userId;
  const WeaknessScreen({super.key, required this.userId});

  @override
  State<WeaknessScreen> createState() => _WeaknessScreenState();
}

class _WeaknessScreenState extends State<WeaknessScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchWeakTop(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 약점 유형')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('약점 데이터가 없습니다.'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(item['error_type']),
                  subtitle: Text('정확도: ${item['accuracy']}%'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConceptDetailScreen(
                          errorType: item['error_type'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
