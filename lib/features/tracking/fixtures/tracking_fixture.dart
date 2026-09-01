import '../models/location_point.dart';

class TrackingFixture {
  /// Sinh ra một danh sách tọa độ giả lập (Ví dụ: Chạy quanh một công viên)
  /// Khoảng cách giữa các điểm hợp lý để không bị thuật toán lọc nhiễu loại bỏ
  static List<LocationPoint> getMockRoute() {
    final baseTime = DateTime.now().subtract(const Duration(minutes: 30));

    return [
      LocationPoint(10.762622, 106.681045, baseTime),
      LocationPoint(10.762730, 106.681250, baseTime.add(const Duration(seconds: 10))),
      LocationPoint(10.762880, 106.681500, baseTime.add(const Duration(seconds: 22))),
      LocationPoint(10.763100, 106.681700, baseTime.add(const Duration(seconds: 35))),
      LocationPoint(10.763350, 106.681850, baseTime.add(const Duration(seconds: 50))),
      LocationPoint(10.763500, 106.681600, baseTime.add(const Duration(seconds: 65))),
      LocationPoint(10.763400, 106.681300, baseTime.add(const Duration(seconds: 80))),
      LocationPoint(10.763150, 106.681000, baseTime.add(const Duration(seconds: 95))),
      LocationPoint(10.762850, 106.680850, baseTime.add(const Duration(seconds: 110))),
      LocationPoint(10.762622, 106.681045, baseTime.add(const Duration(seconds: 125))), // Vòng về đích
    ];
  }
}