import 'package:flutter/material.dart';

/// 커뮤니티 글쓰기 화면
///
/// - 제목
/// - 내용
/// - 닉네임 (선생님 / 학생 공통)
/// - 지역 정보 (예: 서울 · 마포구)
/// - 카테고리 선택
///
/// 저장하면 `Map<String, String>` 형태로 상위 화면에 되돌려줌.
class CommunityEditorScreen extends StatefulWidget {
  final List<String> categories; // '질문·답변', '스터디 모집' 등

  const CommunityEditorScreen({
    super.key,
    required this.categories,
  });

  @override
  State<CommunityEditorScreen> createState() => _CommunityEditorScreenState();
}

class _CommunityEditorScreenState extends State<CommunityEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _nicknameController = TextEditingController(text: '익명');
  final _regionController = TextEditingController();

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.categories.isNotEmpty ? widget.categories.first : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _nicknameController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(<String, String>{
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'nickname': _nicknameController.text.trim(),
      'region': _regionController.text.trim(),
      'category': _selectedCategory ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('새 글 쓰기'),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return '제목을 입력하세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '내용',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 5,
                maxLines: 10,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return '내용을 입력하세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '닉네임 (선생님 / 학생)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _regionController,
                decoration: const InputDecoration(
                  labelText: '지역 정보 (예: 서울 · 강남구)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: '카테고리',
                  border: OutlineInputBorder(),
                ),
                items: widget.categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('등록하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
