import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'location_failure.dart';

enum AppLocationPermission { denied, deniedForever, whileInUse, always }

class LocationAccessStatus {
  const LocationAccessStatus({
    required this.serviceEnabled,
    required this.permission,
  });

  final bool serviceEnabled;
  final AppLocationPermission permission;

  bool get permissionGranted =>
      permission == AppLocationPermission.whileInUse ||
      permission == AppLocationPermission.always;

  bool get fullyAvailable => serviceEnabled && permissionGranted;
}

class LocationService {
  const LocationService();

  Future<LocationAccessStatus> getStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    return LocationAccessStatus(
      serviceEnabled: serviceEnabled,
      permission: _mapPermission(permission),
    );
  }

  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        LocationFailureType.serviceDisabled,
        'Dịch vụ vị trí trên thiết bị đang tắt.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        LocationFailureType.permissionDenied,
        'Bạn chưa cho phép TrọSV sử dụng vị trí.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureType.permissionDeniedForever,
        'Quyền vị trí đã bị từ chối vĩnh viễn.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      throw const LocationFailure(
        LocationFailureType.timeout,
        'Không lấy được GPS trong thời gian cho phép.',
      );
    } catch (_) {
      throw const LocationFailure(
        LocationFailureType.unavailable,
        'Không thể lấy vị trí hiện tại.',
      );
    }
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

AppLocationPermission _mapPermission(LocationPermission permission) {
  return switch (permission) {
    LocationPermission.always => AppLocationPermission.always,
    LocationPermission.whileInUse => AppLocationPermission.whileInUse,
    LocationPermission.deniedForever => AppLocationPermission.deniedForever,
    _ => AppLocationPermission.denied,
  };
}
