import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/contracts/story_renderer.dart';
import 'package:questory/features/story_studio/application/story_platform_services.dart';
import 'package:questory/features/story_studio/data/story_templates.dart';
import 'package:questory/features/story_studio/presentation/story_canvas.dart';

void main() {
  testWidgets('renders a real PNG at exactly 1080 x 1920', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final boundaryKey = GlobalKey();
    final document = storyTemplates.first.createDocument(
      documentId: 'renderer-test',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryCanvas(
            document: document,
            boundaryKey: boundaryKey,
            showEditorChrome: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    late StoryExport export;
    await tester.runAsync(() async {
      export = await BoundaryStoryRenderer(
        boundaryKey: boundaryKey,
      ).renderPng(document);
    });
    addTearDown(() async {
      final file = File(export.path);
      if (await file.exists()) {
        await file.delete();
      }
    });

    expect(export.width, 1080);
    expect(export.height, 1920);
    await tester.runAsync(() async {
      final bytes = await File(export.path).readAsBytes();
      expect(bytes, isNotEmpty);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1080);
      expect(frame.image.height, 1920);
      frame.image.dispose();
      codec.dispose();
    });
  });
}
