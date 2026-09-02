import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/core/fixtures/fake_story_services.dart';
import 'package:questory/features/tracking/presentation/run_summary_screen.dart';

void main() {
  testWidgets('uses a safe placeholder when retained media is missing', (
    tester,
  ) async {
    final summary = RunSummary(
      id: 'run-missing-photo',
      startedAtUtc: DateTime.utc(2026, 9, 2),
      activeDuration: const Duration(minutes: 12),
      distanceMeters: 1250,
      locationName: 'Nha Trang, Vietnam',
      track: const [],
      landmarks: const [],
      quests: const [],
      evidence: [
        QuestEvidence(
          id: 'missing',
          questId: 'quest',
          photoPath: 'Z:/definitely-missing/questory-photo.jpg',
          point: GeoPoint(
            latitude: 12.23,
            longitude: 109.19,
            timestampUtc: DateTime.utc(2026, 9, 2),
          ),
          capturedAtUtc: DateTime.utc(2026, 9, 2),
          caption: 'The caption remains available.',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          summary: summary,
          storyRepository: FakeStoryRepository(),
          shareService: FakeShareService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.errorBuilder, isNotNull);
    expect(find.text('The caption remains available.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
