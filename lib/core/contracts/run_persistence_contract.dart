import '../../features/tracking/states/run_tracking_state.dart';

abstract class RunPersistenceContract {
  /// Lưu trạng thái hiện tại (gọi liên tục khi đang chạy hoặc khi bấm Pause)
  Future<void> saveCheckpoint(RunTrackingState state);

  /// Tải lại trạng thái dang dở khi người dùng mở lại app sau khi crash
  Future<RunTrackingState?> loadCheckpoint();

  /// Xóa checkpoint sau khi bấm Finish hoặc Discard
  Future<void> clearCheckpoint();
}