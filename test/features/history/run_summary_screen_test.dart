import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/contracts/live_share_service.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/core/domain/shared_run.dart';
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

  testWidgets('requires explicit consent before uploading a route', (
    tester,
  ) async {
    final liveShare = _FakeLiveShareService();
    final summary = RunSummary(
      id: 'run-private',
      startedAtUtc: DateTime.utc(2026, 9, 5),
      activeDuration: const Duration(minutes: 10),
      distanceMeters: 1000,
      locationName: 'Nha Trang, Vietnam',
      track: const [],
      landmarks: const [],
      quests: const [],
      evidence: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          summary: summary,
          storyRepository: FakeStoryRepository(),
          shareService: FakeShareService(),
          liveShareService: liveShare,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('share-route-online')));
    await tester.pumpAndSettle();

    expect(find.text('Share this route online?'), findsOneWidget);
    expect(find.textContaining('route coordinates'), findsOneWidget);
    expect(liveShare.createCalls, 0);

    await tester.tap(find.byKey(const ValueKey('cancel-online-share')));
    await tester.pumpAndSettle();
    expect(liveShare.createCalls, 0);

    await tester.tap(find.byKey(const ValueKey('share-route-online')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-online-share')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(liveShare.createCalls, 1);
    expect(find.text('Share this route online?'), findsNothing);
  });
}

class _FakeLiveShareService implements LiveShareService {
  int createCalls = 0;

  @override
  Future<ShareLink> createShare(
    RunSummary summary, {
    Duration expiresIn = const Duration(hours: 24),
  }) async {
    createCalls += 1;
    return ShareLink(
      shareId: 'share-id',
      token: 'share-token',
      expiresAtUtc: DateTime.utc(2026, 9, 6),
      shareUrl: 'https://example.test/shared/share-id',
    );
  }

  @override
  Future<SharedRunPreview> loadSharedRun({
    required String shareId,
    required String token,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> revokeShare({
    required String shareId,
    required String token,
  }) async {}

  @override
  Future<void> uploadEvidence({
    required ShareLink share,
    required QuestEvidence evidence,
  }) async {}
}
