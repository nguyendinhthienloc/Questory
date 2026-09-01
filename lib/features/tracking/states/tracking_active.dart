part of 'run_tracking_state.dart';

class TrackingActive extends RunTrackingState {
  final Duration activeDuration;
  final double totalDistanceMeters;
  final double averagePace;
  final List<LocationPoint> routePoints;

  const TrackingActive({
    required this.activeDuration,
    required this.totalDistanceMeters,
    required this.averagePace,
    required this.routePoints,
  });
}