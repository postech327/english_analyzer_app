// lib/config/api.dart
/// API 엔드포인트와 공통 BASE URL 관리
class ApiConfig {
  /// 실행 시 주입: --dart-define=API_BASE=http://127.0.0.1:8000
  /// 주입이 없다면 로컬 기본값 사용
  static final String baseUrl = _normalizeBase(
    const String.fromEnvironment(
      'API_BASE',
      defaultValue: 'http://127.0.0.1:8000',
    ),
  );

  // ---------- Endpoints ----------

  // 인증
  static String get authRegister => _j('auth/register');
  static String get login => _j('login');

  // 분석 계열
  static String get analyzeStructure => _j('analyze_structure');
  static String get analyzeParagraph => _j('analyze_paragraph');
  static String get analyzeTopicTitleSummary =>
      _j('analyze_topic_title_summary');

  // 단어/유의어
  static String get wordSynonyms => _j('word_synonyms');

  // 챗봇
  static String get chat => _j('chat');

  // 단어 객관식 생성
  static String get wordMcq => _j('word-mcq'); // 문자열 포맷 응답
  static String get wordMcqStruct => _j('word-mcq-struct'); // 구조화 응답

  // 대시보드
  static String get dashboard => _j('dashboard');

  // PPT 내보내기
  static String get exportPpt => _j('export/ppt');

  // 🆕 선생님: 지문 + 자동생성 문제 세트 저장
  static String get teacherQuestionSets => _j('teacher/question-sets');

  /// 문자열 URL → Uri
  static Uri u(String url) => Uri.parse(url);

  /// 내부 유틸: 슬래시 중복/누락 방지
  static String _j(String path) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$p';
  }

  /// 내부 유틸: baseUrl 끝의 / 제거
  static String _normalizeBase(String s) {
    return s.endsWith('/') ? s.substring(0, s.length - 1) : s;
  }

  // ───────── Question Maker ─────────
  static String qm(String type) => _j('question_maker/$type');
}
