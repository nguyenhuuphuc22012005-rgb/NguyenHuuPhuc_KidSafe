import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static const LatLng defaultLocation = LatLng(10.7769, 106.7009); // TP. Hồ Chí Minh

  static Future<LatLng> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return defaultLocation;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return defaultLocation;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return defaultLocation;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Fallback khi chạy trên Windows Desktop / Web hoặc không có GPS phần cứng
      return defaultLocation;
    }
  }

  /// Luồng cập nhật vị trí GPS thời gian thực (Live GPS stream)
  static Stream<LatLng> getPositionStream() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3, // cập nhật khi di chuyển từ 3m
        ),
      ).map((pos) => LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      return Stream.value(defaultLocation);
    }
  }

  static double calculateDistanceMeters(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2);
  }

  static String getShareableMapUrl(double lat, double lng) {
    return 'https://maps.google.com/?q=$lat,$lng';
  }

  static String getNavigationUrl(double lat, double lng) {
    return 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }
}
