import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'passage_problem_screen.dart';

class FolderPassagesScreen extends StatefulWidget {
  final int folderId;

  const FolderPassagesScreen({super.key, required this.folderId});

  @override
  State<FolderPassagesScreen> createState() => _FolderPassagesScreenState();
}

class _FolderPassagesScreenState extends State<FolderPassagesScreen> {
  List passages = [];

  @override
  void initState() {
    super.initState();
    loadPassages();
  }

  Future<void> loadPassages() async {
    final res = await ApiService.getPassagesByFolder(widget.folderId);
    setState(() {
      passages = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("지문 목록")),
      body: ListView.builder(
        itemCount: passages.length,
        itemBuilder: (context, index) {
          final p = passages[index];
          return ListTile(
            title: Text(p['text'] ?? ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PassageProblemScreen(
                    passageId: p['id'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
