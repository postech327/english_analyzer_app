// lib/services/question_maker_service.dart
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:english_analyzer_app/config/api.dart';
import 'package:english_analyzer_app/models/teacher_models.dart';


class QmService {
  // ─────────────────────────────────────────────────────────
  // 서버 호출 (백엔드: /question_maker/<type>)
  // ─────────────────────────────────────────────────────────
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
        .whereType<Map>()
        .map((e) => McqItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // ✅ 허브 기반 “정답 고정” 생성기 (Topic/Title/Gist/Summary)
  // ─────────────────────────────────────────────────────────
  List<McqItem> buildFixedTTGS({
    required String type,
    required String passage,
    required String correctText,
    int count = 1,
    int choices = 5,
  }) {
    final stemMap = {
      'title': 'Which of the following is best for the title of the passage?',
      'topic': 'Which of the following is best for the topic of the passage?',
      'gist': 'Which of the following is the main idea of the passage?',
      'summary': 'Which of the following best summarizes the passage?',
    };
    final stem = stemMap[type] ?? stemMap['topic']!;
    final correct = correctText.trim();

    if (correct.isEmpty) {
      return fallbackTTGS(type: type, passage: passage, count: count);
    }

    final items = <McqItem>[];
    for (int k = 0; k < count; k++) {
      final distractors = _fixedDistractors(
        type: type,
        passage: passage,
        correct: correct,
        n: max(0, choices - 1),
      );

      final optsPlain = [...distractors, correct]..shuffle();
      final ans = optsPlain.indexOf(correct);

      items.add(
        McqItem(
          stem: stem,
          options: List.generate(
            optsPlain.length,
            (i) => '${_circled(i + 1)} ${optsPlain[i]}',
          ),
          answerIndex: ans,
          meta: {
            'fixed_by_hub': true,
            'correct_text': correct,
          },
        ),
      );
    }
    return items;
  }

  // ─────────────────────────────────────────────────────────
  // 폴백들 (오프라인/서버 실패 시)
  // ─────────────────────────────────────────────────────────
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

  List<McqItem> fallbackCloze({
    required String passage,
    String? answerText,
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

    final marked = _blankFirst(text, answer);

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

  List<McqItem> fallbackInsertion({
    required String passage,
    int choicesCount = 5,
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

    if (picked.isEmpty) {
      int idx = sents.lastIndexWhere(_hasTransition);
      if (idx < 0) idx = sents.length - 1;
      picked = sents[idx];
      originalIndex = idx;
      sents.removeAt(idx);
    }

    final gapCount = sents.length + 1;
    final options = List.generate(gapCount, (i) => _circled(i + 1));

    int answerIndex = originalIndex;
    if (answerIndex > sents.length) answerIndex = sents.length;
    if (answerIndex < 0) answerIndex = sents.length;

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

  List<McqItem> fallbackOrder({
    required String passage,
    int? seed,
  }) {
    final rnd = seed == null ? Random() : Random(seed);

    final blocks = _splitIntoBlocks(passage);
    final fixed = blocks[0];
    final a0 = blocks[1];
    final b0 = blocks[2];
    final c0 = blocks[3];

    const options = <String>[
      '① (A)-(C)-(B)',
      '② (B)-(A)-(C)',
      '③ (B)-(C)-(A)',
      '④ (C)-(A)-(B)',
      '⑤ (C)-(B)-(A)',
    ];

    final answerIndex = rnd.nextInt(options.length);

    List<String> parsePattern(String s) {
      final m = RegExp(r'\((A|B|C)\)-\((A|B|C)\)-\((A|B|C)\)').firstMatch(s)!;
      return [m.group(1)!, m.group(2)!, m.group(3)!];
    }

    final pattern = parsePattern(options[answerIndex]);

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
  // 내부 헬퍼들
  // ─────────────────────────────────────────────────────────
  List<String> _fixedDistractors({
    required String type,
    required String passage,
    required String correct,
    required int n,
  }) {
    final pool = <String>[];
    final theme = roughTheme(passage);

    if (type == 'title') {
      pool.addAll([
        'A Warning About Modern Society',
        'The Limits of Human Knowledge',
        'A Historical Overview of the Issue',
        'A Personal Story With a Lesson',
        'Why People Make the Wrong Choices',
        'The Hidden Costs Behind Our Decisions',
        'How Small Factors Shape Big Outcomes',
      ]);
    } else if (type == 'topic') {
      pool.addAll([
        'How people respond to social pressure',
        'The role of evidence in decision making',
        'The unintended consequences of well-meant actions',
        'The importance of diverse perspectives',
        theme,
      ]);
    } else if (type == 'gist') {
      pool.addAll([
        'A key factor explains why people misjudge situations.',
        'External appearances often hide the real issue.',
        'Small changes can lead to major misunderstandings.',
        'People benefit when they question their assumptions.',
      ]);
    } else if (type == 'summary') {
      pool.addAll([
        'The passage reviews background information and lists several examples.',
        'The author presents two opposing views without taking a clear side.',
        'The passage explains a problem and suggests a practical solution.',
        'The passage describes a trend and evaluates its impact on society.',
      ]);
    }

    pool.addAll(const [
      'Historical background unrelated to the passage.',
      'Personal anecdotes without general relevance.',
      'A narrow example mistaken for the main idea.',
      'An exaggerated claim beyond the text.',
      'A detail that misses the central point.',
      'An opposite statement that contradicts the text.',
    ]);

    final uniq = <String>{};
    for (final p in pool) {
      final s = p.trim();
      if (s.isEmpty) continue;
      if (s.toLowerCase() == correct.toLowerCase()) continue;
      uniq.add(s);
    }

    final list = uniq.toList()..shuffle();
    return list.take(n).toList();
  }

  List<String> _splitSentences(String t) {
    final cleaned = t.replaceAll('\n', ' ').trim();
    final parts = cleaned
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? [cleaned] : parts;
  }

  String _circled(int i) => String.fromCharCode(0x2460 + (i - 1));

  String _injectMarkers(List<String> sents) {
    final buf = StringBuffer();
    for (int i = 0; i < sents.length; i++) {
      buf.writeln('${_circled(i + 1)} ${sents[i]}');
    }
    return buf.toString().trimRight();
  }

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

  String roughTheme(String t) {
    final low = t.toLowerCase();
    if (low.contains('students') ||
        low.contains('learn') ||
        low.contains('education')) {
      return 'The role of education in learning and development.';
    }
    if (low.contains('technology') ||
        low.contains('device') ||
        low.contains('social media')) {
      return 'How technology influences society and behavior.';
    }
    if (low.contains('environment') || low.contains('climate')) {
      return 'The need for sustainable environmental actions.';
    }
    if (low.contains('government') ||
        low.contains('bailout') ||
        low.contains('policy')) {
      return 'How policies can create unintended consequences.';
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
    final list = [...pool]..shuffle();
    return list.where((e) => e != correct).take(n).toList();
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

  String _blankFirst(String text, String needle) {
    if (needle.trim().isEmpty) return text;

    final i = text.toLowerCase().indexOf(needle.toLowerCase());
    if (i < 0) return text;

    final before = text.substring(0, i);
    final after = text.substring(i + needle.length);
    return '${before}____(   )____$after';
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
