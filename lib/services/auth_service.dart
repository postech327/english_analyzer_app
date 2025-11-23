// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api.dart';
import '../models/auth_models.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // 토큰 저장 키 & 스토리지
  static const _kToken = 'access_token';
  final _storage = const FlutterSecureStorage();

  // -------------------------------
  // 회원가입
  // -------------------------------
  Future<Map<String, dynamic>> register(RegisterRequest req) async {
    final uri = ApiConfig.u(ApiConfig.authRegister);
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(req.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractError(res.body, fallback: '회원가입 실패'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // -------------------------------
  // 로그인 → 토큰 저장
  // -------------------------------
  Future<LoginResponse> login(LoginRequest req) async {
    final uri = ApiConfig.u(ApiConfig.login);
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(req.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractError(res.body, fallback: '로그인 실패'));
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final login = LoginResponse.fromJson(data);

    // 토큰 저장
    await _storage.write(key: _kToken, value: login.accessToken);
    return login;
  }

  // -------------------------------
  // 토큰 헬퍼
  // -------------------------------
  Future<String?> getToken() => _storage.read(key: _kToken);
  Future<void> logout() => _storage.delete(key: _kToken);

  // -------------------------------
  // 에러 메시지 추출
  // -------------------------------
  static String _extractError(String body, {String fallback = '요청 실패'}) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      if (m['detail'] is String) return m['detail'] as String;
      if (m['message'] is String) return m['message'] as String;
      if (m['error'] is String) return m['error'] as String;
    } catch (_) {}
    return fallback;
  }
}
