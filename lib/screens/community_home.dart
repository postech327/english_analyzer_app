// lib/screens/community_home.dart
import 'package:flutter/material.dart';

import '../models/community_models.dart';
import '../services/community_api.dart';
import 'community_editor_screen.dart';
import 'profile_screen.dart'; // ← 추가

/// 임시 로그인 유저 ID (백엔드에 미리 만들어둔 dummy user: id=1)
const int kDummyAuthorId = 1;

/// 커뮤니티 메인 화면 (서버 연동)
class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  // 상단 카테고리 (전체 / 질문 / 스터디 / 나눔 / 지역)
  final List<String> _categories = [
    '전체',
    '질문·답변',
    '스터디 모집',
    '나눔·물물교환',
    '지역 모임',
  ];
  int _selectedIndex = 0;

  final TextEditingController _searchController = TextEditingController();

  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// 🔹 Author 정보를 이용해 "Lv3 선생님" 같은 뱃지 텍스트 만들어주는 헬퍼
  String _roleLabel(AuthorBrief? author) {
    if (author == null) return '';

    String roleKo;
    switch (author.role) {
      case 'teacher':
        roleKo = '선생님';
        break;
      case 'student':
        roleKo = '학생';
        break;
      default:
        roleKo = '회원';
    }

    return 'Lv${author.level} $roleKo';
  }

  @override
  void initState() {
    super.initState();
    _loadPosts(); // 처음 진입 시 목록 불러오기
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final category = _categories[_selectedIndex];
      final search = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();

      final posts = await CommunityApi.fetchPosts(
        category: category,
        search: search,
      );

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '목록 로드 중 오류가 발생했습니다: $e';
      });
    }
  }

  Future<void> _openNewPostEditor() async {
    // '전체'를 뺀 나머지 카테고리만 글쓰기 화면으로 전달
    final editorCategories = _categories.where((c) => c != '전체').toList();

    final result = await Navigator.push<Map<String, String>?>(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityEditorScreen(categories: editorCategories),
      ),
    );

    if (result == null) return; // 사용자가 취소한 경우

    try {
      // 🔥 여기서 authorId까지 함께 전송
      final newPost = await CommunityApi.createPost(
        title: result['title'] ?? '',
        content: result['content'] ?? '',
        nickname: result['nickname'] ?? '익명',
        region: result['region'],
        category: result['category'] ?? editorCategories.first,
        authorId: kDummyAuthorId, // ✅ 임시 로그인 유저 ID
      );

      setState(() {
        // 최신 글이 위에 오도록 맨 앞에 삽입
        _posts.insert(0, newPost);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새 글이 등록되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('글 등록 실패: $e')),
      );
    }
  }

  void _showPostDetail(CommunityPost post) {
    final badge = _roleLabel(post.author); // 🔹 Lv/role 뱃지

    // 닉네임 + (뱃지) + 지역 + 카테고리 조합
    final metaParts = <String>[];
    final nickWithBadge =
        badge.isNotEmpty ? '${post.nickname} ($badge)' : post.nickname;
    metaParts.add(nickWithBadge);
    if (post.region != null && post.region!.isNotEmpty) {
      metaParts.add(post.region!);
    }
    metaParts.add(post.category);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(post.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metaParts.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(post.content),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
        backgroundColor: cs.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(
                    userId: kDummyAuthorId, // 임시 로그인 유저 id=1
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: cs.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 상단 카테고리 선택 Chip ───
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _selectedIndex;
                return ChoiceChip(
                  label: Text(_categories[index]),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    _loadPosts();
                  },
                );
              },
            ),
          ),

          // ─── 검색 바 ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '제목 · 내용 · 닉네임 · 지역 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _loadPosts(),
            ),
          ),

          const Divider(height: 1),

          // ─── 본문 리스트 ───
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _posts.isEmpty
                        ? const Center(child: Text('등록된 글이 없습니다.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _posts.length,
                            itemBuilder: (context, index) {
                              final post = _posts[index];
                              final badge = _roleLabel(post.author);

                              // 첫 줄 메타 정보
                              final firstLineParts = <String>[];
                              final nickWithBadge = badge.isNotEmpty
                                  ? '${post.nickname} ($badge)'
                                  : post.nickname;
                              firstLineParts.add(nickWithBadge);
                              if (post.region != null &&
                                  post.region!.isNotEmpty) {
                                firstLineParts.add(post.region!);
                              }
                              firstLineParts.add(post.category);
                              final firstLine = firstLineParts.join(' · ');

                              // 둘째 줄: 내용 앞부분
                              final preview = post.content.length > 40
                                  ? '${post.content.substring(0, 40)}…'
                                  : post.content;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    post.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text('$firstLine\n$preview'),
                                  isThreeLine: true,
                                  onTap: () => _showPostDetail(post),
                                  trailing: Text(
                                    // 대충 날짜만 보기 좋게
                                    '${post.createdAt.month}/${post.createdAt.day} '
                                    '${post.createdAt.hour.toString().padLeft(2, '0')}:${post.createdAt.minute.toString().padLeft(2, '0')}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPostEditor,
        icon: const Icon(Icons.edit),
        label: const Text('글쓰기'),
      ),
    );
  }
}
