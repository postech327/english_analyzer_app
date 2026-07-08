// lib/services/user_api.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user_profile.dart';
import '../models/coin_log.dart';

/// FastAPI 백엔드 기본 URL
const String baseUrl =
    String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8001');

class UserApi {
  // ─────────────────────────────
  // 1) 유저 프로필 조회
  // GET /users/{user_id}
  // ─────────────────────────────
  static Future<UserProfile> fetchProfile(int userId) async {
    final uri = Uri.parse('$baseUrl/users/$userId');
    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('프로필 로드 실패: ${resp.statusCode} / ${resp.body}');
    }

    final data =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  // ─────────────────────────────
  // 2) 코인 적립
  // POST /users/{user_id}/coins/earn
  // body: { "amount": 30, "reason": "출석 보상" }
  // ─────────────────────────────
  static Future<UserProfile> earnCoins({
    required int userId,
    required int amount,
    required String reason,
  }) async {
    final uri = Uri.parse('$baseUrl/users/$userId/coins/earn');

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'reason': reason,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('코인 적립 실패: ${resp.statusCode} / ${resp.body}');
    }

    final data =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  // ─────────────────────────────
  // 3) 코인 로그 조회
  // GET /users/{user_id}/coins/logs
  // ─────────────────────────────
  static Future<List<CoinLog>> fetchCoinLogs(int userId) async {
    final uri = Uri.parse('$baseUrl/users/$userId/coins/logs');
    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('코인 로그 로드 실패: ${resp.statusCode} / ${resp.body}');
    }

    final List<dynamic> list =
        jsonDecode(utf8.decode(resp.bodyBytes)) as List<dynamic>;

    return list
        .map((e) => CoinLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
