part of 'run_tracking_state.dart';

class TrackingFailed extends RunTrackingState {
  final String errorMessage;

  const TrackingFailed(this.errorMessage);
}