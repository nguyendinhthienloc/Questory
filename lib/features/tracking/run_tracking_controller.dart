import 'dart:async';
import 'states/run_tracking_state.dart';
import 'native_tracking_bridge.dart';
import 'location_permission_manager.dart';
import '../../core/contracts/run_persistence_contract.dart';
import 'models/location_point.dart';

class RunTrackingController {
  final NativeTrackingBridge _nativeBridge;
  final LocationPermissionManager _permissionManager;
  final RunPersistenceContract _persistence;

  RunTrackingState _state = const TrackingIdle();
  StreamSubscription<Map<String, dynamic>>? _locationSubscription;

  RunTrackingState get state => _state;

  RunTrackingController(
    this._nativeBridge,
    this._permissionManager,
    this._persistence,
  );

  /// 1. Bắt đầu chạy (Khởi động Foreground Service dưới Native)
  Future<void> startRun({required Future<bool> Function() onShowExplanation}) async {
    _updateState(const TrackingAcquiring());

    final permission = await _permissionManager.requestPermission(
      onShowExplanation: onShowExplanation,
    );

    if (permission == PermissionState.granted || permission == PermissionState.approximate) {
      // Gọi lệnh bật Native Foreground Service
      await _nativeBridge.startNativeTracking();

      // Lắng nghe luồng tọa độ real-time từ Native đẩy lên
      _locationSubscription = _nativeBridge.locationStream.listen((data) {
        if (_state is TrackingActive) {
          final lat = data['lat'] as double;
          final lng = data['lng'] as double;
          final distance = data['distance'] as double;

          final newPoint = LocationPoint(lat, lng, DateTime.now());
          final currentPoints = List<LocationPoint>.from((_state as TrackingActive).routePoints)..add(newPoint);

          final duration = DateTime.now().difference(_startTime);
          final pace = _calculatePace(distance, duration);

          _updateState(TrackingActive(
            activeDuration: duration,
            totalDistanceMeters: distance,
            averagePace: pace,
            routePoints: currentPoints,
          ));
        }
      });

      _startTime = DateTime.now();
      _updateState(TrackingActive(
        activeDuration: Duration.zero,
        totalDistanceMeters: 0.0,
        averagePace: 0.0,
        routePoints: [],
      ));
    } else {
      _updateState(const TrackingFailed('Không đủ quyền truy cập vị trí.'));
    }
  }

  late DateTime _startTime;

  double _calculatePace(double distanceMeters, Duration duration) {
    if (distanceMeters == 0) return 0.0;
    final double distanceKm = distanceMeters / 1000.0;
    final double minutes = duration.inSeconds / 60.0;
    return minutes / distanceKm;
  }

  /// 2. Tạm dừng
  void pauseRun() {
    if (_state is TrackingActive) {
      final currentState = _state as TrackingActive;
      _locationSubscription?.pause();

      _updateState(TrackingPaused(
        activeDuration: currentState.activeDuration,
        totalDistanceMeters: currentState.totalDistanceMeters,
        averagePace: currentState.averagePace,
        routePoints: currentState.routePoints,
      ));
    }
  }

  /// 3. Tiếp tục
  void resumeRun() {
    if (_state is TrackingPaused) {
      final currentState = _state as TrackingPaused;
      _locationSubscription?.resume();

      _updateState(TrackingActive(
        activeDuration: currentState.activeDuration,
        totalDistanceMeters: currentState.totalDistanceMeters,
        averagePace: currentState.averagePace,
        routePoints: currentState.routePoints,
      ));
    }
  }

  /// 4. Hoàn tất buổi chạy (Tắt Service Native)
  Future<void> finishRun() async {
    if (_state is TrackingFinishing || _state is TrackingCompleted) return;

    _updateState(const TrackingFinishing());

    _locationSubscription?.cancel();
    await _nativeBridge.stopNativeTracking();
    await _persistence.clearCheckpoint();

    _updateState(const TrackingCompleted("run_id_12345"));
  }

  /// 5. Hủy bỏ
  Future<void> discardRun() async {
    _locationSubscription?.cancel();
    await _nativeBridge.stopNativeTracking();
    await _persistence.clearCheckpoint();
    _updateState(const TrackingIdle());
  }

  void _updateState(RunTrackingState newState) {
    _state = newState;
    if (newState is TrackingActive || newState is TrackingPaused) {
      _persistence.saveCheckpoint(newState);
    }
  }
}