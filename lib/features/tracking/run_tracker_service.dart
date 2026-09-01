import 'dart:async';
import 'package:geolocator/geolocator.dart';
// Thay đường dẫn này cho đúng với cấu trúc của bạn
import 'models/location_point.dart';
import 'package:flutter/foundation.dart';

class RunTrackerService {
  final List<LocationPoint> _routePoints = [];
  StreamSubscription<Position>? _positionStream;

  double _totalDistanceMeters = 0.0;
  DateTime? _startTime;

  // Giới hạn vận tốc 11 m/s để lọc nhiễu
  final double _maxValidSpeed = 11.0;

  /// Bắt đầu lắng nghe GPS
  void startTracking({
      required Function(double distance, Duration duration, double pace) onMetricsUpdated,
      required Function(String error) onError, // Thêm callback xử lý lỗi (Task 13)
    }) {
      _startTime = DateTime.now();

      LocationSettings locationSettings;

      // Phân tách cấu hình riêng cho Android để bật Foreground Service
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
          forceLocationManager: true,
          // Khởi tạo Foreground Service kèm Notification
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: "Questory is tracking your route offline.",
            notificationTitle: "Active Run",
            enableWakeLock: true, // Quan trọng: Giữ CPU hoạt động khi tắt màn hình
            setOngoing: true,     // Người dùng không thể gạt bỏ thông báo này
          ),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        );
      }

      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen(
        (Position position) {
          _processNewPosition(position, onMetricsUpdated);
        },
        // XỬ LÝ TASK 13: Mất GPS tạm thời không được crash app
        onError: (error) {
          // Lỗi thường gặp: LocationServiceDisabledException (vào hầm mất sóng)
          // Thay vì crash hoặc tự động kết thúc (finish), ta chỉ báo lỗi và chờ tín hiệu lại
          print("Cảnh báo tín hiệu GPS: $error");
          onError("Tín hiệu GPS yếu hoặc mất kết nối. Đang tìm lại...");
        },
        cancelOnError: false, // Quan trọng: Không hủy stream khi gặp lỗi tạm thời
      );
    }

  /// Xử lý điểm mới, tính toán và đẩy dữ liệu ra ngoài
  void _processNewPosition(Position position, Function(double, Duration, double) onMetricsUpdated) {
    final newPoint = LocationPoint(position.latitude, position.longitude, position.timestamp);

    if (_routePoints.isNotEmpty) {
      final lastPoint = _routePoints.last;

      // Hàm có sẵn của Geolocator tính khoảng cách cực chuẩn (Haversine formula)
      final double distance = Geolocator.distanceBetween(
        lastPoint.latitude, lastPoint.longitude,
        newPoint.latitude, newPoint.longitude,
      );

      final int timeDiffSeconds = newPoint.timestamp.difference(lastPoint.timestamp).inSeconds;

      // Task 5: Lọc nhiễu GPS (Invalid jumps)
      if (timeDiffSeconds > 0) {
        final double speed = distance / timeDiffSeconds;
        if (speed > _maxValidSpeed) {
          return; // Bỏ qua điểm này, không cộng dồn
        }
      }
      _totalDistanceMeters += distance;
    }

    _routePoints.add(newPoint);

    // Task 6: Tính toán các chỉ số
    final currentDuration = DateTime.now().difference(_startTime!);
    final currentPace = _calculatePace(_totalDistanceMeters, currentDuration);

    // Gọi callback để UI (hoặc State) cập nhật
    onMetricsUpdated(_totalDistanceMeters, currentDuration, currentPace);
  }

  /// Tính Pace: Phút / Km
  double _calculatePace(double distanceMeters, Duration duration) {
    if (distanceMeters == 0) return 0.0;
    final double distanceKm = distanceMeters / 1000.0;
    final double minutes = duration.inSeconds / 60.0;
    return minutes / distanceKm;
  }

  void stopTracking() {
    _positionStream?.cancel();
  }

  List<LocationPoint> get routePoints => List.unmodifiable(_routePoints);

  List<String> checkNearbyQuests(Position currentPosition, List<Map<String, dynamic>> activeQuests) {
      List<String> nearbyQuestIds = [];

      for (var quest in activeQuests) {
        double questLat = quest['lat'];
        double questLng = quest['lng'];
        double radius = quest['radius']; // Bán kính yêu cầu (ví dụ: 50 mét)

        double distanceToQuest = Geolocator.distanceBetween(
          currentPosition.latitude, currentPosition.longitude,
          questLat, questLng,
        );

        if (distanceToQuest <= radius) {
          nearbyQuestIds.add(quest['id']);
        }
      }

      return nearbyQuestIds;
    }

    void pauseTracking() {
      _positionStream?.pause();
    }

    void resumeTracking() {
      _positionStream?.resume();
    }
}