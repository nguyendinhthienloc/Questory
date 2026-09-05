import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/app/app_dependencies.dart';
import 'package:questory/app/main_navigation.dart';
import 'package:questory/core/domain/destination_models.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/core/domain/run_session.dart';
import 'package:questory/core/fixtures/fake_destination_repository.dart';
import 'package:questory/core/fixtures/fake_run_dependencies.dart';
import 'package:questory/core/fixtures/fake_story_services.dart';
import 'package:questory/features/tracking/presentation/run_tracker_screen.dart';

void main() {
  testWidgets('offers and discards a saved run checkpoint', (tester) async {
    final repository = FakeRunRepository()..active = _session();
    await _pumpNavigation(tester, repository);

    expect(find.text('Paused run found'), findsOneWidget);
    await tester.tap(find.text('DISCARD'));
    await tester.pumpAndSettle();
    expect(repository.active, isNull);
  });

  testWidgets('resumes a saved run checkpoint', (tester) async {
    final repository = FakeRunRepository()..active = _session();
    await _pumpNavigation(tester, repository);

    await tester.tap(find.text('RESUME'));
    await tester.pumpAndSettle();
    expect(find.byType(RunTrackerScreen), findsOneWidget);
  });

  testWidgets('reports recovery storage errors without crashing', (
    tester,
  ) async {
    await _pumpNavigation(tester, _FailingRecoveryRepository());

    expect(find.textContaining('Saved-run recovery is unavailable'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens Tracks lazily between Explore and Journey', (
    tester,
  ) async {
    var tracksBuilds = 0;
    await _pumpNavigation(
      tester,
      FakeRunRepository(),
      tracksScreenBuilder: (_) {
        tracksBuilds++;
        return const ColoredBox(
          key: ValueKey('tracks-screen'),
          color: Colors.black,
        );
      },
    );

    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Tracks'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(tracksBuilds, 0);

    await tester.tap(find.byKey(const ValueKey('nav-tracks')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tracks-screen')), findsOneWidget);
    expect(tracksBuilds, 1);
  });
}

Future<void> _pumpNavigation(
  WidgetTester tester,
  FakeRunRepository runs, {
  WidgetBuilder? tracksScreenBuilder,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MainNavigation(
        tracksScreenBuilder: tracksScreenBuilder,
        dependencies: AppDependencies(
          destinations: FakeDestinationRepository(seed: [_pack()]),
          runs: runs,
          stories: FakeStoryRepository(),
          achievements: FakeAchievementRepository(),
          locationTracker: FakeLocationTracker(),
          photoStore: FakePhotoStore(),
          clock: FakeClock(DateTime.utc(2026, 9, 2, 1)),
          shareService: FakeShareService(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

RunSession _session() => RunSession(
      id: 'active-run',
      cityId: 'test-city',
      locationName: 'Test City, Vietnam',
      routeId: 'route',
      startedAtUtc: DateTime.utc(2026, 9, 2),
      updatedAtUtc: DateTime.utc(2026, 9, 2, 0, 10),
      lifecycle: RunLifecycle.paused,
      accumulatedActiveDuration: const Duration(minutes: 10),
      track: const [],
      evidence: const [],
      completedQuestIds: const {},
      skippedQuestIds: const {},
    );

DestinationPack _pack() {
  final point = GeoPoint(
    latitude: 10,
    longitude: 106,
    timestampUtc: DateTime.utc(2026),
  );
  return DestinationPack(
    schemaVersion: 1,
    packVersion: '1.0.0',
    id: 'test-city',
    cityName: 'Test City',
    countryCode: 'VN',
    description: 'Test city.',
    lastReviewedAtUtc: DateTime.utc(2026),
    routes: [
      RoutePlan(
        id: 'route',
        name: 'Test Route',
        description: 'A deterministic route.',
        distanceMeters: 1000,
        estimatedDuration: const Duration(minutes: 10),
        difficulty: 'Easy',
        expectedPolyline: [point, point],
        landmarks: const [],
        questIds: const [],
        safetyNotes: const ['Test current conditions.'],
      ),
    ],
    quests: const [],
    pointsOfInterest: const [],
  );
}

class _FailingRecoveryRepository extends FakeRunRepository {
  @override
  Future<RunSession?> loadActive() =>
      Future<RunSession?>.error(StateError('database unavailable'));
}
