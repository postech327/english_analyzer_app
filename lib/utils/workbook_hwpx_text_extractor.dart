import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class HwpxTextExtractionResult {
  const HwpxTextExtractionResult({
    required this.text,
    required this.sectionCount,
    required this.paragraphCount,
  });

  final String text;
  final int sectionCount;
  final int paragraphCount;
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

  final paragraphs = <String>[];
  for (final section in sections) {
    final content = section.content;
    final xmlText = utf8.decode(content, allowMalformed: true);
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xmlText);
    } catch (_) {
      throw FormatException('${section.name} 본문 XML을 읽지 못했습니다.');
    }
    final sectionParagraphs = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'p')
        .map(_paragraphText)
        .where((text) => text.isNotEmpty)
        .toList();
    if (sectionParagraphs.isNotEmpty) {
      paragraphs.addAll(sectionParagraphs);
    } else {
      final fallback = document.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 't')
          .map((element) => element.innerText)
          .join(' ')
          .trim();
      if (fallback.isNotEmpty) paragraphs.add(fallback);
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
  );
}

String _paragraphText(XmlElement paragraph) {
  final buffer = StringBuffer();
  for (final element in paragraph.descendants.whereType<XmlElement>()) {
    switch (element.name.local) {
      case 't':
        buffer.write(element.innerText);
      case 'tab':
        buffer.write('\t');
      case 'lineBreak':
      case 'br':
        buffer.write('\n');
    }
  }
  return buffer
      .toString()
      .replaceAll('\u200B', '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\s*\n\s*'), '\n')
      .trim();
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
