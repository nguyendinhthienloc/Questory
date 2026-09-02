import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/contracts/location_tracker.dart';
import '../../core/domain/run_models.dart';

class GeolocatorLocationTracker implements LocationTracker {
  const GeolocatorLocationTracker();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        LocationPermissionStatus.granted,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.deniedForever,
      _ => LocationPermissionStatus.denied,
    };
  }

  @override
  Stream<GeoPoint> watch() {
    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
            intervalDuration: const Duration(seconds: 5),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Questory run in progress',
              notificationText:
                  'Location recording remains active until you finish or pause.',
              notificationChannelName: 'Run tracking',
              enableWakeLock: true,
              setOngoing: true,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          );
    return Geolocator.getPositionStream(locationSettings: settings).map(
      (position) => GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestampUtc: position.timestamp.toUtc(),
        accuracyMeters: position.accuracy,
        altitudeMeters: position.altitude,
      ),
    );
  }
}
