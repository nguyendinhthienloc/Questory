import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/contracts/share_service.dart';
import '../../../core/contracts/story_renderer.dart';
import '../../../core/domain/story_project.dart';
import 'story_export_storage.dart';
import 'story_share_platform.dart';

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
      final safeId = document.id.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '-');
      final path = await storeStoryPng(
        byteData.buffer.asUint8List(),
        'questory-$safeId.png',
      );
      return StoryExport(
        path: path,
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

  @override
  Future<void> sharePng({required String path, required String title}) async {
    await shareStoryPng(path: path, title: title);
  }
}
