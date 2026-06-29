import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import 'community_detail_screen.dart';
import 'community_write_screen.dart'; // 🔥 추가
import '../../models/community_models.dart';

class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  late Future<List<CommunityPost>> futurePosts;

  @override
  void initState() {
    super.initState();
    futurePosts = _loadPosts();
  }

  Future<List<CommunityPost>> _loadPosts() async {
    final data = await CommunityService.fetchPosts();
    return data.map<CommunityPost>((e) => CommunityPost.fromJson(e)).toList();
  }

  void _refreshPosts() {
    setState(() {
      futurePosts = _loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community"),
      ),

      // 🔥 body
      body: FutureBuilder<List<CommunityPost>>(
        future: futurePosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final posts = snapshot.data!;

          if (posts.isEmpty) {
            return const Center(child: Text("No posts yet."));
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshPosts();
            },
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(post.title),
                    subtitle: Text("${post.nickname} • ${post.category}"),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommunityDetailScreen(post: post),
                        ),
                      );

                      // 🔥 상세에서 돌아오면 자동 새로고침
                      _refreshPosts();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),

      // 🔥🔥🔥 글쓰기 버튼 추가
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CommunityWriteScreen(),
            ),
          );

          // 글 작성 후 true 반환하면 새로고침
          if (result == true) {
            _refreshPosts();
          }
        },
        icon: const Icon(Icons.edit),
        label: const Text("글쓰기"),
      ),
    );
  }
}
