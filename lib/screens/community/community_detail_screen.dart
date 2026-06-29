// screens/community/community_detail_screen.dart

import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../models/community_models.dart';

class CommunityDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const CommunityDetailScreen({super.key, required this.post});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  List<dynamic> _comments = [];
  bool _isLoading = true;

  int _likeCount = 0;
  bool _liked = false;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final comments = await CommunityService.fetchComments(widget.post.id);

      final likeCount = await CommunityService.getLikeCount(widget.post.id);

      final liked = await CommunityService.getLikeStatus(widget.post.id);

      setState(() {
        _comments = comments;
        _likeCount = likeCount;
        _liked = liked;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // 💬 댓글 작성
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    await CommunityService.createComment(
      postId: widget.post.id,
      content: _commentController.text.trim(),
    );

    _commentController.clear();
    await _loadAll();
  }

  // ❤️ 좋아요 (Optimistic Update)
  Future<void> _toggleLike() async {
    final previousLiked = _liked;
    final previousCount = _likeCount;

    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });

    try {
      await CommunityService.toggleLike(widget.post.id);
    } catch (e) {
      setState(() {
        _liked = previousLiked;
        _likeCount = previousCount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("좋아요 처리 실패")),
      );
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    return raw.substring(0, 16).replaceAll("T", " ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("게시글 상세")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 📌 게시글 본문
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.post.content),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _toggleLike,
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                      scale: animation, child: child),
                              child: Icon(
                                _liked ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey(_liked),
                                color: _liked ? Colors.red : Colors.grey,
                              ),
                            ),
                          ),
                          Text(
                            '$_likeCount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _liked ? Colors.red : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // 💬 댓글 목록 (업그레이드)
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];

                      final nickname =
                          comment["author"]?["nickname"] ?? "Unknown";
                      final content = comment["content"] ?? "";
                      final createdAt = comment["created_at"];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blueGrey,
                              child: Text(
                                nickname.isNotEmpty
                                    ? nickname[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nickname,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      content,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 💬 댓글 입력창
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: "댓글을 입력하세요",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _submitComment,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
