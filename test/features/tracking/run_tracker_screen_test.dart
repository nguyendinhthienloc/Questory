import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/contracts/location_tracker.dart';
import 'package:questory/core/domain/destination_models.dart';
import 'package:questory/core/domain/run_session.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/core/fixtures/fake_run_dependencies.dart';
import 'package:questory/features/tracking/presentation/run_tracker_screen.dart';

void main() {
  testWidgets('explains location and shows denied-permission recovery', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: RunTrackerScreen(
          pack: _pack(),
          route: _pack().routes.first,
          repository: FakeRunRepository(),
          locationTracker: FakeLocationTracker(
            permission: LocationPermissionStatus.denied,
          ),
          photoStore: FakePhotoStore(),
          clock: FakeClock(DateTime.utc(2026)),
          onFinished: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('begin-tracking')));
    await tester.pumpAndSettle();
    expect(find.text('Record this run?'), findsOneWidget);
    expect(find.textContaining('precise location'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('NEEDS ATTENTION'), findsOneWidget);
    expect(find.textContaining('permission was denied'), findsOneWidget);
  });

  testWidgets('starts, pauses, resumes, and finishes from tracker controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    RunSummary? finished;
    final repository = FakeRunRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: RunTrackerScreen(
          pack: _pack(),
          route: _pack().routes.first,
          repository: repository,
          locationTracker: FakeLocationTracker(),
          photoStore: FakePhotoStore(),
          clock: FakeClock(DateTime.utc(2026)),
          onFinished: (summary) => finished = summary,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('begin-tracking')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('pause-run')), findsOneWidget);
    final captureButton = find.widgetWithText(FilledButton, 'CAPTURE');
    expect(captureButton, findsOneWidget);
    expect(tester.widget<FilledButton>(captureButton).onPressed, isNotNull);
    tester.widget<FilledButton>(captureButton).onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Use GPS fallback?'), findsOneWidget);
    expect(find.textContaining('physically at the quest location'),
        findsOneWidget);
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    final pauseButton = find.byKey(const ValueKey('pause-run'));
    await tester.runAsync(() async {
      tester.widget<OutlinedButton>(pauseButton).onPressed!();
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(repository.active?.lifecycle, RunLifecycle.paused);
    expect(find.byKey(const ValueKey('resume-run')), findsOneWidget);

    final resumeButton = find.byKey(const ValueKey('resume-run'));
    await tester.runAsync(() async {
      tester.widget<OutlinedButton>(resumeButton).onPressed!();
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('pause-run')), findsOneWidget);

    final finishButton = find.byKey(const ValueKey('finish-run'));
    tester.widget<FilledButton>(finishButton).onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('FINISH'),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(finished, isNotNull);
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pump();
    expect(find.text('COMPLETED'), findsOneWidget);
  });
}

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
        questIds: const ['manual-quest'],
        safetyNotes: const ['Test current conditions.'],
      ),
    ],
    quests: [
      Quest(
        id: 'manual-quest',
        title: 'Manual quest',
        prompt: 'Capture a public detail.',
        point: point,
        radiusMeters: 60,
        captionRequired: true,
        fallback: const QuestFallback(
          type: QuestFallbackType.manualConfirmation,
          instructions: 'Confirm that you are at the public landmark.',
        ),
      ),
    ],
    pointsOfInterest: [
      PointOfInterest(
        id: 'test-poi',
        name: 'Test point',
        description: 'A bundled test point.',
        point: point,
        questIds: const ['manual-quest'],
      ),
    ],
  );
}
