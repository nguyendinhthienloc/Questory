part of 'run_tracking_state.dart';

class TrackingPaused extends RunTrackingState {
  final Duration activeDuration;
  final double totalDistanceMeters;
  final double averagePace;
  final List<LocationPoint> routePoints;

  const TrackingPaused({
    required this.activeDuration,
    required this.totalDistanceMeters,
    required this.averagePace,
    required this.routePoints,
  });
}