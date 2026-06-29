import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("게시글 상세")),
      body: Center(
        child: Text("Post ID: $postId"),
      ),
    );
  }
}
