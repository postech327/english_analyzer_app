import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/student_mock_exam_service.dart';
import 'mock_exam_result_screen.dart';

class MockExamTakeScreen extends StatefulWidget {
  const MockExamTakeScreen({
    super.key,
    required this.mockExamId,
    required this.title,
  });

  final int mockExamId;
  final String title;

  @override
  State<MockExamTakeScreen> createState() => _MockExamTakeScreenState();
}

class _MockExamTakeScreenState extends State<MockExamTakeScreen> {
  static const _surface = Color(0xFFF6F8FC);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _blue = Color(0xFF2563EB);
  static const _purple = Color(0xFF7C3AED);
  static const _line = Color(0xFFE5E7EB);

  late Future<Map<String, dynamic>> _future;
  final Map<int, int> _selectedAnswers = {};
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 40);
  int _currentIndex = 0;
  bool _isSubmitting = false;
  bool _isPassageExpanded = true;
  bool _timerEnabled = true;
  bool _timeUpNotified = false;

  @override
  void initState() {
    super.initState();
    _future = StudentMockExamService.fetchMockExamDetail(widget.mockExamId);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _asText(dynamic value, [String fallback = '-']) {
    final text = value?.toString() ?? '';
    return text.trim().isEmpty || text == 'null' ? fallback : text;
  }

  List<dynamic> _asList(dynamic value) {
    return value is List ? value : const [];
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_timerEnabled) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_timerEnabled) return;
      if (_remaining.inSeconds <= 0) {
        _timer?.cancel();
        if (!_timeUpNotified) {
          _timeUpNotified = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('시간이 종료되었습니다. 제출해 주세요.')),
          );
        }
        return;
      }
      setState(() {
        _remaining = Duration(seconds: _remaining.inSeconds - 1);
      });
    });
  }

  void _toggleTimer(bool enabled) {
    setState(() {
      _timerEnabled = enabled;
      if (!enabled) {
        _timer?.cancel();
      } else if (_remaining.inSeconds <= 0) {
        _remaining = const Duration(minutes: 40);
        _timeUpNotified = false;
      }
    });
    if (enabled) _startTimer();
  }

  String _timerText() {
    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _selectAnswer(int questionId, int selectedIndex) {
    setState(() {
      _selectedAnswers[questionId] = selectedIndex;
    });
  }

  void _goTo(int index) {
    setState(() {
      _currentIndex = index;
      _isPassageExpanded = true;
    });
  }

  Future<void> _submit(List<dynamic> questions, String title) async {
    final unanswered = <int>[];
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i] is Map ? questions[i] as Map : const {};
      final id = _asInt(question['id']);
      if (!_selectedAnswers.containsKey(id)) {
        unanswered.add(i + 1);
      }
    }

    if (unanswered.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('아직 선택하지 않은 문제가 있습니다: ${unanswered.join(", ")}번')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await StudentMockExamService.submitMockExam(
        mockExamId: widget.mockExamId,
        answers: _selectedAnswers.entries
            .map(
              (entry) => {
                'question_id': entry.key,
                'selected_index': entry.value,
              },
            )
            .toList(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MockExamResultScreen(
            title: title,
            result: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모의고사 제출 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _surface,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: _surface,
            appBar: AppBar(
              backgroundColor: _surface,
              foregroundColor: _ink,
              elevation: 0,
              title: const Text('Mock Exam'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('모의고사를 불러오지 못했습니다.\n${snapshot.error}'),
              ),
            ),
          );
        }

        final exam = snapshot.data ?? const {};
        final title = _asText(exam['title'], widget.title);
        final questions = _asList(exam['questions']);
        if (questions.isEmpty) {
          return Scaffold(
            backgroundColor: _surface,
            appBar: AppBar(
              backgroundColor: _surface,
              foregroundColor: _ink,
              elevation: 0,
              title: Text(title),
            ),
            body: const Center(child: Text('등록된 문항이 없습니다.')),
          );
        }

        _currentIndex = _currentIndex.clamp(0, questions.length - 1).toInt();
        final current = questions[_currentIndex] is Map
            ? Map<String, dynamic>.from(questions[_currentIndex] as Map)
            : <String, dynamic>{};
        final questionId = _asInt(current['id']);
        final selectedIndex = _selectedAnswers[questionId];

        return Scaffold(
          backgroundColor: _surface,
          appBar: AppBar(
            backgroundColor: _surface,
            foregroundColor: _ink,
            elevation: 0,
            title: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _progressHeader(questions),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                    children: [
                      _questionNavigator(questions),
                      const SizedBox(height: 12),
                      _passageCard(current),
                      const SizedBox(height: 14),
                      _questionCard(
                        question: current,
                        selectedIndex: selectedIndex,
                        onSelect: (index) => _selectAnswer(questionId, index),
                      ),
                    ],
                  ),
                ),
                _bottomBar(questions, title),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _progressHeader(List<dynamic> questions) {
    final total = questions.length;
    final answered = _selectedAnswers.length;
    final progress = total == 0 ? 0.0 : answered / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _badge('문제 ${_currentIndex + 1}/$total'),
              _badge('선택 $answered/$total'),
              _timerBadge(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFEFF6FF),
              valueColor: const AlwaysStoppedAnimation<Color>(_blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerBadge() {
    final isUrgent = _timerEnabled && _remaining.inSeconds <= 300;
    return InkWell(
      onTap: () => _toggleTimer(!_timerEnabled),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              _timerEnabled ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _timerEnabled ? Icons.timer_rounded : Icons.timer_off_rounded,
              size: 15,
              color: isUrgent ? const Color(0xFFDC2626) : _blue,
            ),
            const SizedBox(width: 5),
            Text(
              _timerEnabled ? '남은 시간 ${_timerText()}' : '타이머 꺼짐',
              style: TextStyle(
                color: isUrgent ? const Color(0xFFDC2626) : _blue,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionNavigator(List<dynamic> questions) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(radius: 22),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(questions.length, (index) {
          final item =
              questions[index] is Map ? questions[index] as Map : const {};
          final id = _asInt(item['id']);
          final isCurrent = index == _currentIndex;
          final isAnswered = _selectedAnswers.containsKey(id);

          final background = isCurrent
              ? _blue
              : isAnswered
                  ? const Color(0xFFF3E8FF)
                  : Colors.white;
          final color = isCurrent
              ? Colors.white
              : isAnswered
                  ? _purple
                  : _muted;

          return InkWell(
            onTap: () => _goTo(index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: Border.all(color: isCurrent ? _blue : _line),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _passageCard(Map<String, dynamic> question) {
    final source = _asText(question['source'], '');
    final questionType = _asText(question['question_type'], '').toLowerCase();

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                setState(() => _isPassageExpanded = !_isPassageExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.article_outlined, color: _blue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      source.isEmpty ? '지문' : source,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _isPassageExpanded ? '접기' : '열기',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(
                    _isPassageExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: _muted,
                  ),
                ],
              ),
            ),
          ),
          if (_isPassageExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: _passageContent(question, questionType),
            ),
        ],
      ),
    );
  }

  Widget _passageContent(Map<String, dynamic> question, String questionType) {
    if (questionType == 'order') {
      return _orderPassageContent(_orderDisplayText(question));
    }
    if (questionType == 'insertion') {
      return _insertionPassageContent(question);
    }

    final passage = _asText(question['passage'], '');
    return SelectableText.rich(
      _htmlLikeTextSpan(passage.isEmpty ? '-' : passage),
    );
  }

  String _orderDisplayText(Map<String, dynamic> question) {
    final passage = _asText(question['passage'], '');
    final questionText = _asText(question['question_text'], '');
    if (_looksLikeOrderText(passage)) return passage;
    if (_looksLikeOrderText(questionText)) return questionText;
    return passage;
  }

  bool _looksLikeOrderText(String text) {
    return text.contains('(A)') && text.contains('(B)') && text.contains('(C)');
  }

  Widget _orderPassageContent(String text) {
    final sections = _splitOrderSections(text);
    if (sections.isEmpty) {
      return SelectableText.rich(_htmlLikeTextSpan(text.isEmpty ? '-' : text));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final label = section.$1;
        final body = section.$2;
        final isGiven = label == 'Given Text' || label == '주어진 글';
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isGiven ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isGiven ? const Color(0xFFBFDBFE) : _line,
            ),
          ),
          child: SelectableText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label\n',
                  style: TextStyle(
                    color: isGiven ? _blue : _purple,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.55,
                  ),
                ),
                ..._htmlLikeTextSpan(body).children ?? [],
              ],
              style: _passageTextStyle(),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<(String, String)> _splitOrderSections(String raw) {
    var text = raw
        .replaceAll(RegExp(r'\[Given Text\]', caseSensitive: false), '주어진 글')
        .replaceAll(RegExp(r'Given Text\s*:?', caseSensitive: false), '주어진 글')
        .replaceAll(RegExp(r'\s*\(A\)\s*'), '\n(A) ')
        .replaceAll(RegExp(r'\s*\(B\)\s*'), '\n(B) ')
        .replaceAll(RegExp(r'\s*\(C\)\s*'), '\n(C) ')
        .trim();

    final firstPart = text.indexOf(RegExp(r'\([ABC]\)'));
    if (firstPart == -1) return const [];

    final given = text.substring(0, firstPart).trim();
    final partsText = text.substring(firstPart);
    final partPattern = RegExp(r'\(([ABC])\)\s*([\s\S]*?)(?=\n\([ABC]\)|$)');
    final sections = <(String, String)>[];
    if (given.isNotEmpty) {
      sections
          .add(('주어진 글', given.replaceFirst(RegExp(r'^주어진 글\s*:?\s*'), '')));
    }
    for (final match in partPattern.allMatches(partsText)) {
      final label = match.group(1) ?? '';
      final body = (match.group(2) ?? '').trim();
      if (body.isNotEmpty) sections.add(('($label)', body));
    }
    return sections;
  }

  Widget _insertionPassageContent(Map<String, dynamic> question) {
    final rawPassage = _asText(question['passage'], '');
    final insertionSentence = _extractInsertionSentence(question);
    final body = _insertionBodyText(rawPassage, insertionSentence);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insertionSentence.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: SelectableText.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '주어진 문장\n',
                    style: TextStyle(
                      color: _blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.55,
                    ),
                  ),
                  ..._htmlLikeTextSpan(insertionSentence).children ?? [],
                ],
                style: _passageTextStyle(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SelectableText.rich(
            _htmlLikeTextSpan(body.isEmpty ? rawPassage : body)),
      ],
    );
  }

  String _extractInsertionSentence(Map<String, dynamic> question) {
    final passage = _asText(question['passage'], '');
    final questionText = _asText(question['question_text'], '');
    final passageParts = passage.split(RegExp(r'\n\s*\n+'));
    if (passageParts.length >= 2 &&
        !_containsInsertionMarkers(passageParts.first)) {
      return passageParts.first.trim();
    }

    final quoted = RegExp(r'["“](.+?)["”]').firstMatch(questionText);
    if (quoted != null) return quoted.group(1)?.trim() ?? '';
    return '';
  }

  String _insertionBodyText(String passage, String insertionSentence) {
    var body = passage.trim();
    if (insertionSentence.isNotEmpty && body.startsWith(insertionSentence)) {
      body = body.substring(insertionSentence.length).trim();
    }
    body = body.replaceAll(RegExp(r'^\n+'), '').trim();

    if (_containsInsertionMarkers(body)) {
      return body;
    }

    final sentences = body
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (sentences.isEmpty) return body;

    final buffer = StringBuffer();
    for (var i = 0; i < sentences.length; i++) {
      if (i < 5) buffer.write('(${_circled(i)}) ');
      buffer.write(sentences[i]);
      if (i != sentences.length - 1) buffer.write(' ');
    }
    return buffer.toString();
  }

  bool _containsInsertionMarkers(String text) {
    return RegExp(r'[①②③④⑤]|\(\s*[①②③④⑤]\s*\)').hasMatch(text);
  }

  Widget _questionCard({
    required Map<String, dynamic> question,
    required int? selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    final number = _asInt(question['number']);
    final questionType = _asText(question['question_type'], '').toLowerCase();
    final typeLabel =
        _asText(question['type_label'], _asText(question['question_type']));
    final questionText = _questionPrompt(question);
    final options = _displayOptions(questionType, _asList(question['options']));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge(typeLabel),
              const Spacer(),
              Text(
                'Q$number',
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SelectableText.rich(
            _htmlLikeTextSpan(
              questionText,
              baseStyle: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 16.2,
                height: 1.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final text = entry.value;
            final isSelected = selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onSelect(index),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? _blue : _line,
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? _blue : const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? _blue : _line),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: _htmlLikeTextSpan(
                            '${_circled(index)} $text'.trim(),
                            baseStyle: TextStyle(
                              color: const Color(0xFF111827),
                              fontSize: 15.4,
                              height: 1.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _questionPrompt(Map<String, dynamic> question) {
    final questionType = _asText(question['question_type'], '').toLowerCase();
    final text = _asText(question['question_text'], '');
    if (questionType == 'order' && _looksLikeOrderText(text)) {
      return '주어진 글 다음에 이어질 글의 순서로 가장 적절한 것은?';
    }
    if (questionType == 'insertion') {
      return '글의 흐름으로 보아, 주어진 문장이 들어가기에 가장 적절한 곳은?';
    }
    return text;
  }

  List<String> _displayOptions(String questionType, List<dynamic> options) {
    if (questionType == 'order') {
      const orderChoices = [
        '(A)-(C)-(B)',
        '(B)-(A)-(C)',
        '(B)-(C)-(A)',
        '(C)-(A)-(B)',
        '(C)-(B)-(A)',
      ];
      if (_optionsLookLikeOrderChoices(options)) {
        return options.map((item) => _stripLeadingChoice('$item')).toList();
      }
      return orderChoices;
    }

    if (questionType == 'insertion') {
      return const ['1', '2', '3', '4', '5'];
    }

    return options.map((item) => _stripLeadingChoice('$item')).toList();
  }

  bool _optionsLookLikeOrderChoices(List<dynamic> options) {
    return options.length == 5 &&
        options.every((item) =>
            RegExp(r'\([ABC]\)-\([ABC]\)-\([ABC]\)').hasMatch('$item'));
  }

  String _stripLeadingChoice(String text) {
    return text
        .trim()
        .replaceFirst(RegExp(r'^\s*(?:[①②③④⑤]|[1-5][\.\)]?)\s*'), '')
        .trim();
  }

  TextSpan _htmlLikeTextSpan(String text, {TextStyle? baseStyle}) {
    final style = baseStyle ?? _passageTextStyle();
    final spans = <TextSpan>[];
    final underlinePattern = RegExp(
      r'^<\s*u(?:\s+[^>]*)?>[\s\S]*?<\s*/\s*u\s*>$',
      caseSensitive: false,
    );
    final pattern = RegExp(
      r'(<\s*u(?:\s+[^>]*)?>[\s\S]*?<\s*/\s*u\s*>|[①②③④⑤]|\([ABC]\)|\[Given Text\]|주어진 글)',
      caseSensitive: false,
    );
    var cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, match.start), style: style),
        );
      }

      final token = match.group(0) ?? '';
      final underline = underlinePattern.hasMatch(token);
      final clean = underline
          ? token
              .replaceFirst(
                RegExp(r'^<\s*u(?:\s+[^>]*)?>', caseSensitive: false),
                '',
              )
              .replaceFirst(
                RegExp(r'<\s*/\s*u\s*>$', caseSensitive: false),
                '',
              )
          : token;
      spans.add(
        TextSpan(
          text: clean,
          style: underline
              ? style.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: style.color ?? _ink,
                  decorationThickness: 1.5,
                )
              : _markerStyle(token, style),
        ),
      );
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }

    return TextSpan(children: spans, style: style);
  }

  TextStyle _markerStyle(String token, TextStyle baseStyle) {
    final isMarker = RegExp(r'^[①②③④⑤]$|^\([ABC]\)$|^\[Given Text\]$|^주어진 글$')
        .hasMatch(token);
    if (!isMarker) return baseStyle;
    return baseStyle.copyWith(
      color: token.contains('Given') || token == '주어진 글' ? _blue : _purple,
      fontWeight: FontWeight.w900,
    );
  }

  TextStyle _passageTextStyle() {
    return const TextStyle(
      color: Color(0xFF111827),
      fontSize: 16.2,
      height: 1.74,
      fontWeight: FontWeight.w500,
    );
  }

  Widget _bottomBar(List<dynamic> questions, String title) {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == questions.length - 1;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: _line)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isFirst ? null : () => _goTo(_currentIndex - 1),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('이전'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: _line),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isLast
                  ? FilledButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submit(questions, title),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('제출'),
                      style: _primaryButtonStyle(),
                    )
                  : FilledButton.icon(
                      onPressed: () => _goTo(_currentIndex + 1),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('다음'),
                      style: _primaryButtonStyle(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _blue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _circled(int index) {
    const labels = ['①', '②', '③', '④', '⑤'];
    return index >= 0 && index < labels.length
        ? labels[index]
        : '${index + 1}.';
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  BoxDecoration _cardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
