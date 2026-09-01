import '../../core/contracts/run_persistence_contract.dart';
import 'states/run_tracking_state.dart';

class FakeRunPersistence implements RunPersistenceContract {
  RunTrackingState? _savedState;

  @override
  Future<void> saveCheckpoint(RunTrackingState state) async {
    // Giả lập thời gian ghi vào ổ cứng
    await Future.delayed(const Duration(milliseconds: 100));
    _savedState = state;
    print("Checkpoint saved: ${state.runtimeType}");
  }

  @override
  Future<RunTrackingState?> loadCheckpoint() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _savedState;
  }

  @override
  Future<void> clearCheckpoint() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _savedState = null;
    print("Checkpoint cleared");
  }
}