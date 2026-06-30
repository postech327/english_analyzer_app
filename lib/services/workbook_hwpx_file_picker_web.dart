// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'picked_upload_file.dart';

Future<PickedUploadFile?> pickWorkbookHwpxFile() async {
  final files = await pickWorkbookHwpxFiles();
  return files.isEmpty ? null : files.first;
}

Future<List<PickedUploadFile>> pickWorkbookHwpxFiles() async {
  final input = html.FileUploadInputElement()
    ..accept = '.hwpx,application/zip'
    ..multiple = true;

  input.click();
  await input.onChange.first;

  final files = input.files ?? const <html.File>[];
  if (files.isEmpty) return const [];

  final picked = <PickedUploadFile>[];
  for (final file in files) {
    picked.add(await _readFile(file));
  }
  return picked;
}

Future<PickedUploadFile> _readFile(html.File file) {
  final reader = html.FileReader();
  final completer = Completer<PickedUploadFile>();
  reader.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.completeError('HWPX 파일을 읽지 못했습니다.');
    }
  });
  reader.onLoadEnd.first.then((_) {
    final result = reader.result;
    final bytes = switch (result) {
      ByteBuffer buffer => Uint8List.view(buffer),
      Uint8List data => data,
      _ => Uint8List(0),
    };
    if (!completer.isCompleted) {
      completer.complete(PickedUploadFile(name: file.name, bytes: bytes));
    }
  });
  reader.readAsArrayBuffer(file);
  return completer.future;
}
