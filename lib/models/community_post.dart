// lib/models/community_post.dart
class CommunityPost {
  final int id;
  final String title;
  final String content;
  final String nickname;
  final String? region;
  final String category;
  final String createdAt;

  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.nickname,
    required this.region,
    required this.category,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      nickname: json['nickname'],
      region: json['region'],
      category: json['category'],
      createdAt: json['created_at'],
    );
  }
}
