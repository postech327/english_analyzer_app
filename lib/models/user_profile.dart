// lib/models/user_profile.dart
class UserProfile {
  final int id;
  final String email;
  final String nickname;
  final String? region;
  final String role; // "normal" / "student" / "teacher"
  final int level; // 1,2,3...
  final int coins;
  final DateTime createdAt;
  final String levelLabel; // 예: "Lv3 선생님회원"

  UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    required this.region,
    required this.role,
    required this.level,
    required this.coins,
    required this.createdAt,
    required this.levelLabel,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      region: json['region'] as String?,
      role: json['role'] as String,
      level: json['level'] as int,
      coins: json['coins'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      levelLabel: json['level_label'] as String,
    );
  }
}
