// lib/models/coin_log.dart
class CoinLog {
  final int id;
  final String action; // "earn" / "spend"
  final int amount; // +10, -10
  final String? reason;
  final DateTime createdAt;

  CoinLog({
    required this.id,
    required this.action,
    required this.amount,
    required this.reason,
    required this.createdAt,
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
