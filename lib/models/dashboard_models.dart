// lib/models/dashboard_models.dart
class DashboardData {
  final int streakDays;
  final int totalAnalyses;
  final int learnedWords;
  final String level;
  final List<WrongType> wrongTypes;
  final List<RatioItem> ratios;

  DashboardData({
    required this.streakDays,
    required this.totalAnalyses,
    required this.learnedWords,
    required this.level,
    required this.wrongTypes,
    required this.ratios,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final wt = (json['wrongTypes'] as List? ?? [])
        .map((e) => WrongType.fromJson(e as Map<String, dynamic>))
        .toList();

    final rs = (json['ratios'] as List? ?? [])
        .map((e) => RatioItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardData(
      streakDays: _asInt(json['streakDays']),
      totalAnalyses: _asInt(json['totalAnalyses']),
      learnedWords: _asInt(json['learnedWords']),
      level: (json['level'] ?? '').toString(),
      wrongTypes: wt,
      ratios: rs,
    );
  }
}

class WrongType {
  final String label;
  final int count;

  WrongType({required this.label, required this.count});

  factory WrongType.fromJson(Map<String, dynamic> json) => WrongType(
        label: (json['label'] ?? '').toString(),
        count: _asInt(json['count']),
      );
}

class RatioItem {
  final String label;
  final int value; // 퍼센트(0~100)

  RatioItem({required this.label, required this.value});

  factory RatioItem.fromJson(Map<String, dynamic> json) => RatioItem(
        label: (json['label'] ?? '').toString(),
        value: _asInt(json['value']),
      );
}

int _asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}
