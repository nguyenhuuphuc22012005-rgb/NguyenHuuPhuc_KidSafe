import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/geofence_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class GeofenceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<GeofenceModel> _geofences = [];
  bool _isLoading = false;

  List<GeofenceModel> get geofences => _geofences;
  bool get isLoading => _isLoading;

  Future<void> loadGeofences(String childId) async {
    _isLoading = true;
    notifyListeners();

    _geofences = await _api.getGeofences(childId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGeofence(GeofenceModel geo) async {
    final created = await _api.createGeofence(geo);
    _geofences.insert(0, created);
    notifyListeners();
  }

  Future<void> updateGeofence(GeofenceModel geo) async {
    await _api.updateGeofence(geo);
    final idx = _geofences.indexWhere((g) => g.id == geo.id);
    if (idx != -1) {
      _geofences[idx] = geo;
      notifyListeners();
    }
  }

  Future<void> deleteGeofence(String id) async {
    await _api.deleteGeofence(id);
    _geofences.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  /// Kiểm tra xem vị trí của bé có nằm trong vùng an toàn nào không
  bool isInsideAnySafeZone(double lat, double lng) {
    if (_geofences.isEmpty) return true;
    final childPos = LatLng(lat, lng);
    for (final geo in _geofences) {
      if (!geo.isActive) continue;
      final dist = LocationService.calculateDistanceMeters(
        childPos,
        LatLng(geo.latitude, geo.longitude),
      );
      if (dist <= geo.radiusMeters) {
        return true;
      }
    }
    return false;
  }
}
