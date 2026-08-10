import 'package:permission_handler/permission_handler.dart';

class LocationPermissionHandler {
  /// Requests location permission from the user.
  /// Returns `true` if permission was granted, `false` otherwise.
  static Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Checks whether location permission has already been granted.
  static Future<bool> hasPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }
}
