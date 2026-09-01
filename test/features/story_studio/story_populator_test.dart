import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/domain/run_summary.dart';
import 'package:questory/core/domain/story_project.dart';
import 'package:questory/features/story_studio/application/story_populator.dart';
import 'package:questory/features/story_studio/data/story_run_fixture.dart';
import 'package:questory/features/story_studio/data/story_templates.dart';

void main() {
  const populator = StoryPopulator();

  test('populates every recap data category from a RunSummary', () {
    final document = populator.fromRun(
      template: storyTemplates.first,
      summary: storyRunFixture,
      documentId: 'populated-story',
    );
    final content =
        document.elements.map((element) => element.content).join('\n');
    final route = document.elements.firstWhere(
      (element) => element.type == StoryElementType.route,
    );
    final photo = document.elements.firstWhere(
      (element) => element.type == StoryElementType.photo,
    );

    expect(document.sourceRunId, storyRunFixture.id);
    expect(content, contains('NHA TRANG, VIETNAM'));
    expect(content, contains('5.42 KM'));
    expect(content, contains('31:09'));
    expect(content, contains('5:45 /KM'));
    expect(content, contains('EST. CALORIES 326 KCAL'));
    expect(content, contains('Tram Huong Tower'));
    expect(content, contains('Sunrise by the sea'));
    expect(content, contains('First light along Tran Phu.'));
    expect(content, contains('CACHED 27°C • CLEAR'));
    expect(content, contains('SEP'));
    expect(photo.assetPath, startsWith('fixture://'));
    expect(route.routePoints, hasLength(storyRunFixture.track.length));
    expect(
      route.routePoints.every(
        (point) => point.x >= 0 && point.x <= 1 && point.y >= 0 && point.y <= 1,
      ),
      isTrue,
    );
  });

  test('omits calories and weather when optional data is unavailable', () {
    final summary = RunSummary(
      id: 'minimal-run',
      startedAtUtc: DateTime.utc(2026, 9, 1, 10),
      activeDuration: const Duration(minutes: 12),
      distanceMeters: 0,
      locationName: 'Ho Chi Minh City, Vietnam',
      track: const [],
      landmarks: const [],
      quests: const [],
      evidence: const [],
    );
    final document = populator.fromRun(
      template: storyTemplates.last,
      summary: summary,
      documentId: 'minimal-story',
    );
    final content =
        document.elements.map((element) => element.content).join('\n');

    expect(content, isNot(contains('CALORIES')));
    expect(content, isNot(contains('CACHED')));
    expect(content, contains('PACE —'));
    expect(content, contains('HO CHI MINH CITY, VIETNAM'));
  });
}
