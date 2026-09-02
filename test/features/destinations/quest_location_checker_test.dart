import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/domain/destination_models.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/features/destinations/application/quest_location_checker.dart';

void main() {
  const checker = QuestLocationChecker();
  final quest = Quest(
    id: 'quest',
    title: 'Quest',
    prompt: 'Take a photo',
    point: GeoPoint(
      latitude: 12.2388,
      longitude: 109.1967,
      timestampUtc: DateTime.utc(2026),
    ),
    radiusMeters: 80,
    captionRequired: true,
    fallback: const QuestFallback(
      type: QuestFallbackType.manualConfirmation,
      instructions: 'Confirm manually.',
    ),
  );

  test('accepts an injected point inside the quest radius', () {
    final result = checker.evaluate(
      quest: quest,
      userPoint: GeoPoint(
        latitude: 12.2388,
        longitude: 109.1967,
        accuracyMeters: 8,
        timestampUtc: DateTime.utc(2026),
      ),
    );

    expect(result.status, QuestLocationStatus.nearby);
    expect(result.distanceMeters, closeTo(0, 0.1));
  });

  test('offers the documented fallback for inaccurate GPS', () {
    final result = checker.evaluate(
      quest: quest,
      userPoint: GeoPoint(
        latitude: 12.25,
        longitude: 109.2,
        accuracyMeters: 120,
        timestampUtc: DateTime.utc(2026),
      ),
    );

    expect(result.status, QuestLocationStatus.fallbackAvailable);
  });

  test('rejects a precise point outside the radius', () {
    final result = checker.evaluate(
      quest: quest,
      userPoint: GeoPoint(
        latitude: 12.25,
        longitude: 109.2,
        accuracyMeters: 5,
        timestampUtc: DateTime.utc(2026),
      ),
    );

    expect(result.status, QuestLocationStatus.tooFar);
  });
}
