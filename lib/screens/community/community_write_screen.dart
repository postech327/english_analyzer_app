import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../config/auth_store.dart';

class CommunityWriteScreen extends StatefulWidget {
  const CommunityWriteScreen({super.key});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  String selectedCategory = "질문·답변";
  bool isLoading = false;

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (titleController.text.trim().isEmpty ||
        contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("제목과 내용을 입력해주세요.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      debugPrint("🔥 userId: ${AuthStore.userId}");
      debugPrint("🔥 nickname: ${AuthStore.nickname}");

      await CommunityService.createPost(
        title: titleController.text.trim(),
        content: contentController.text.trim(),
        region: "서울",
        category: selectedCategory,
      );

      if (!mounted) return;

      Navigator.pop(context, true); // 🔥 성공 시 true 반환 (리스트 새로고침용)
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("작성 실패: $e")),
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
      appBar: AppBar(
        title: const Text("글쓰기"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "제목",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: "내용",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "질문·답변", child: Text("질문·답변")),
                DropdownMenuItem(value: "스터디 모집", child: Text("스터디 모집")),
                DropdownMenuItem(value: "나눔·물물교환", child: Text("나눔·물물교환")),
                DropdownMenuItem(value: "지역 모임", child: Text("지역 모임")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitPost,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("등록하기"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
