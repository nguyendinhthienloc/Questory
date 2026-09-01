import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../core/contracts/share_service.dart';
import '../../../core/contracts/story_renderer.dart';
import '../../../core/domain/story_project.dart';

class BoundaryStoryRenderer implements StoryRenderer {
  BoundaryStoryRenderer({required this.boundaryKey});

  final GlobalKey boundaryKey;

  @override
  Future<StoryExport> renderPng(StoryDocument document) async {
    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('The story canvas is not ready to export.');
    }

    final image = await renderObject.toImage(pixelRatio: 1);
    try {
      if (image.width != storyCanvasWidth.toInt() ||
          image.height != storyCanvasHeight.toInt()) {
        throw StateError(
          'Expected a 1080 x 1920 export, got '
          '${image.width} x ${image.height}.',
        );
      }
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Flutter could not encode the story as PNG.');
      }
      final exportDirectory = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'questory_exports',
      );
      await exportDirectory.create(recursive: true);
      final safeId = document.id.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '-');
      final file = File(
        '${exportDirectory.path}${Platform.pathSeparator}'
        'questory-$safeId.png',
      );
      await file.writeAsBytes(
        byteData.buffer.asUint8List(),
        flush: true,
      );
      return StoryExport(
        path: file.path,
        width: image.width,
        height: image.height,
      );
    } finally {
      image.dispose();
    }
  }
}

class AndroidShareService implements ShareService {
  const AndroidShareService();

  static const MethodChannel _channel = MethodChannel('questory/story_share');

  @override
  Future<void> sharePng({required String path, required String title}) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Story sharing is currently available on Android.',
      );
    }
    await _channel.invokeMethod<void>('sharePng', {
      'path': path,
      'title': title,
    });
  }
}
