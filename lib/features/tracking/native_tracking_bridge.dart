import 'package:flutter/services.dart';
import 'domain/models/location_point.dart';

class NativeTrackingBridge {
  static const MethodChannel _commandChannel = MethodChannel('com.questory.tracking/command');
  static const EventChannel _eventChannel = EventChannel('com.questory.tracking/event');

  /// 1. Gửi lệnh bật Foreground Service xuống Native Android
  Future<void> startNativeTracking() async {
    try {
      await _commandChannel.invokeMethod('startService');
    } on PlatformException catch (e) {
      print("Không thể khởi động Native Service: ${e.message}");
    }
  }

  /// 2. Gửi lệnh tắt Foreground Service
  Future<void> stopNativeTracking() async {
    try {
      await _commandChannel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      print("Không thể dừng Native Service: ${e.message}");
    }
  }

  /// 3. Lắng nghe luồng dữ liệu tọa độ liên tục từ Native Android đẩy lên
  Stream<Map<String, dynamic>> get locationStream {
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(event);
      return {
        'lat': data['lat'] as double,
        'lng': data['lng'] as double,
        'distance': data['distance'] as double,
      };
    });
  }
}