import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class HwpxTextExtractionResult {
  const HwpxTextExtractionResult({
    required this.text,
    required this.sectionCount,
    required this.paragraphCount,
    this.paragraphs = const <String>[],
    this.paragraphRuns = const <List<String>>[],
    this.paragraphIndexes = const <int>[],
    this.paragraphUnderlineRanges = const <List<HwpxUnderlineRange>>[],
  });

  final String text;
  final int sectionCount;
  final int paragraphCount;
  final List<String> paragraphs;
  final List<List<String>> paragraphRuns;
  final List<int> paragraphIndexes;
  final List<List<HwpxUnderlineRange>> paragraphUnderlineRanges;
}

class HwpxUnderlineRange {
  const HwpxUnderlineRange({
    required this.start,
    required this.end,
    required this.text,
    this.runStartIndex = -1,
    this.runEndIndex = -1,
  });

  final int start;
  final int end;
  final String text;
  final int runStartIndex;
  final int runEndIndex;
}

HwpxTextExtractionResult extractWorkbookTextFromHwpx(List<int> bytes) {
  if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
    throw const FormatException('올바른 HWPX 파일이 아닙니다.');
  }

  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const FormatException('HWPX 압축 구조를 읽지 못했습니다.');
  }

  final sections = archive.files.where((file) {
    final name = file.name.replaceAll('\\', '/').toLowerCase();
    return file.isFile &&
        RegExp(r'(^|/)contents/section\d+\.xml$').hasMatch(name);
  }).toList()
    ..sort((left, right) =>
        _sectionNumber(left.name).compareTo(_sectionNumber(right.name)));
  if (sections.isEmpty) {
    throw const FormatException('HWPX 본문 섹션을 찾지 못했습니다.');
  }

  final underlinedCharacterProperties =
      _underlinedCharacterPropertyIds(archive);

  final paragraphs = <String>[];
  final paragraphRuns = <List<String>>[];
  final paragraphIndexes = <int>[];
  final paragraphUnderlineRanges = <List<HwpxUnderlineRange>>[];
  var xmlParagraphIndex = 0;
  for (final section in sections) {
    final content = section.content;
    final xmlText = utf8.decode(content, allowMalformed: true);
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xmlText);
    } catch (_) {
      throw FormatException('${section.name} 본문 XML을 읽지 못했습니다.');
    }
    final sectionParagraphElements = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'p')
        .toList();
    final sectionParagraphs = <String>[];
    for (final paragraph in sectionParagraphElements) {
      final content = _paragraphContent(
        paragraph,
        underlinedCharacterProperties,
      );
      final text = content.text;
      if (text.isNotEmpty) {
        sectionParagraphs.add(text);
        paragraphRuns.add(_paragraphRuns(paragraph));
        paragraphIndexes.add(xmlParagraphIndex);
        paragraphUnderlineRanges.add(content.underlineRanges);
      }
      xmlParagraphIndex++;
    }
    if (sectionParagraphs.isNotEmpty) {
      paragraphs.addAll(sectionParagraphs);
    } else {
      final fallback = document.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 't')
          .map((element) => element.innerText)
          .join(' ')
          .trim();
      if (fallback.isNotEmpty) {
        paragraphs.add(fallback);
        paragraphRuns.add(<String>[fallback]);
        paragraphIndexes.add(xmlParagraphIndex++);
        paragraphUnderlineRanges.add(const <HwpxUnderlineRange>[]);
      }
    }
  }

  final text = paragraphs.join('\n\n').replaceAll('\u00A0', ' ').trim();
  if (text.isEmpty) {
    throw const FormatException('HWPX 파일에서 텍스트를 찾지 못했습니다.');
  }
  return HwpxTextExtractionResult(
    text: text,
    sectionCount: sections.length,
    paragraphCount: paragraphs.length,
    paragraphs: List<String>.unmodifiable(paragraphs),
    paragraphRuns: List<List<String>>.unmodifiable(
      paragraphRuns.map(List<String>.unmodifiable),
    ),
    paragraphIndexes: List<int>.unmodifiable(paragraphIndexes),
    paragraphUnderlineRanges: List<List<HwpxUnderlineRange>>.unmodifiable(
      paragraphUnderlineRanges.map(List<HwpxUnderlineRange>.unmodifiable),
    ),
  );
}

