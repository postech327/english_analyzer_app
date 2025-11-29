// lib/models/community_post.dart
class CommunityPost {
  final String title;
  final String content;
  final String nickname;
  final String region; // 예: '서울 · 강남구'
  final String category; // 예: '질문·답변', '스터디 모집' 등
  final DateTime createdAt; // 작성 시간

  CommunityPost({
    required this.title,
    required this.content,
    required this.nickname,
    required this.region,
    required this.category,
    required this.createdAt,
  });
}
