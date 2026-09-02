import '../../../core/domain/run_models.dart';
import '../../destinations/application/quest_location_checker.dart';

abstract final class RunCalculations {
  static const maximumPlausibleSpeedMetersPerSecond = 12.0;
  static const maximumAcceptedAccuracyMeters = 100.0;

  static bool accepts(GeoPoint? previous, GeoPoint next) {
    if (next.latitude < -90 ||
        next.latitude > 90 ||
        next.longitude < -180 ||
        next.longitude > 180) {
      return false;
    }
    final accuracy = next.accuracyMeters;
    if (accuracy != null && accuracy > maximumAcceptedAccuracyMeters) {
      return false;
    }
    if (previous == null) return true;
    final elapsedSeconds =
        next.timestampUtc.difference(previous.timestampUtc).inMilliseconds /
            1000;
    if (elapsedSeconds <= 0) return false;
    final distance = QuestLocationChecker.distanceBetween(previous, next);
    return distance / elapsedSeconds <= maximumPlausibleSpeedMetersPerSecond;
  }

  static double distanceMeters(List<GeoPoint> track) {
    var total = 0.0;
    for (var index = 1; index < track.length; index++) {
      total += QuestLocationChecker.distanceBetween(
        track[index - 1],
        track[index],
      );
    }
    return total;
  }

  static double? paceSecondsPerKilometer({
    required double distanceMeters,
    required Duration activeDuration,
  }) {
    if (distanceMeters <= 0 || activeDuration <= Duration.zero) return null;
    return activeDuration.inMilliseconds / 1000 / (distanceMeters / 1000);
  }
}
