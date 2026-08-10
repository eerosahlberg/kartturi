import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Retrieves the current GPS position of the device.
  /// Returns `null` if the position could not be determined.
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}
