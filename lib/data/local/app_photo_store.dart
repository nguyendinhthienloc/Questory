import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/contracts/photo_store.dart';

class AppPhotoStore implements PhotoStore {
  const AppPhotoStore();

  @override
  Future<String> retain({
    required String temporaryPath,
    required String evidenceId,
  }) async {
    final source = File(temporaryPath);
    if (!await source.exists()) {
      throw StateError('The captured photo is no longer available.');
    }
    final support = await getApplicationSupportDirectory();
    final directory = Directory(
      '${support.path}${Platform.pathSeparator}questory_photos',
    );
    await directory.create(recursive: true);
    final safeId = evidenceId.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '-');
    final destination = File(
      '${directory.path}${Platform.pathSeparator}$safeId.jpg',
    );
    await source.copy(destination.path);
    return destination.path;
  }

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
