import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/domain/story_project.dart';
import 'package:questory/features/story_studio/application/story_editor_controller.dart';

void main() {
  late StoryEditorController editor;

  setUp(() {
    editor = StoryEditorController(_document());
  });

  tearDown(() {
    editor.dispose();
  });

  test('selects, moves, resizes, rotates, and records one gesture undo', () {
    editor.select('photo');
    final before = editor.selectedElement!.transform;

    editor.beginInteraction();
    editor.updateInteraction(
      deltaX: 80,
      deltaY: 100,
      scale: 1.25,
      rotation: math.pi / 12,
    );
    editor.endInteraction();

    final after = editor.selectedElement!.transform;
    expect(after.x, isNot(before.x));
    expect(after.y, isNot(before.y));
    expect(after.width, greaterThan(before.width));
    expect(after.rotation, closeTo(math.pi / 12, 0.0001));
    expect(editor.canUndo, isTrue);

    editor.undo();
    expect(editor.selectedElement!.transform.toJson(), before.toJson());
    editor.redo();
    expect(editor.selectedElement!.transform.toJson(), after.toJson());
  });

  test('snaps a dragged element to the canvas center and exposes guides', () {
    editor.select('photo');
    editor.beginInteraction();
    editor.updateInteraction(
      deltaX: 339,
      deltaY: 0,
    );

    expect(
      editor.guides.any((guide) => guide.axis == StoryGuideAxis.vertical),
      isTrue,
    );
    expect(
      editor.selectedElement!.transform.x +
          editor.selectedElement!.transform.width / 2,
      storyCanvasWidth / 2,
    );
    editor.endInteraction();
    expect(editor.guides, isEmpty);
  });

  test('duplicates, reorders, and deletes without mutating the source layer',
      () {
    editor.select('photo');
    final source = editor.selectedElement!;
    editor.duplicateSelected();

    expect(editor.document.elements, hasLength(3));
    expect(editor.selectedElement!.id, startsWith('photo-copy-'));
    expect(editor.selectedElement!.zIndex, greaterThan(source.zIndex));

    editor.sendBackward();
    editor.sendBackward();
    expect(editor.selectedElement!.zIndex, 0);
    expect(editor.document.elementById(source.id)!.zIndex, 1);

    final duplicateId = editor.selectedElement!.id;
    editor.deleteSelected();
    expect(editor.document.elementById(duplicateId), isNull);
    expect(editor.document.elementById(source.id), isNotNull);
  });

  test('edits photo crop and font with undo and redo', () {
    editor.select('photo');
    editor.updatePhotoCrop(focalX: 0.75, focalY: -0.4, zoom: 3);
    editor.updateSelectedFont('Space Grotesk');

    expect(editor.selectedElement!.photoCrop.zoom, 3);
    expect(editor.selectedElement!.photoCrop.focalX, 0.75);
    expect(editor.selectedElement!.style.fontFamily, 'Space Grotesk');

    editor.undo();
    expect(editor.selectedElement!.style.fontFamily, 'Noto Sans');
    editor.undo();
    expect(editor.selectedElement!.photoCrop.zoom, 1);
    editor.redo();
    editor.redo();
    expect(editor.selectedElement!.style.fontFamily, 'Space Grotesk');
  });

  test('keeps transformed elements inside the canonical canvas', () {
    editor.select('photo');
    editor.moveSelected(5000, 5000);
    final transform = editor.selectedElement!.transform;

    expect(transform.x + transform.width, lessThanOrEqualTo(storyCanvasWidth));
    expect(
      transform.y + transform.height,
      lessThanOrEqualTo(storyCanvasHeight),
    );
  });
}

StoryDocument _document() {
  return StoryDocument(
    id: 'editor-test',
    title: 'Editor test',
    backgroundColor: 0xFFFFFFFF,
    elements: [
      StoryElement(
        id: 'photo',
        type: StoryElementType.photo,
        transform: const StoryTransform(
          x: 101,
          y: 100,
          width: 200,
          height: 300,
        ),
        zIndex: 0,
      ),
      StoryElement(
        id: 'text',
        type: StoryElementType.text,
        transform: const StoryTransform(
          x: 440,
          y: 600,
          width: 200,
          height: 100,
        ),
        zIndex: 1,
        content: 'RUN',
      ),
    ],
  );
}
