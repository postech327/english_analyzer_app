// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'picked_upload_file.dart';

Future<PickedUploadFile?> pickMockExamUploadFile() async {
  final input = html.FileUploadInputElement()
    ..accept = '.xlsx,.xlsm,.csv'
    ..multiple = false;

  input.click();
  await input.onChange.first;

  final file = input.files?.isNotEmpty == true ? input.files!.first : null;
  if (file == null) return null;

  final reader = html.FileReader();
  final completer = Completer<PickedUploadFile?>();

  reader.onError.first.then((_) {
    if (!completer.isCompleted) completer.completeError('파일을 읽지 못했습니다.');
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
