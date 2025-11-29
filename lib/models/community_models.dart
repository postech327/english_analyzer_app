// lib/models/community_models.dart
class CommunityPost {
  final int id;
  final String title;
  final String content;
  final String nickname;
  final String? region;
  final String category;
  final DateTime createdAt;

  // ⭐️ 새로 추가
  final AuthorBrief? author;

  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.nickname,
    this.region,
    required this.category,
    required this.createdAt,
    this.author,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      region: json['region'] as String?,
      category: json['category'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),

      // ⭐️ author 파싱 (없으면 null)
      author: json['author'] != null
          ? AuthorBrief.fromJson(json['author'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AuthorBrief {
  final int id;
  final String nickname;
  final String role; // 'normal' / 'student' / 'teacher'
  final int level; // 1, 2, 3 ...

  AuthorBrief({
    required this.id,
    required this.nickname,
    required this.role,
    required this.level,
  });

  factory AuthorBrief.fromJson(Map<String, dynamic> json) {
    return AuthorBrief(
      id: json['id'] as int,
      nickname: json['nickname'] as String? ?? '',
      role: json['role'] as String? ?? 'normal',
      level: json['level'] as int? ?? 1,
    );
  }
}
