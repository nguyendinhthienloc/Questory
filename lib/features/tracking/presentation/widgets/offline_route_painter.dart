import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/location_point.dart';

class OfflineRoutePainter extends CustomPainter {
  final List<LocationPoint> routePoints;

  // Custom theme màu sắc trơn (Solid color) theo đúng yêu cầu Frozen decisions
  final Color routeColor;
  final double strokeWidth;

  OfflineRoutePainter({
    required this.routePoints,
    this.routeColor = Colors.deepOrange, // Màu nổi bật cho polyline
    this.strokeWidth = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.length < 2) return;

    // 1. Tìm giới hạn (Bounding Box) của toàn bộ các điểm GPS
    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (var point in routePoints) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    // 2. Tính tỷ lệ để đưa Polyline vào giữa khung hình (Canvas)
    final double latRange = maxLat - minLat == 0 ? 0.0001 : maxLat - minLat;
    final double lngRange = maxLng - minLng == 0 ? 0.0001 : maxLng - minLng;

    // Tạo margin để đường chạy không chạm viền màn hình
    final double padding = 20.0;
    final double usableWidth = size.width - (padding * 2);
    final double usableHeight = size.height - (padding * 2);

    final Paint paint = Paint()
      ..color = routeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();

    // 3. Ánh xạ từng tọa độ GPS sang X, Y trên màn hình
    for (int i = 0; i < routePoints.length; i++) {
      final point = routePoints[i];

      // Chuyển đổi Kinh độ (Lng) sang trục X
      final double x = padding + ((point.longitude - minLng) / lngRange) * usableWidth;

      // Chuyển đổi Vĩ độ (Lat) sang trục Y (Lưu ý: vĩ độ tăng thì đi lên phía Bắc, trục Y của Canvas tăng thì đi xuống dưới)
      final double y = padding + (1 - ((point.latitude - minLat) / latRange)) * usableHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // 4. Vẽ đường đi lên Canvas
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant OfflineRoutePainter oldDelegate) {
    return oldDelegate.routePoints.length != routePoints.length;
  }
}