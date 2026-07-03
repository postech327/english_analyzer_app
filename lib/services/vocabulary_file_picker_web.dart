// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'picked_upload_file.dart';

Future<PickedUploadFile?> pickVocabularyImportFile() async {
  final input = html.FileUploadInputElement()
    ..accept = '.hwpx,.txt,.hwp,text/plain,application/zip'
    ..multiple = false;
  input.click();
  await input.onChange.first;
  final files = input.files ?? const <html.File>[];
  if (files.isEmpty) return null;

  final file = files.first;
  final reader = html.FileReader();
  final completer = Completer<PickedUploadFile>();
  reader.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.completeError('파일을 읽지 못했습니다.');
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
