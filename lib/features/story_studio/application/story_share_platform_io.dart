import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('questory/story_share');

Future<void> shareStoryPng(
    {required String path, required String title}) async {
  if (!Platform.isAndroid) {
    throw UnsupportedError('Story sharing is currently available on Android.');
  }
  await _channel.invokeMethod<void>('sharePng', {
    'path': path,
    'title': title,
  });
}
