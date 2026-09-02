import '../domain/run_models.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
}

abstract interface class LocationTracker {
  Future<bool> isServiceEnabled();

  Future<LocationPermissionStatus> requestPermission();

  Stream<GeoPoint> watch();
}
