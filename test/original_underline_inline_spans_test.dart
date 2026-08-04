import 'package:english_analyzer_app/utils/blank_display_passage.dart';
import 'package:english_analyzer_app/utils/original_underline_inline_spans.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('styles only stored original underline ranges', () {
    const passage = 'Before rugged individualism after.';
    final start = passage.indexOf('rugged');
    final span = buildQuestionOriginalUnderlineInlineSpans(
      questionType: 'implication',
      passage: passage,
      specialData: <String, dynamic>{
        'underline_ranges': <Map<String, dynamic>>[
          <String, dynamic>{
            'start': start,
            'end': start + 'rugged individualism'.length,
            'text': 'rugged individualism',
          },
        ],
      },
      baseStyle: const TextStyle(color: Colors.black),
    );

    final children = span.children!.cast<TextSpan>();
    expect(children.map((child) => child.text).join(), passage);
    expect(children[1].text, 'rugged individualism');
    expect(children[1].style?.decoration, TextDecoration.underline);
    expect(children.first.style?.decoration, isNot(TextDecoration.underline));
  });

  test('blank renders only its placeholder and ignores original ranges', () {
    const passage = 'A clear target helps us ______ the result.';
    final span = buildBlankPassageInlineSpans(
      passage: passage,
      baseStyle: const TextStyle(color: Colors.black),
    );

    final leaves = <TextSpan>[];
    void collect(InlineSpan current) {
      if (current is! TextSpan) return;
      if (current.text != null) leaves.add(current);
      for (final child in current.children ?? const <InlineSpan>[]) {
        collect(child);
      }
    }

    collect(span);
    expect(
      leaves.any(
        (leaf) =>
            leaf.text?.contains('clear target') == true &&
            leaf.style?.decoration == TextDecoration.underline,
      ),
      isFalse,
    );
    expect(
      leaves.any(
        (leaf) =>
            leaf.text?.contains('\u00A0') == true &&
            leaf.style?.decoration == TextDecoration.underline,
      ),
      isTrue,
    );
  });

  test('topic title gist blank and general types suppress original ranges', () {
    const passage = 'When they understand what matters, they act.';
    final start = passage.indexOf('When');
    final specialData = <String, dynamic>{
      'underline_ranges': <Map<String, dynamic>>[
        <String, dynamic>{
          'start': start,
          'end': start + 'When'.length,
          'text': 'When',
        },
      ],
    };

    for (final type in <String>['topic', 'title', 'gist', 'blank', 'purpose']) {
      final span = buildQuestionOriginalUnderlineInlineSpans(
        questionType: type,
        passage: passage,
        specialData: specialData,
        baseStyle: const TextStyle(color: Colors.black),
      );
      expect(span.toPlainText(), passage, reason: type);
      expect(span.style?.decoration, isNot(TextDecoration.underline),
          reason: type);
      expect(span.children, isNull, reason: type);
    }
  });

  test('does not invent underline when ranges are absent', () {
    final span = buildOriginalUnderlineInlineSpans(
      passage: 'Plain passage.',
      specialData: const <String, dynamic>{},
      baseStyle: const TextStyle(color: Colors.black),
    );
    final child = span.children!.single as TextSpan;
    expect(child.text, 'Plain passage.');
    expect(child.style?.decoration, isNot(TextDecoration.underline));
  });
}