Set<String> _underlinedCharacterPropertyIds(Archive archive) {
  final ids = <String>{};
  final headers = archive.files.where((file) {
    final name = file.name.replaceAll('\\', '/').toLowerCase();
    return file.isFile && name.endsWith('contents/header.xml');
  });
  for (final header in headers) {
    final document = XmlDocument.parse(
      utf8.decode(header.content, allowMalformed: true),
    );
    for (final charPr in document.descendants.whereType<XmlElement>().where(
          (element) => element.name.local == 'charPr',
        )) {
      final underline = charPr.childElements.where(
        (element) => element.name.local == 'underline',
      );
      if (underline.isEmpty) continue;
      final type = underline.first.getAttribute('type')?.toUpperCase() ?? '';
      if (type.isNotEmpty && type != 'NONE') {
        final id = charPr.getAttribute('id');
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }
  }
  return ids;
}

_ParagraphContent _paragraphContent(
  XmlElement paragraph,
  Set<String> underlinedCharacterProperties,
) {
  final raw = StringBuffer();
  final rawUnderlineSegments = <_RawUnderlineSegment>[];
  var underlinedBuffer = StringBuffer();
  var underlineRunStart = -1;
  var underlineRunEnd = -1;
  final runs = paragraph.descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == 'run')
      .toList(growable: false);

  void flushUnderline() {
    if (underlinedBuffer.isNotEmpty) {
      rawUnderlineSegments.add(
        _RawUnderlineSegment(
          text: underlinedBuffer.toString(),
          runStartIndex: underlineRunStart,
          runEndIndex: underlineRunEnd,
        ),
      );
      underlinedBuffer = StringBuffer();
      underlineRunStart = -1;
      underlineRunEnd = -1;
    }
  }

  for (final element in paragraph.descendants.whereType<XmlElement>()) {
    String value;
    switch (element.name.local) {
      case 't':
        value = element.innerText;
      case 'tab':
        value = '\t';
      case 'lineBreak':
      case 'br':
        value = '\n';
      default:
        continue;
    }
    final run = element.ancestors.whereType<XmlElement>().firstWhere(
          (ancestor) => ancestor.name.local == 'run',
          orElse: () => paragraph,
        );
    final isUnderlined = underlinedCharacterProperties.contains(
      run.getAttribute('charPrIDRef'),
    );
    final runIndex = runs.indexOf(run);
    raw.write(value);
    if (isUnderlined) {
      if (underlineRunStart == -1) underlineRunStart = runIndex;
      underlineRunEnd = runIndex;
      underlinedBuffer.write(value);
    } else {
      flushUnderline();
    }
  }
  flushUnderline();

  final text = _normalizeParagraphText(raw.toString());
  final ranges = <HwpxUnderlineRange>[];
  var searchFrom = 0;
  for (final rawSegment in rawUnderlineSegments) {
    final segment = _normalizeParagraphText(rawSegment.text);
    if (segment.isEmpty || _isBlankPlaceholderOnly(segment)) continue;
    var start = text.indexOf(segment, searchFrom);
    if (start < 0) start = text.indexOf(segment);
    if (start < 0) continue;
    final end = start + segment.length;
    if (ranges.isNotEmpty &&
        start >= ranges.last.end &&
        text.substring(ranges.last.end, start).trim().isEmpty) {
      final previous = ranges.removeLast();
      ranges.add(
        HwpxUnderlineRange(
          start: previous.start,
          end: end,
          text: text.substring(previous.start, end),
          runStartIndex: previous.runStartIndex,
          runEndIndex: rawSegment.runEndIndex,
        ),
      );
    } else {
      ranges.add(
        HwpxUnderlineRange(
          start: start,
          end: end,
          text: segment,
          runStartIndex: rawSegment.runStartIndex,
          runEndIndex: rawSegment.runEndIndex,
        ),
      );
    }
    searchFrom = end;
  }
  return _ParagraphContent(text: text, underlineRanges: ranges);
}

bool _isBlankPlaceholderOnly(String text) =>
    RegExp(r'^\s*(?:_{2,}|\[\s*\])\s*$').hasMatch(text);

String _normalizeParagraphText(String raw) => raw
    .replaceAll('\u200B', '')
    .replaceAll('\u00A0', ' ')
    .replaceAll(RegExp(r'[ \t]+'), ' ')
    .replaceAll(RegExp(r'\s*\n\s*'), '\n')
    .trim();

class _ParagraphContent {
  const _ParagraphContent({required this.text, required this.underlineRanges});

  final String text;
  final List<HwpxUnderlineRange> underlineRanges;
}

class _RawUnderlineSegment {
  const _RawUnderlineSegment({
    required this.text,
    required this.runStartIndex,
    required this.runEndIndex,
  });

  final String text;
  final int runStartIndex;
  final int runEndIndex;
}

List<String> _paragraphRuns(XmlElement paragraph) {
  return paragraph.descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == 't')
      .map((element) => element.innerText)
      .where((text) => text.isNotEmpty)
      .toList(growable: false);
}

int _sectionNumber(String name) {
  return int.tryParse(
        RegExp(
              r'section(\d+)\.xml$',
              caseSensitive: false,
            ).firstMatch(name)?.group(1) ??
            '',
      ) ??
      0;
}
