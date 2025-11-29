// lib/services/community_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/community_models.dart';

/// FastAPI 서버 기본 주소
const String baseUrl =
    String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8000');

class CommunityApi {
  /// 글 목록 조회
  static Future<List<CommunityPost>> fetchPosts({
    String? category,
    String? search,
  }) async {
    final queryParams = <String, String>{};

    // 카테고리 필터 (전체는 보내지 않음)
    if (category != null && category.isNotEmpty && category != '전체') {
      queryParams['category'] = category;
    }

    // 검색어(q)
    if (search != null && search.trim().isNotEmpty) {
      queryParams['q'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/community/posts')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('커뮤니티 목록 로드 실패: ${resp.statusCode} / ${resp.body}');
    }

    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as List<dynamic>;

    return data
        .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 새 글 작성
  static Future<CommunityPost> createPost({
    required String title,
    required String content,
    required String nickname,
    String? region,
    required String category,
    required int authorId, // ← 로그인된 유저 ID
  }) async {
    final uri = Uri.parse('$baseUrl/community/posts');

    final body = jsonEncode({
      'title': title,
      'content': content,
      'nickname': nickname,
      'region': region,
      'category': category,
      'author_id': authorId, // ← 백엔드에서 받는 필드 이름
    });

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('글 등록 실패: ${resp.statusCode} / ${resp.body}');
    }

    final data =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

    return CommunityPost.fromJson(data);
  }
}
