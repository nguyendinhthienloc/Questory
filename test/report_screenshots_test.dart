import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/app/app_dependencies.dart';
import 'package:questory/core/domain/achievement.dart';
import 'package:questory/core/domain/destination_models.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/core/fixtures/fake_run_dependencies.dart';
import 'package:questory/core/fixtures/fake_story_services.dart';
import 'package:questory/data/local/bundled_destination_repository.dart';
import 'package:questory/features/history/presentation/history_screen.dart';
import 'package:questory/features/story_studio/data/story_templates.dart';
import 'package:questory/features/story_studio/presentation/story_studio_screen.dart';
import 'package:questory/features/tracking/presentation/run_tracker_screen.dart';
import 'package:questory/main.dart';

const _captureKey = ValueKey('report-screenshot-boundary');

void main() {
  setUpAll(() async {
    final notoSans = FontLoader('Noto Sans')
      ..addFont(rootBundle.load('assets/story/fonts/NotoSans-Variable.ttf'));
    final spaceGrotesk = FontLoader('Space Grotesk')
      ..addFont(
          rootBundle.load('assets/story/fonts/SpaceGrotesk-Variable.ttf'));
    final flutterRoot =
        Platform.environment['FLUTTER_ROOT'] ?? 'C:/dev/flutter';
    final iconBytes = await File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(iconBytes)));
    await Future.wait([
      notoSans.load(),
      spaceGrotesk.load(),
      materialIcons.load(),
    ]);
  });

  testWidgets('captures Explore and route details for the report',
      (tester) async {
    await _configureSurface(tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: QuestoryApp(dependencies: _dependencies()),
      ),
    );
    await tester.pump();
    final context = tester.element(find.byType(Scaffold).first);
    await tester.runAsync(
      () => Future.wait([
        precacheImage(
          const AssetImage(
            'assets/destinations/artwork/nha_trang_coast.png',
          ),
          context,
        ),
        precacheImage(
          const AssetImage(
            'assets/destinations/artwork/ho_chi_minh_city.png',
          ),
          context,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_captureKey),
      matchesGoldenFile('../report/images/explore.png'),
    );

    await tester.tap(find.byKey(const ValueKey('destination-nha-trang')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('route-nha-trang-coastal-morning')),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_captureKey),
      matchesGoldenFile('../report/images/route-details.png'),
    );
  });

  testWidgets('captures an active tracker for the report', (tester) async {
    await _configureSurface(tester);
    final pack = _pack();
    final locations = FakeLocationTracker();
    final clock = FakeClock(DateTime.utc(2026, 9, 4, 6, 30));
    addTearDown(locations.close);

    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: QuestoryApp(
          home: RunTrackerScreen(
            pack: pack,
            route: pack.routes.first,
            repository: FakeRunRepository(),
            locationTracker: locations,
            photoStore: FakePhotoStore(),
            clock: clock,
            onFinished: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('begin-tracking')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    locations.emit(_point(12.2388, 109.1967, clock.nowUtc()));
    await tester.pump(const Duration(milliseconds: 50));
    clock.advance(const Duration(minutes: 8));
    locations.emit(_point(12.2430, 109.1979, clock.nowUtc()));
    await tester.pump(const Duration(milliseconds: 50));

    await expectLater(
      find.byKey(_captureKey),
      matchesGoldenFile('../report/images/tracker.png'),
    );
  });

  testWidgets('captures populated Journey for the report', (tester) async {
    await _configureSurface(tester);
    final summary = _summary();
    final runs = FakeRunRepository()..summaries[summary.id] = summary;
    final stories = FakeStoryRepository(
      seed: [
        storyTemplates.first.createDocument(
          documentId: 'story-${summary.id}-city-sprint',
          sourceRunId: summary.id,
        ),
      ],
    );
    final achievements = FakeAchievementRepository()
      ..achievements = [
        Achievement(
          id: 'first-run',
          title: 'First Chapter',
          description: 'Complete your first Questory run.',
          progress: 1,
          target: 1,
          unlockedAtUtc: DateTime.utc(2026, 9, 4),
        ),
      ];

    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: QuestoryApp(
          home: HistoryScreen(
            dependencies: _dependencies(
              runs: runs,
              stories: stories,
              achievements: achievements,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_captureKey),
      matchesGoldenFile('../report/images/history.png'),
    );
  });

  testWidgets('captures Story Studio for the report', (tester) async {
    await _configureSurface(tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _captureKey,
        child: QuestoryApp(
          home: StoryStudioScreen(
            runSummary: _summary(),
            repository: FakeStoryRepository(),
            renderer: FakeStoryRenderer(),
            shareService: FakeShareService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_captureKey),
      matchesGoldenFile('../report/images/story-studio.png'),
    );
  });
}

Future<void> _configureSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(412, 915));
  tester.view.devicePixelRatio = 1;
  addTearDown(() async {
    tester.view.resetDevicePixelRatio();
    await tester.binding.setSurfaceSize(null);
  });
}

AppDependencies _dependencies({
  FakeRunRepository? runs,
  FakeStoryRepository? stories,
  FakeAchievementRepository? achievements,
}) =>
    AppDependencies(
      destinations: BundledDestinationRepository(),
      runs: runs ?? FakeRunRepository(),
      stories: stories ?? FakeStoryRepository(),
      achievements: achievements ?? FakeAchievementRepository(),
      locationTracker: FakeLocationTracker(),
      photoStore: FakePhotoStore(),
      clock: FakeClock(DateTime.utc(2026, 9, 4, 6, 30)),
      shareService: FakeShareService(),
    );

RunSummary _summary() => RunSummary(
      id: 'nha-trang-sunrise-run',
      startedAtUtc: DateTime.utc(2026, 9, 4, 23, 30),
      activeDuration: const Duration(minutes: 34, seconds: 12),
      distanceMeters: 5120,
      averagePaceSecondsPerKilometer: 400.8,
      locationName: 'Nha Trang, Vietnam',
      track: [
        _point(12.2388, 109.1967, DateTime.utc(2026, 9, 4, 23, 30)),
        _point(12.2430, 109.1979, DateTime.utc(2026, 9, 5, 0, 4)),
      ],
      landmarks: const ['Tran Phu Beach', 'Tram Huong Tower'],
      quests: const [
        RunQuestResult(
          questId: 'nt-tower-frame',
          title: 'Frame the Tower',
          completed: true,
          skipped: false,
        ),
      ],
      evidence: const [],
      estimatedCalories: 307,
    );

GeoPoint _point(double latitude, double longitude, DateTime time) => GeoPoint(
      latitude: latitude,
      longitude: longitude,
      timestampUtc: time,
      accuracyMeters: 7,
    );

DestinationPack _pack() {
  final start = _point(
    12.2388,
    109.1967,
    DateTime.utc(2026, 9, 4, 6, 30),
  );
  final quest = Quest(
    id: 'nt-tower-frame',
    title: 'Frame the Tower',
    prompt: 'Frame Tram Huong Tower against the morning sky.',
    point: GeoPoint(
      latitude: 12.2388,
      longitude: 109.1967,
      timestampUtc: DateTime.utc(2026, 9, 4, 6, 30),
    ),
    radiusMeters: 80,
    captionRequired: true,
    fallback: const QuestFallback(
      type: QuestFallbackType.manualConfirmation,
      instructions: 'Confirm that you are at Tram Huong Tower.',
    ),
  );
  return DestinationPack(
    schemaVersion: 1,
    packVersion: '1.0.0',
    id: 'nha-trang',
    cityName: 'Nha Trang',
    countryCode: 'VN',
    description: 'A coastal running and discovery pack.',
    lastReviewedAtUtc: DateTime.utc(2026, 9, 1),
    routes: [
      RoutePlan(
        id: 'nha-trang-coastal-morning',
        name: 'Coastal Morning Run',
        description: 'A sunrise route along Tran Phu Beach.',
        distanceMeters: 5200,
        estimatedDuration: const Duration(minutes: 35),
        difficulty: 'Easy',
        expectedPolyline: [start],
        landmarks: const [],
        questIds: [quest.id],
        safetyNotes: const ['Check current pedestrian conditions.'],
      ),
    ],
    quests: [quest],
    pointsOfInterest: const [],
  );
}
