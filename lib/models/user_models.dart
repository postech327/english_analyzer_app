// lib/models/user_models.dart
class UserProfile {
  final int id;
  final String email;
  final String nickname;
  final String region;
  final String role;
  final int level;
  final int coins;
  final String createdAt;
  final String levelLabel;

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
      region: json['region'] as String? ?? '',
      role: json['role'] as String,
      level: json['level'] as int,
      coins: json['coins'] as int,
      createdAt: json['created_at'] as String,
      levelLabel: json['level_label'] as String? ?? '',
    );
  }
}

// 🔥 새로 추가: 코인 로그 한 줄
class CoinLog {
  final int id;
  final String action; // "earn" or "spend"
  final int amount;
  final String? reason;
  final DateTime createdAt;

  CoinLog({
    required this.id,
    required this.action,
    required this.amount,
    required this.createdAt,
    this.reason,
  });

  factory CoinLog.fromJson(Map<String, dynamic> json) {
    return CoinLog(
      id: json['id'] as int,
      action: json['action'] as String,
      amount: json['amount'] as int,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
