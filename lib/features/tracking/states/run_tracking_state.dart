import '../models/location_point.dart';

// Khai báo các file con thuộc về library này
part 'tracking_idle.dart';
part 'tracking_acquiring.dart';
part 'tracking_active.dart';
part 'tracking_paused.dart';
part 'tracking_finishing.dart';
part 'tracking_completed.dart';
part 'tracking_failed.dart';

sealed class RunTrackingState {
  const RunTrackingState();
}