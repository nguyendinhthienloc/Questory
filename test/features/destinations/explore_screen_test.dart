import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/domain/destination_models.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/features/destinations/presentation/explore_screen.dart';
import 'package:questory/core/fixtures/fake_destination_repository.dart';
import 'package:questory/main.dart';

void main() {
  testWidgets('Questory starts on Explore Vietnam', (tester) async {
    await tester.pumpWidget(const QuestoryApp());
    await tester.pumpAndSettle();

    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.text('Explore Vietnam'), findsOneWidget);
  });

  testWidgets('shows both launch cities on a small screen', (tester) async {
    final repository = FakeDestinationRepository(seed: _packs());
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: ExploreScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Explore Vietnam'), findsOneWidget);
    expect(find.text('Nha Trang'), findsOneWidget);
    expect(find.text('Ho Chi Minh City'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens a city and its bundled route details', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeDestinationRepository(seed: _packs());
    await tester.pumpWidget(
      MaterialApp(home: ExploreScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('destination-nha-trang')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coastal Morning Run'), findsOneWidget);
    expect(find.text('START FREE RUN'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('route-nha-trang-coastal-morning')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Route Details'), findsOneWidget);
    expect(find.text('START THIS ROUTE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('quest-nt-tower-frame')),
      300,
    );
    expect(find.text('Frame the Tower'), findsOneWidget);
  });
}

List<DestinationPack> _packs() => [
      _pack(
        id: 'nha-trang',
        city: 'Nha Trang',
        routeId: 'nha-trang-coastal-morning',
        routeName: 'Coastal Morning Run',
        questId: 'nt-tower-frame',
        questTitle: 'Frame the Tower',
      ),
      _pack(
        id: 'ho-chi-minh-city',
        city: 'Ho Chi Minh City',
        routeId: 'hcmc-river-city-lights',
        routeName: 'River and City Lights',
        questId: 'hcmc-old-new',
        questTitle: 'Old and New',
      ),
    ];

DestinationPack _pack({
  required String id,
  required String city,
  required String routeId,
  required String routeName,
  required String questId,
  required String questTitle,
}) {
  final point = GeoPoint(
    latitude: 10.0,
    longitude: 106.0,
    timestampUtc: DateTime.utc(2026),
  );
  final quest = Quest(
    id: questId,
    title: questTitle,
    prompt: 'Capture a city detail.',
    point: point,
    radiusMeters: 60,
    captionRequired: true,
    fallback: const QuestFallback(
      type: QuestFallbackType.manualConfirmation,
      instructions: 'Confirm that you are at the landmark.',
    ),
  );
  return DestinationPack(
    schemaVersion: 1,
    packVersion: '1.0.0',
    id: id,
    cityName: city,
    countryCode: 'VN',
    description: 'An offline city pack.',
    lastReviewedAtUtc: DateTime.utc(2026),
    routes: [
      RoutePlan(
        id: routeId,
        name: routeName,
        description: 'A public city route.',
        distanceMeters: 3000,
        estimatedDuration: const Duration(minutes: 30),
        difficulty: 'Easy',
        expectedPolyline: [point],
        landmarks: [
          Landmark(
            id: 'landmark-$id',
            name: 'City landmark',
            description: 'A public landmark.',
            point: point,
          ),
        ],
        questIds: [questId],
        safetyNotes: const ['Check current pedestrian conditions.'],
      ),
    ],
    quests: [quest],
    pointsOfInterest: [
      PointOfInterest(
        id: 'poi-$id',
        name: 'City point',
        description: 'A bundled discovery point.',
        point: point,
        questIds: [questId],
      ),
    ],
  );
}
