import 'package:flutter_test/flutter_test.dart';
import 'package:questory/core/domain/run_models.dart';
import 'package:questory/features/tracking/application/run_calculations.dart';

void main() {
  test('calculates distance, pace, and rejects an impossible GPS jump', () {
    final track = [
      GeoPoint(
        latitude: 10.0,
        longitude: 106.0,
        accuracyMeters: 5,
        timestampUtc: DateTime.utc(2026, 9, 2, 8),
      ),
      GeoPoint(
        latitude: 10.001,
        longitude: 106.0,
        accuracyMeters: 5,
        timestampUtc: DateTime.utc(2026, 9, 2, 8, 1),
      ),
    ];

    expect(RunCalculations.accepts(track.first, track.last), isTrue);
    final distance = RunCalculations.distanceMeters(track);
    expect(distance, closeTo(111.2, 1));
    expect(
      RunCalculations.paceSecondsPerKilometer(
        distanceMeters: 1000,
        activeDuration: const Duration(minutes: 6),
      ),
      360,
    );

    final jump = GeoPoint(
      latitude: 11,
      longitude: 107,
      accuracyMeters: 5,
      timestampUtc: DateTime.utc(2026, 9, 2, 8, 1, 5),
    );
    expect(RunCalculations.accepts(track.last, jump), isFalse);
  });

  test('returns no pace for zero distance', () {
    expect(
      RunCalculations.paceSecondsPerKilometer(
        distanceMeters: 0,
        activeDuration: const Duration(minutes: 10),
      ),
      isNull,
    );
  });
}
