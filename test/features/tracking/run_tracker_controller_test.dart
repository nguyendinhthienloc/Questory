import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/contracts/location_tracker.dart';
import 'package:questory/core/domain/destination_models.dart';
import 'package:questory/core/domain/run_session.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/core/fixtures/fake_run_dependencies.dart';
import 'package:questory/features/tracking/application/run_tracker_controller.dart';

void main() {
  test('tracks active time, excludes pauses, checkpoints, and finishes',
      () async {
    final started = DateTime.utc(2026, 9, 2, 1);
    final clock = FakeClock(started);
    final locations = FakeLocationTracker();
    final repository = FakeRunRepository();
    final controller = RunTrackerController(
      pack: _pack(),
      route: _pack().routes.first,
      repository: repository,
      locationTracker: locations,
      clock: clock,
    );

    await controller.start();
    locations.emit(_point(10, 106, started));
    await Future<void>.delayed(Duration.zero);
    clock.advance(const Duration(minutes: 1));
    locations.emit(_point(10.001, 106, clock.nowUtc()));
    await Future<void>.delayed(Duration.zero);
    await controller.pause();

    expect(controller.activeDuration, const Duration(minutes: 1));
    expect(repository.active, isNotNull);
    clock.advance(const Duration(minutes: 5));
    expect(controller.activeDuration, const Duration(minutes: 1));

    await controller.resume();
    clock.advance(const Duration(minutes: 1));
    locations.emit(_point(10.002, 106, clock.nowUtc()));
    await Future<void>.delayed(Duration.zero);
    final summary = await controller.finish();

    expect(summary, isNotNull);
    expect(summary!.activeDuration, const Duration(minutes: 2));
    expect(summary.distanceMeters, greaterThan(200));
    expect(repository.active, isNull);
    expect(await repository.getSummary(summary.id), same(summary));

    controller.dispose();
    await locations.close();
  });

  test('permission denial produces a failed state without tracking', () async {
    final controller = RunTrackerController(
      pack: _pack(),
      route: null,
      repository: FakeRunRepository(),
      locationTracker: FakeLocationTracker(
        permission: LocationPermissionStatus.denied,
      ),
      clock: FakeClock(DateTime.utc(2026)),
    );

    await controller.start();

    expect(controller.lifecycle, RunLifecycle.failed);
    expect(controller.session!.errorMessage, contains('denied'));
    expect(controller.track, isEmpty);
    controller.dispose();
  });

  test('restores an active checkpoint as paused without counting downtime',
      () async {
    final started = DateTime.utc(2026, 9, 2, 1);
    final checkpoint = RunSession(
      id: 'saved',
      cityId: 'test-city',
      locationName: 'Test City, Vietnam',
      routeId: 'test-route',
      startedAtUtc: started,
      updatedAtUtc: started.add(const Duration(minutes: 3)),
      lifecycle: RunLifecycle.active,
      activeSegmentStartedAtUtc: started,
      accumulatedActiveDuration: Duration.zero,
      track: const [],
      evidence: const [],
      completedQuestIds: const {},
      skippedQuestIds: const {},
    );
    final repository = FakeRunRepository();
    final controller = RunTrackerController(
      pack: _pack(),
      route: _pack().routes.first,
      repository: repository,
      locationTracker: FakeLocationTracker(),
      clock: FakeClock(started.add(const Duration(hours: 1))),
    );

    await controller.restore(checkpoint);

    expect(controller.lifecycle, RunLifecycle.paused);
    expect(controller.activeDuration, const Duration(minutes: 3));
    expect(repository.active!.lifecycle, RunLifecycle.paused);
    controller.dispose();
  });
}

GeoPoint _point(double latitude, double longitude, DateTime time) => GeoPoint(
      latitude: latitude,
      longitude: longitude,
      timestampUtc: time,
      accuracyMeters: 8,
    );

DestinationPack _pack() {
  final point = _point(10, 106, DateTime.utc(2026));
  final route = RoutePlan(
    id: 'test-route',
    name: 'Test Route',
    description: 'A deterministic route.',
    distanceMeters: 1000,
    estimatedDuration: const Duration(minutes: 10),
    difficulty: 'Easy',
    expectedPolyline: [point],
    landmarks: const [],
    questIds: const [],
    safetyNotes: const [],
  );
  return DestinationPack(
    schemaVersion: 1,
    packVersion: '1.0.0',
    id: 'test-city',
    cityName: 'Test City',
    countryCode: 'VN',
    description: 'Test city.',
    lastReviewedAtUtc: DateTime.utc(2026),
    routes: [route],
    quests: const [],
    pointsOfInterest: const [],
  );
}
