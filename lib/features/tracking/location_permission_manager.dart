import 'package:geolocator/geolocator.dart';

// Định nghĩa các kết quả trả về khi xin quyền để UI dễ xử lý
enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
  locationServiceDisabled
}

class LocationPermissionManager {
  /// Hàm này kiểm tra và xin quyền
  Future<PermissionResult> checkAndRequestPermission({
    required Function onRequireExplanation,
  }) async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Kiểm tra xem GPS trên máy có bị tắt cứng không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return PermissionResult.locationServiceDisabled;
    }

    // 2. Kiểm tra trạng thái quyền hiện tại
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // IN-CONTEXT EXPLANATION: Gọi callback để UI hiển thị Dialog giải thích TRƯỚC KHI xin quyền
      bool userAgreedToProceed = await onRequireExplanation();

      if (!userAgreedToProceed) {
        return PermissionResult.denied;
      }

      // Xin quyền từ hệ thống Android
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return PermissionResult.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Người dùng đã chọn "Don't ask again"
      return PermissionResult.permanentlyDenied;
    }

    // Quyền đã được cấp (Always hoặc While in use)
    return PermissionResult.granted;
  }

  /// Mở cài đặt máy để người dùng tự bật quyền nếu đã bị denied forever
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}