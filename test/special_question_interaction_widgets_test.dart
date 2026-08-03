import 'package:english_analyzer_app/widgets/special_question_interaction_widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selected insertion position has strong contrast and check',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              const StrongPositionChoice(label: '①', selected: true),
              StrongPositionChoice(
                label: '②',
                selected: false,
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    final selected = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('strong-position-①-true')),
    );
    final unselected = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('strong-position-②-false')),
    );
    expect(
        (selected.decoration as BoxDecoration).color, const Color(0xFF2563EB));
    expect((unselected.decoration as BoxDecoration).color, Colors.white);

    await tester.tap(find.text('②'));
    expect(tapped, isTrue);
  });

  testWidgets('insertion markers use inline spaced parentheses without badges',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: InsertionPassageView(
              passage:
                  'Till the ground. ➀ Wood. (➁) Stone. （ ➂ ） Iron. \u00A0➃\u200B Copper. (\u2060➄\uFEFF) Flint. (⑥)',
              selectedPositions: <int>{2, 5},
            ),
          ),
        ),
      ),
    );

    final richText = _richTextInside<InsertionPassageView>(tester);
    final root = richText.text as TextSpan;
    final spans = _flatten(root).toList();
    for (final marker in const <String>[
      '①',
      '②',
      '③',
      '④',
      '⑤',
      '⑥',
    ]) {
      expect(root.toPlainText(), contains('( $marker )'));
    }
    expect(root.toPlainText(), isNot(contains('➀')));
    expect(root.toPlainText(), isNot(contains('➄')));
    expect(root.toPlainText(), isNot(contains('\n')));
    expect(
      find.descendant(
        of: find.byType(InsertionPassageView),
        matching: find.byType(AnimatedContainer),
      ),
      findsNothing,
    );

    final markerSpans = spans
        .where((span) => span.text?.contains(RegExp(r'\( [①-⑨] \)')) ?? false)
        .toList();
    expect(markerSpans, hasLength(6));
    final first = markerSpans[0];
    final second = markerSpans[1];
    final fifth = markerSpans[4];
    expect(first.style?.backgroundColor, Colors.transparent);
    expect(second.style?.backgroundColor, const Color(0xFFEDE9FE));
    expect(fifth.style?.backgroundColor, const Color(0xFFEDE9FE));
    expect(second.style?.fontWeight, FontWeight.w900);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple insertion highlights every selected inline position',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InsertionPassageView(
            passage: 'One. ① Two. ② Three. ③ Four.',
            selectedPositions: <int>{1, 3},
          ),
        ),
      ),
    );

    final root = _richTextInside<InsertionPassageView>(tester).text as TextSpan;
    final markerSpans = _flatten(root)
        .where((span) => span.text?.contains(RegExp(r'\( [①-⑨] \)')) ?? false)
        .toList();
    expect(markerSpans, hasLength(3));
    expect(markerSpans[0].style?.backgroundColor, const Color(0xFFEDE9FE));
    expect(markerSpans[1].style?.backgroundColor, Colors.transparent);
    expect(markerSpans[2].style?.backgroundColor, const Color(0xFFEDE9FE));
  });

  testWidgets(
      'irrelevant sentences share one inline rich text and remain tappable',
      (tester) async {
    int? tappedPosition;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: IrrelevantPassageView(
              passage: '① First sentence.\n'
                  '② Second sentence.\n'
                  '③ Third sentence.',
              selectedPosition: 2,
              onPositionSelected: (position) => tappedPosition = position,
            ),
          ),
        ),
      ),
    );

    final richText = _richTextInside<IrrelevantPassageView>(tester);
    final root = richText.text as TextSpan;
    final spans = _flatten(root).toList();
    expect(root.toPlainText(),
        '❶ First sentence. ❷ Second sentence. ❸ Third sentence. ');
    expect(root.toPlainText(), isNot(contains('\n')));
    expect(
      find.descendant(
        of: find.byType(IrrelevantPassageView),
        matching: find.byType(Wrap),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(IrrelevantPassageView),
        matching: find.byType(AnimatedContainer),
      ),
      findsNothing,
    );

    final firstMarker = spans.singleWhere((span) => span.text == '❶ ');
    final secondMarker = spans.singleWhere((span) => span.text == '❷ ');
    final secondSentence =
        spans.singleWhere((span) => span.text == 'Second sentence. ');
    expect(firstMarker.style?.backgroundColor, Colors.transparent);
    expect(secondMarker.style?.backgroundColor, const Color(0xFFE8F0FF));
    expect(secondSentence.style?.backgroundColor, const Color(0xFFE8F0FF));

    (firstMarker.recognizer as TapGestureRecognizer).onTap!();
    expect(tappedPosition, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline irrelevant rich text wraps at 260px without overflow',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: IrrelevantPassageView(
              passage:
                  '① A long sentence naturally wraps according to the available mobile width without becoming a separate full-width choice card.\n'
                  '② The following sentence continues in the same rich text flow.',
              selectedPosition: 1,
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(IrrelevantPassageView),
        matching: find.byType(RichText),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('irrelevant body and bottom choices stay synchronized at 260px',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 260, child: _IrrelevantSelectionHarness()),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('strong-position-②-true')),
      findsOneWidget,
    );
    final firstButtonTop = tester.getTopLeft(
      find.byKey(const ValueKey('strong-position-①-false')),
    );
    final lastButtonTop = tester.getTopLeft(
      find.byKey(const ValueKey('strong-position-⑦-false')),
    );
    expect(lastButtonTop.dy, greaterThan(firstButtonTop.dy));

    await tester.tap(find.text('③'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('strong-position-③-true')),
      findsOneWidget,
    );
    var root = _richTextInside<IrrelevantPassageView>(tester).text as TextSpan;
    var spans = _flatten(root).toList();
    expect(
      spans.singleWhere((span) => span.text == '❸ ').style?.backgroundColor,
      const Color(0xFFE8F0FF),
    );

    final firstMarker = spans.singleWhere((span) => span.text == '❶ ');
    (firstMarker.recognizer as TapGestureRecognizer).onTap!();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('strong-position-①-true')),
      findsOneWidget,
    );
    root = _richTextInside<IrrelevantPassageView>(tester).text as TextSpan;
    spans = _flatten(root).toList();
    expect(
      spans.singleWhere((span) => span.text == '❶ ').style?.backgroundColor,
      const Color(0xFFE8F0FF),
    );
    expect(tester.takeException(), isNull);
  });
}

RichText _richTextInside<T extends Widget>(WidgetTester tester) {
  return tester.widget<RichText>(
    find.descendant(
      of: find.byType(T),
      matching: find.byType(RichText),
    ),
  );
}

Iterable<TextSpan> _flatten(TextSpan span) sync* {
  yield span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (child is TextSpan) yield* _flatten(child);
  }
}

class _IrrelevantSelectionHarness extends StatefulWidget {
  const _IrrelevantSelectionHarness();

  @override
  State<_IrrelevantSelectionHarness> createState() =>
      _IrrelevantSelectionHarnessState();
}

class _IrrelevantSelectionHarnessState
    extends State<_IrrelevantSelectionHarness> {
  int selected = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IrrelevantPassageView(
          passage: '① First.\n② Second.\n③ Third.\n'
              '④ Fourth.\n⑤ Fifth.\n⑥ Sixth.\n⑦ Seventh.',
          selectedPosition: selected,
          onPositionSelected: (position) {
            setState(() => selected = position);
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var position = 1; position <= 7; position++)
              StrongPositionChoice(
                label: String.fromCharCode(0x2460 + position - 1),
                selected: selected == position,
                onTap: () => setState(() => selected = position),
              ),
          ],
        ),
      ],
    );
  }
}
