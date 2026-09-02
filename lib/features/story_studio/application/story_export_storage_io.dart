import 'dart:io';
import 'dart:typed_data';

Future<String> storeStoryPng(Uint8List bytes, String fileName) async {
  final exportDirectory = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}questory_exports',
  );
  await exportDirectory.create(recursive: true);
  final file = File(
    '${exportDirectory.path}${Platform.pathSeparator}$fileName',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
