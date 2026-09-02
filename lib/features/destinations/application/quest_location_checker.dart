import 'dart:math' as math;

import '../../../core/domain/destination_models.dart';
import '../../../core/domain/run_models.dart';

enum QuestLocationStatus {
  nearby,
  tooFar,
  inaccurateGps,
  fallbackAvailable,
}

class QuestLocationResult {
  const QuestLocationResult({
    required this.status,
    required this.distanceMeters,
  });

  final QuestLocationStatus status;
  final double distanceMeters;
}

class QuestLocationChecker {
  const QuestLocationChecker();

  QuestLocationResult evaluate({
    required Quest quest,
    required GeoPoint userPoint,
  }) {
    final distance = distanceBetween(userPoint, quest.point);
    final accuracy = userPoint.accuracyMeters;
    if (accuracy != null &&
        accuracy > quest.fallback.allowedWhenAccuracyExceedsMeters) {
      return QuestLocationResult(
        status: quest.fallback.type == QuestFallbackType.manualConfirmation
            ? QuestLocationStatus.fallbackAvailable
            : QuestLocationStatus.inaccurateGps,
        distanceMeters: distance,
      );
    }
    return QuestLocationResult(
      status: distance <= quest.radiusMeters
          ? QuestLocationStatus.nearby
          : QuestLocationStatus.tooFar,
      distanceMeters: distance,
    );
  }

  static double distanceBetween(GeoPoint first, GeoPoint second) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = _radians(first.latitude);
    final lat2 = _radians(second.latitude);
    final deltaLat = _radians(second.latitude - first.latitude);
    final deltaLon = _radians(second.longitude - first.longitude);
    final haversine = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    return earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
