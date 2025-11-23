// lib/services/question_maker_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:english_analyzer_app/config/api.dart';

class McqItem {
  final String stem;
  final List<String> options;
  final int answerIndex;
  final Map<String, dynamic> meta;

  McqItem({
    required this.stem,
    required this.options,
    required this.answerIndex,
    this.meta = const {},
  });

  factory McqItem.fromJson(Map<String, dynamic> j) => McqItem(
        stem: j['stem'] as String? ?? '',
        options: (j['options'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        answerIndex: j['answer_index'] is int ? j['answer_index'] as int : 0,
        meta: (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class QmService {
  /// 서버 호출 (백엔드: /question_maker/<type>)
  Future<List<McqItem>> generateViaServer({
    required String type,
    required String passage,
    int items = 5,
    Map<String, dynamic>? extra,
  }) async {
    final uri = ApiConfig.u(ApiConfig.qm(type));
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'passage': passage,
        'items': items,
        if (extra != null) ...extra,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Question API 실패(${res.statusCode}): ${res.body}');
    }

    final data = jsonDecode(res.body);
    final list = (data['items'] as List?) ?? [];
    return list
        .map((e) => McqItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // 폴백들 (오프라인/서버 실패 시)
  // ─────────────────────────────────────────────────────────

  /// 제목/주제/요지/요약 공통 폴백
  /// type: 'title' | 'topic' | 'gist' | 'summary'
  List<McqItem> fallbackTTGS({
    required String type,
    required String passage,
    int count = 1,
  }) {
    final stemMap = {
      'title': 'Which of the following is best for the title of the passage?',
      'topic': 'Which of the following is best for the topic of the passage?',
      'gist': 'Which of the following is the main idea of the passage?',
      'summary': 'Which of the following best summarizes the passage?',
    };
    final stem = stemMap[type] ?? stemMap['topic']!;
    final items = <McqItem>[];

    for (int k = 0; k < count; k++) {
      final correct = roughTheme(passage);
      final ds = _genericDistractors(correct, n: 4);
      final opts = [...ds, correct]..shuffle();
      final ans = opts.indexOf(correct);

      items.add(
        McqItem(
          stem: stem,
          options: List.generate(
              opts.length, (i) => '${_circled(i + 1)} ${opts[i]}'),
          answerIndex: ans,
        ),
      );
    }
    return items;
  }

  /// 빈칸 폴백 (정답 텍스트 필요)
  /// ✅ 빈칸 폴백 (정답 입력 or 자동 추출 + 본문에 빈칸 표시)
  List<McqItem> fallbackCloze({
    required String passage,
    String? answerText, // ← 선택 입력
  }) {
    String text = passage.trim();
    if (text.isEmpty) {
      return [
        McqItem(
          stem: 'Which of the following is best for the blank?',
          options: const ['①'],
          answerIndex: 0,
          meta: {'passage_marked': '', 'answer_text': ''},
        )
      ];
    }

    // 1) 정답 결정 (사용자 입력 > 자동 추출)
    String answer = (answerText ?? '').trim();
    if (answer.isEmpty) {
      final bigram = RegExp(r'\b([A-Za-z]{3,}\s+[A-Za-z]{3,})\b')
          .firstMatch(text)
          ?.group(0);
      if (bigram != null) {
        answer = bigram;
      } else {
        final word = RegExp(r'\b([A-Za-z]{5,})\b').firstMatch(text)?.group(0);
        answer = word ?? 'answer';
      }
    }

    // 2) 본문에서 첫 번째 일치만 빈칸으로 치환
    String marked = _blankFirst(text, answer);

    // 3) 보기 생성
    final distractors = _perturb(answer);
    final opts = [...distractors.take(4), answer]..shuffle();
    final ans = opts.indexOf(answer);

    return [
      McqItem(
        stem: 'Which of the following is best for the blank?',
        options:
            List.generate(opts.length, (i) => '${_circled(i + 1)} ${opts[i]}'),
        answerIndex: ans,
        meta: {
          'passage_marked': marked,
          'answer_text': answer,
          'explain': 'The blank corresponds to "$answer".',
        },
      ),
    ];
  }

// ── 헬퍼: 본문에서 첫 번째 일치만 빈칸으로 바꾸기 (대소문자 무시)
  String _blankFirst(String text, String needle) {
    if (needle.trim().isEmpty) return text;

    final i = text.toLowerCase().indexOf(needle.toLowerCase());
    if (i < 0) return text;

    final before = text.substring(0, i);
    final after = text.substring(i + needle.length);

    // ✅ 중괄호 {} 로 변수 경계 지정
    return '${before}____(   )____$after';
  }

  /// ✅ 삽입형(Fallback)
  /// - [insertSentence]가 주어지면 본문에서 찾아 제거하고 그 위치를 정답으로 사용
  /// - 없으면 휴리스틱(접속/전환 문장 우선, 없으면 마지막 문장)으로 선택해 제거
  List<McqItem> fallbackInsertion({
    required String passage,
    int choicesCount = 5, // 서버 옵션 유지용(폴백에선 자동 계산)
    String? insertSentence,
  }) {
    final sents = _splitSentences(passage);
    if (sents.isEmpty) {
      return [
        McqItem(
          stem: 'Choose the best position to insert the given sentence.',
          options: const ['①'],
          answerIndex: 0,
          meta: {
            'insert_sentence': insertSentence ?? '',
            'passage_marked': '',
            'explain': '',
          },
        )
      ];
    }

    String picked = (insertSentence ?? '').trim();
    int originalIndex = -1;

    if (picked.isNotEmpty) {
      originalIndex = sents.indexWhere((e) => e.trim() == picked);
      if (originalIndex == -1) {
        originalIndex = sents.indexWhere((e) => e.contains(picked));
      }
      if (originalIndex >= 0) {
        sents.removeAt(originalIndex);
      } else {
        picked = '';
      }
    }

    // 휴리스틱: 접속/전환 시그널 포함 문장(뒤쪽 우선), 없으면 마지막 문장
    if (picked.isEmpty) {
      int idx = sents.lastIndexWhere(_hasTransition);
      if (idx < 0) idx = sents.length - 1;
      picked = sents[idx];
      originalIndex = idx;
      sents.removeAt(idx);
    }

    // 보기(문장 사이 간격) 개수: (남은 문장 수 + 1)
    final gapCount = sents.length + 1;
    final options = List.generate(gapCount, (i) => _circled(i + 1));

    // 정답 인덱스 계산(제거된 위치)
    int answerIndex = originalIndex;
    if (answerIndex > sents.length) answerIndex = sents.length;
    if (answerIndex < 0) answerIndex = sents.length;

    // 지문(삽입 문장 제외, ① … 형태로 마킹)
    final marked = _injectMarkers(sents);

    return [
      McqItem(
        stem: 'Choose the best position to insert the given sentence.',
        options: options,
        answerIndex: answerIndex,
        meta: {
          'insert_sentence': picked,
          'passage_marked': marked,
          'explain': 'Insert after position ${answerIndex + 1}.',
        },
      )
    ];
  }

  /// ✅ 순서형(Fallback) — 보기 5개는 고정, 정답 패턴만 랜덤
  List<McqItem> fallbackOrder({
    required String passage,
    int? seed,
  }) {
    final rnd = seed == null ? Random() : Random(seed);

    // 4블록: fixed + A0/B0/C0
    final blocks = _splitIntoBlocks(passage);
    final fixed = blocks.first;
    final a0 = blocks[1];
    final b0 = blocks[2];
    final c0 = blocks[3];

    // 보기 5개 고정
    const options = <String>[
      '① (A)-(C)-(B)',
      '② (B)-(A)-(C)',
      '③ (B)-(C)-(A)',
      '④ (C)-(A)-(B)',
      '⑤ (C)-(B)-(A)',
    ];

    // 정답 패턴을 5개 중 랜덤 선택
    final answerIndex = rnd.nextInt(options.length);

    // 패턴 파싱 → ['A','B','C']
    List<String> parsePattern(String s) {
      final m = RegExp(r'\((A|B|C)\)-\((A|B|C)\)-\((A|B|C)\)').firstMatch(s)!;
      return [m.group(1)!, m.group(2)!, m.group(3)!];
    }

    final pattern = parsePattern(options[answerIndex]);

    // 실제 정답 순서는 A0 → B0 → C0 이므로 라벨 매핑으로 재배치
    final map = <String, String>{
      pattern[0]: a0,
      pattern[1]: b0,
      pattern[2]: c0,
    };

    return [
      McqItem(
        stem: 'Rearrange the paragraphs in the correct order.',
        options: options,
        answerIndex: answerIndex,
        meta: {
          'fixed': fixed,
          'A': map['A']!,
          'B': map['B']!,
          'C': map['C']!,
        },
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────
  // 헬퍼
  // ─────────────────────────────────────────────────────────

  /// 문장 분리
  List<String> _splitSentences(String t) {
    final cleaned = t.replaceAll('\n', ' ').trim();
    final parts = cleaned
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? [cleaned] : parts;
  }

  /// ①, ②, ③ …
  String _circled(int i) => String.fromCharCode(0x2460 + (i - 1));

  /// 삽입형 지문 마킹(① + 문장)
  String _injectMarkers(List<String> sents) {
    final buf = StringBuffer();
    for (int i = 0; i < sents.length; i++) {
      buf.writeln('${_circled(i + 1)} ${sents[i]}');
    }
    return buf.toString().trimRight();
  }

  /// 순서형 블록 분할: fixed + A + B + C
  List<String> _splitIntoBlocks(String t) {
    final sents = _splitSentences(t);
    if (sents.length <= 4) {
      final fill = [...sents];
      while (fill.length < 4) {
        fill.add('');
      }
      return fill.take(4).toList();
    }
    final q = (sents.length / 4).ceil();
    return [
      sents.take(q).join(' '),
      sents.skip(q).take(q).join(' '),
      sents.skip(2 * q).take(q).join(' '),
      sents.skip(3 * q).join(' '),
    ];
  }

  /// 러프 테마(요지/요약용 임시 정답)
  String roughTheme(String t) {
    final low = t.toLowerCase();
    if (low.contains('students') ||
        low.contains('learn') ||
        low.contains('education')) {
      return 'The central cause-effect in the passage.';
    }
    if (low.contains('technology') || low.contains('device')) {
      return 'How technology shapes our daily life.';
    }
    if (low.contains('environment') || low.contains('climate')) {
      return 'The need for sustainable environmental actions.';
    }
    return 'The central cause-effect in the passage.';
  }

  List<String> _genericDistractors(String correct, {int n = 4}) {
    const pool = [
      'Historical background unrelated to the passage.',
      'Personal anecdotes without general relevance.',
      'A narrow example mistaken for the main idea.',
      'An exaggerated claim beyond the text.',
      'A detail that misses the central point.',
      'An opposite statement that contradicts the text.',
    ];
    final list = [...pool]
      ..remove(correct)
      ..shuffle();
    return list.take(n).toList();
  }

  List<String> _perturb(String base) {
    final p = <String>[
      'partly $base',
      '$base in rare cases',
      '$base only for some people',
      base.replaceAll(RegExp(r'\bmore\b', caseSensitive: false), 'less'),
      base.replaceAll(RegExp(r'\bdo\b', caseSensitive: false), 'avoid'),
      'not to $base',
    ];
    final uniq = p.toSet().toList()..removeWhere((e) => e.trim().isEmpty);
    uniq.shuffle();
    return uniq;
  }

  bool _hasTransition(String s) {
    const ts = [
      'however',
      'moreover',
      'therefore',
      'consequently',
      'nevertheless',
      'furthermore',
      'in fact',
      'meanwhile',
      'instead',
      'thus',
      'then',
      'at first',
      'for example',
      'for instance',
    ];
    final low = s.toLowerCase();
    return ts.any((w) => low.contains(w));
  }
}
