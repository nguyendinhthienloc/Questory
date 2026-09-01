part of 'run_tracking_state.dart';

class TrackingCompleted extends RunTrackingState {
  final String runId; // Để truyền data sang màn Story Studio

  const TrackingCompleted(this.runId);
}