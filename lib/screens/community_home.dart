// lib/screens/community_home.dart
import 'package:flutter/material.dart';

import '../models/community_models.dart';
import '../services/community_api.dart';
import 'profile_screen.dart';
import 'community/community_write_screen.dart';
import 'community/community_detail_screen.dart';

const int kDummyAuthorId = 1;

class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
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
    _loadPosts();
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
        _errorMessage = '목록 로드 중 오류: $e';
      });
    }
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
                    userId: kDummyAuthorId,
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
          // 카테고리
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

          // 검색
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

          // 목록
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
                        : RefreshIndicator(
                            onRefresh: _loadPosts,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _posts.length,
                              itemBuilder: (context, index) {
                                final post = _posts[index];
                                final badge = _roleLabel(post.author);

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
                                    subtitle: Text(
                                      '${firstLineParts.join(' · ')}\n$preview',
                                    ),
                                    isThreeLine: true,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CommunityDetailScreen(post: post),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CommunityWriteScreen(),
            ),
          );

          if (result == true) {
            await _loadPosts(); // ⭐ 글 작성 후 자동 새로고침
          }
        },
        icon: const Icon(Icons.edit),
        label: const Text("글쓰기"),
      ),
    );
  }
}
