import 'package:flutter_test/flutter_test.dart';
import 'package:questory/features/story_studio/data/story_templates.dart';
import 'package:questory/features/story_studio/domain/story_document.dart';

void main() {
  group('StoryDocument', () {
    test('round-trips through JSON without losing template data', () {
      final original = storyTemplates.first.document;

      final restored = StoryDocument.fromJson(original.toJson());

      expect(restored.toJson(), original.toJson());
    });

    test('rejects unsupported element types', () {
      final json = storyTemplates.first.document.toJson();
      final elements = json['elements']! as List<Map<String, Object?>>;
      elements.first['type'] = 'video';

      expect(
        () => StoryDocument.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('replaces and removes elements immutably', () {
      final original = storyTemplates.first.document;
      final first = original.elements.first;
      final updated = first.copyWith(content: 'UPDATED');

      final replaced = original.replaceElement(updated);
      final removed = replaced.removeElement(updated.id);

      expect(original.elements.first.content, isNot('UPDATED'));
      expect(replaced.elements.first.content, 'UPDATED');
      expect(
        removed.elements.any((element) => element.id == updated.id),
        isFalse,
      );
    });

    test('round-trips photo crop and recorded route geometry', () {
      final original = storyTemplates.first.document;
      final photo = original.elements.firstWhere(
        (element) => element.type == StoryElementType.photo,
      );
      final route = original.elements.firstWhere(
        (element) => element.type == StoryElementType.route,
      );
      final edited = original
          .replaceElement(
            photo.copyWith(
              assetPath: '/private/run/photo.png',
              photoCrop: const StoryPhotoCrop(
                focalX: 0.65,
                focalY: -0.3,
                zoom: 2.25,
              ),
            ),
          )
          .replaceElement(
            route.copyWith(
              routePoints: const [
                StoryCanvasPoint(0, 1),
                StoryCanvasPoint(0.5, 0.4),
                StoryCanvasPoint(1, 0),
              ],
            ),
          );

      final restored = StoryDocument.fromJson(edited.toJson());
      final restoredPhoto = restored.elementById(photo.id)!;
      final restoredRoute = restored.elementById(route.id)!;

      expect(restoredPhoto.photoCrop.zoom, 2.25);
      expect(restoredPhoto.photoCrop.focalX, 0.65);
      expect(restoredRoute.routePoints, hasLength(3));
      expect(restoredRoute.routePoints.last.x, 1);
    });
  });

  group('Story templates', () {
    test('provide three original 1080 x 1920 starting documents', () {
      expect(storyTemplates, hasLength(3));
      expect(
        storyTemplates.map((template) => template.id).toSet(),
        hasLength(3),
      );

      for (final template in storyTemplates) {
        expect(template.document.canvasWidth, storyCanvasWidth);
        expect(template.document.canvasHeight, storyCanvasHeight);
        expect(template.document.elements, isNotEmpty);
      }
    });

    test('cover every planned story element type', () {
      final representedTypes = storyTemplates
          .expand((template) => template.document.elements)
          .map((element) => element.type)
          .toSet();

      expect(representedTypes, StoryElementType.values.toSet());
    });

    test('creates independent draft element identifiers', () {
      final template = storyTemplates.first;

      final firstDraft = template.createDocument(documentId: 'draft-a');
      final secondDraft = template.createDocument(documentId: 'draft-b');

      expect(firstDraft.id, 'draft-a');
      expect(secondDraft.id, 'draft-b');
      expect(
        firstDraft.elements.map((element) => element.id).toSet(),
        isNot(secondDraft.elements.map((element) => element.id).toSet()),
      );
    });
  });
}
