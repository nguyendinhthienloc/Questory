import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> storeStoryPng(Uint8List bytes, String fileName) async {
  // Android's FileProvider exposes cacheDir, while Directory.systemTemp points
  // to code_cache on some devices and cannot be shared.
  final cacheDirectory =
      Platform.isAndroid ? await getTemporaryDirectory() : Directory.systemTemp;
  final exportDirectory = Directory(
    '${cacheDirectory.path}${Platform.pathSeparator}questory_exports',
  );
  await exportDirectory.create(recursive: true);
  final file = File(
    '${exportDirectory.path}${Platform.pathSeparator}$fileName',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
