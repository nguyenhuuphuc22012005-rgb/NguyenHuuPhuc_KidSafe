import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/child_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/geofence_provider.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

enum MapStyleType {
  googleRoadmap,
  googleSatellite,
  googleTerrain,
  openStreetMap,
}

enum TravelMode {
  motorcycle, // Xe máy (mặc định phổ biến tại VN)
  car,        // Ô tô
  walking,    // Đi bộ
}

class NavigationStep {
  final String instruction;
  final String streetName;
  final double distanceMeters;
  final double durationSeconds;
  final String modifier;
  final String maneuverType;

  NavigationStep({
    required this.instruction,
    required this.streetName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.modifier,
    required this.maneuverType,
  });

  IconData get icon {
    if (maneuverType == 'arrive') return Icons.place_rounded;
    if (modifier.contains('left')) return Icons.turn_left_rounded;
    if (modifier.contains('right')) return Icons.turn_right_rounded;
    if (modifier.contains('u-turn')) return Icons.u_turn_left_rounded;
    return Icons.straight_rounded;
  }
}

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _parentLocation = const LatLng(10.7720, 106.6950);
  bool _isLoadingGps = false;
  bool _isLoadingRoute = false;
  bool _showTrail = true;
  bool _isNavigating = true; // Hiển thị thanh dẫn đường Google Maps
  MapStyleType _currentMapStyle = MapStyleType.googleRoadmap;
  TravelMode _travelMode = TravelMode.motorcycle;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  StreamSubscription<LatLng>? _positionStreamSub;

  // Lộ trình uốn lượn theo đường phố (Turn-by-turn road polyline)
  List<LatLng> _routePoints = [];
  double _routeDistanceMeters = 0;
  double _routeDurationSeconds = 0;
  String _currentStreetInstruction = 'Tiến về phía vị trí của bé';
  double _headingAngle = 0.0; // Góc hướng đi (độ) của phụ huynh
  List<NavigationStep> _navigationSteps = [];

  // Lịch sử di chuyển mẫu của bé
  final List<LatLng> _trail = [
    const LatLng(10.7780, 106.7020),
    const LatLng(10.7775, 106.7015),
    const LatLng(10.7769, 106.7009),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeOut);

    _initLocationAndRoute();
    _listenToLiveGps();
  }

  Future<void> _initLocationAndRoute() async {
    await _fetchRealGps(silent: true);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final child = childrenProvider.selectedChild;
    final childPos = child != null ? LatLng(child.latitude, child.longitude) : const LatLng(10.7769, 106.7009);
    await _fetchRealStreetRoute(_parentLocation, childPos);
  }

  void _listenToLiveGps() {
    _positionStreamSub = LocationService.getPositionStream().listen((pos) {
      if (mounted) {
        setState(() => _parentLocation = pos);
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * math.pi / 180;
    final double lon1 = start.longitude * math.pi / 180;
    final double lat2 = end.latitude * math.pi / 180;
    final double lon2 = end.longitude * math.pi / 180;
    final double dLon = lon2 - lon1;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final double brng = math.atan2(y, x);
    return (brng * 180 / math.pi + 360) % 360;
  }

  /// Lấy tọa độ đường phố thực tế (Turn-by-turn road geometry) qua OSRM API
  Future<void> _fetchRealStreetRoute(LatLng from, LatLng to) async {
    if (mounted) setState(() => _isLoadingRoute = true);

    final modeProfile = _travelMode == TravelMode.walking ? 'walking' : 'driving';
    final url = 'https://router.project-osrm.org/route/v1/$modeProfile/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson&steps=true';

    try {
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'KidSafeApp/1.0'}).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          final points = coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();

          List<NavigationStep> steps = [];
          String currentInstruction = 'Đi thẳng theo tuyến đường về phía vị trí của bé';

          try {
            final rawSteps = route['legs'][0]['steps'] as List;
            for (var s in rawSteps) {
              final street = (s['name'] != null && s['name'].toString().isNotEmpty) ? s['name'].toString() : 'đường không tên';
              final modifier = s['maneuver']?['modifier']?.toString() ?? 'straight';
              final type = s['maneuver']?['type']?.toString() ?? 'turn';

              String vnText;
              if (type == 'arrive') {
                vnText = 'Đến vị trí đích của Bé';
              } else if (modifier.contains('left')) {
                vnText = 'Rẽ trái vào $street';
              } else if (modifier.contains('right')) {
                vnText = 'Rẽ phải vào $street';
              } else if (modifier.contains('u-turn')) {
                vnText = 'Quay đầu xe trên $street';
              } else {
                vnText = 'Đi thẳng vào $street';
              }

              steps.add(NavigationStep(
                instruction: vnText,
                streetName: street,
                distanceMeters: (s['distance'] as num).toDouble(),
                durationSeconds: (s['duration'] as num).toDouble(),
                modifier: modifier,
                maneuverType: type,
              ));
            }

            if (steps.isNotEmpty) {
              currentInstruction = steps[0].instruction;
            }
          } catch (_) {}

          double bearing = 0.0;
          if (points.length >= 2) {
            bearing = _calculateBearing(points[0], points[1]);
          }

          double distance = (route['distance'] as num).toDouble();
          double duration = (route['duration'] as num).toDouble();

          // Điều chỉnh tốc độ di chuyển theo phương tiện tại Việt Nam
          if (_travelMode == TravelMode.motorcycle) {
            duration = (distance / 32000) * 3600; // ~32 km/h xe máy
          }

          if (mounted) {
            setState(() {
              _routePoints = points;
              _routeDistanceMeters = distance;
              _routeDurationSeconds = duration;
              _currentStreetInstruction = currentInstruction;
              _navigationSteps = steps;
              _headingAngle = bearing;
              _isLoadingRoute = false;
            });
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback: Tạo mạng lưới đường phố bàn cờ đa điểm góc vuông (không bao giờ vẽ 1 đường chéo thẳng qua nhà cửa)
    if (mounted) {
      final List<LatLng> gridPoints = [];
      gridPoints.add(from);
      final double latDiff = to.latitude - from.latitude;
      final double lngDiff = to.longitude - from.longitude;

      // 4 khúc cua bàn cờ
      gridPoints.add(LatLng(from.latitude + latDiff * 0.35, from.longitude));
      gridPoints.add(LatLng(from.latitude + latDiff * 0.35, from.longitude + lngDiff * 0.6));
      gridPoints.add(LatLng(from.latitude + latDiff * 0.85, from.longitude + lngDiff * 0.6));
      gridPoints.add(LatLng(from.latitude + latDiff * 0.85, to.longitude));
      gridPoints.add(to);

      final dist = LocationService.calculateDistanceMeters(from, to) * 1.35;
      final speed = _travelMode == TravelMode.walking ? 4.5 : (_travelMode == TravelMode.motorcycle ? 32.0 : 25.0);
      final dur = (dist / 1000 / speed) * 3600;

      setState(() {
        _routePoints = gridPoints;
        _routeDistanceMeters = dist;
        _routeDurationSeconds = dur;
        _currentStreetInstruction = 'Dẫn đường theo mạng lưới giao thông đến vị trí của bé';
        _headingAngle = _calculateBearing(gridPoints[0], gridPoints[1]);
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _fetchRealGps({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingGps = true);
    final pos = await LocationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _parentLocation = pos;
        _isLoadingGps = false;
      });
      if (!silent) {
        _mapController.move(_parentLocation, 16.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật vị trí GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'),
            backgroundColor: AppTheme.accent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Mở ứng dụng Google Maps Navigation chính thức trên điện thoại
  Future<void> _openOfficialGoogleMaps(double destLat, double destLng) async {
    final appUri = Uri.parse('google.navigation:q=$destLat,$destLng&mode=d');
    final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=${_parentLocation.latitude},${_parentLocation.longitude}&destination=$destLat,$destLng&travelmode=driving');

    try {
      final launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở Google Maps: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showNavigationStepsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F9D58).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_rounded, color: Color(0xFF0F9D58), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi Tiết Hướng Đi (Google Maps)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        Text(
                          '${LocationService.formatDistance(_routeDistanceMeters)} • ${(_routeDurationSeconds / 60).ceil()} phút',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _navigationSteps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.route_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text('Đang tính toán các ngã rẽ...', style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _navigationSteps.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 48),
                      itemBuilder: (ctx, i) {
                        final step = _navigationSteps[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor: i == 0
                                ? const Color(0xFF0F9D58)
                                : (i == _navigationSteps.length - 1 ? const Color(0xFFEA4335) : const Color(0xFF1A73E8).withValues(alpha: 0.15)),
                            foregroundColor: (i == 0 || i == _navigationSteps.length - 1) ? Colors.white : const Color(0xFF1A73E8),
                            child: Icon(step.icon, size: 20),
                          ),
                          title: Text(
                            step.instruction,
                            style: TextStyle(
                              fontWeight: i == 0 ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                              color: i == 0 ? const Color(0xFF0F9D58) : AppTheme.textDark,
                            ),
                          ),
                          subtitle: Text(
                            LocationService.formatDistance(step.distanceMeters),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String get _mapUrlTemplate {
    switch (_currentMapStyle) {
      case MapStyleType.googleRoadmap:
        return 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case MapStyleType.googleSatellite:
        return 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case MapStyleType.googleTerrain:
        return 'https://mt{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
      case MapStyleType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> get _mapSubdomains {
    if (_currentMapStyle == MapStyleType.openStreetMap) {
      return const ['a', 'b', 'c'];
    }
    return const ['0', '1', '2', '3'];
  }

  void _shareLocation(double lat, double lng, String childName) {
    final url = LocationService.getShareableMapUrl(lat, lng);
    final navUrl = LocationService.getNavigationUrl(lat, lng);
    final shareText = '📍 Vị trí hiện tại của $childName:\n'
        'Tọa độ: $lat, $lng\n'
        'Xem trên Google Maps: $url\n'
        'Chỉ đường tới vị trí: $navUrl';

    Clipboard.setData(ClipboardData(text: shareText));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.share_location_rounded, color: Color(0xFF4285F4), size: 30),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chia Sẻ Vị Trí Thành Công', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Đã sao chép liên kết Google Maps vào bộ nhớ tạm', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(shareText, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapStylePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn Kiểu Bản Đồ (Google Maps)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            _buildMapStyleOption(
              type: MapStyleType.googleRoadmap,
              title: 'Google Maps Đường Phố',
              subtitle: 'Bản đồ giao thông, tên đường tiếng Việt, địa danh chuẩn Google',
              icon: Icons.map_rounded,
              color: const Color(0xFF4285F4),
            ),
            _buildMapStyleOption(
              type: MapStyleType.googleSatellite,
              title: 'Google Maps Vệ Tinh (Hybrid)',
              subtitle: 'Hình ảnh chụp từ vệ tinh kết hợp tên đường và ranh giới',
              icon: Icons.satellite_alt_rounded,
              color: const Color(0xFF0F9D58),
            ),
            _buildMapStyleOption(
              type: MapStyleType.googleTerrain,
              title: 'Google Maps Địa Hình',
              subtitle: 'Đường đồng mức, đồi núi và mạng lưới giao thông',
              icon: Icons.terrain_rounded,
              color: const Color(0xFFF4B400),
            ),
            _buildMapStyleOption(
              type: MapStyleType.openStreetMap,
              title: 'OpenStreetMap (Cộng Đồng)',
              subtitle: 'Bản đồ mã nguồn mở toàn cầu',
              icon: Icons.public_rounded,
              color: const Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapStyleOption({
    required MapStyleType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _currentMapStyle == type;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE2E8F0),
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
        onTap: () {
          setState(() => _currentMapStyle = type);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _fitBothLocations(LatLng p1, LatLng p2) {
    final bounds = LatLngBounds(p1, p2);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(top: 150, bottom: 250, left: 60, right: 60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final geofenceProvider = Provider.of<GeofenceProvider>(context);
    final child = childrenProvider.selectedChild;
    final childPos = child != null ? LatLng(child.latitude, child.longitude) : const LatLng(10.7769, 106.7009);

    final displayDistance = _routeDistanceMeters > 0
        ? LocationService.formatDistance(_routeDistanceMeters)
        : LocationService.formatDistance(LocationService.calculateDistanceMeters(_parentLocation, childPos));

    final displayMinutes = _routeDurationSeconds > 0
        ? '${(_routeDurationSeconds / 60).ceil()} phút'
        : '${(LocationService.calculateDistanceMeters(_parentLocation, childPos) / 400).ceil()} phút';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản Đồ Chỉ Đường Google Maps'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_rounded, color: Color(0xFF1A73E8)),
            tooltip: 'Lớp bản đồ',
            onPressed: _showMapStylePicker,
          ),
          IconButton(
            icon: (_isLoadingGps || _isLoadingRoute)
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Cập nhật lại tuyến đường',
            onPressed: () async {
              await _fetchRealGps();
              await _fetchRealStreetRoute(_parentLocation, childPos);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. BẢN ĐỒ GOOGLE MAPS
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: childPos,
              initialZoom: 15.2,
              maxZoom: 19.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayer(
                urlTemplate: _mapUrlTemplate,
                subdomains: _mapSubdomains,
                userAgentPackageName: 'com.nguyenhuuphuc.nguyenhuuphuc_kidsafe',
                maxZoom: 19,
              ),

              // Vùng an toàn Geofencing
              CircleLayer(
                circles: geofenceProvider.geofences.map((geo) {
                  return CircleMarker(
                    point: LatLng(geo.latitude, geo.longitude),
                    radius: geo.radiusMeters,
                    useRadiusInMeter: true,
                    color: const Color(0xFF10B981).withValues(alpha: 0.16),
                    borderColor: const Color(0xFF10B981),
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),

              // LỘ TRÌNH DẪN ĐƯỜNG UỐN LƯỢN THEO ĐƯỜNG PHỐ (REAL STREET ROUTING POLYLINE)
              PolylineLayer(
                polylines: [
                  if (_routePoints.length > 1) ...[
                    // Lớp viền xanh đậm bên ngoài chuẩn Google Maps
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.85),
                      strokeWidth: 7.0,
                    ),
                    // Lớp màu xanh Google Navigation bên trong
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF1A73E8),
                      strokeWidth: 4.8,
                    ),
                  ],
                  // Lịch sử di chuyển của bé
                  if (_showTrail)
                    Polyline(
                      points: _trail,
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
                      strokeWidth: 3.0,
                    ),
                ],
              ),

              // MARKERS
              MarkerLayer(
                markers: [
                  // MARKER BÉ (GHIM BẢN ĐỒ CHUẨN GOOGLE MAPS PIN)
                  Marker(
                    point: childPos,
                    width: 72,
                    height: 80,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA4335), // Đỏ Google Pin
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 17,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.face_rounded, color: Color(0xFFEA4335), size: 22),
                          ),
                        ),
                        CustomPaint(
                          size: const Size(12, 8),
                          painter: _PinPointPainter(color: const Color(0xFFEA4335)),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            child?.name ?? 'Bé Bo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // MARKER PHỤ HUYNH (GOOGLE MAPS BLUE DOT WITH DIRECTION ARROW)
                  Marker(
                    point: _parentLocation,
                    width: 70,
                    height: 70,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Sóng radar pulsing
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 22 + (_pulseAnimation.value * 42),
                                height: 22 + (_pulseAnimation.value * 42),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF4285F4).withValues(alpha: (1.0 - _pulseAnimation.value) * 0.45),
                                ),
                              );
                            },
                          ),
                          // Mũi tên hướng đi Google Maps Navigation Heading Beam
                          Transform.rotate(
                            angle: _headingAngle * math.pi / 180,
                            child: CustomPaint(
                              size: const Size(36, 36),
                              painter: _HeadingArrowPainter(),
                            ),
                          ),
                          // Chấm tròn GPS xanh Google
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A73E8),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. KHUNG DẪN ĐƯỜNG GOOGLE MAPS NAVIGATION BANNER (Xanh lá phía trên)
          if (_isNavigating)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F9D58), // Google Navigation Green
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _navigationSteps.isNotEmpty ? _navigationSteps[0].icon : Icons.turn_slight_right_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentStreetInstruction,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '$displayMinutes • $displayDistance',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: _showNavigationStepsDialog,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Xem các bước ▾',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => setState(() => _isNavigating = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Chuyển đổi phương tiện di chuyển
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTravelModeChip(TravelMode.motorcycle, '🛵 Xe máy', childPos),
                        const SizedBox(width: 8),
                        _buildTravelModeChip(TravelMode.car, '🚗 Ô tô', childPos),
                        const SizedBox(width: 8),
                        _buildTravelModeChip(TravelMode.walking, '🚶 Đi bộ', childPos),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // 3. THANH NÚT FLOATING GOOGLE MAPS CONTROLS (Bên phải)
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              children: [
                // Nút My Location GPS
                FloatingActionButton.small(
                  heroTag: 'btn_my_location',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A73E8),
                  elevation: 4,
                  tooltip: 'Vị trí của bạn',
                  onPressed: () {
                    _mapController.move(_parentLocation, 16.5);
                  },
                  child: const Icon(Icons.my_location_rounded, size: 20),
                ),
                const SizedBox(height: 10),
                // Nút Child Focus
                FloatingActionButton.small(
                  heroTag: 'btn_child_location',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFEA4335),
                  elevation: 4,
                  tooltip: 'Vị trí của bé',
                  onPressed: () {
                    _mapController.move(childPos, 16.5);
                  },
                  child: const Icon(Icons.child_care_rounded, size: 20),
                ),
                const SizedBox(height: 10),
                // Nút Toàn cảnh (Fit cả 2)
                FloatingActionButton.small(
                  heroTag: 'btn_fit_both',
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textDark,
                  elevation: 4,
                  tooltip: 'Toàn cảnh lộ trình',
                  onPressed: () => _fitBothLocations(_parentLocation, childPos),
                  child: const Icon(Icons.crop_free_rounded, size: 20),
                ),
                const SizedBox(height: 10),
                // Cụm Zoom in / Zoom out
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'Phóng to',
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom + 1);
                        },
                      ),
                      const Divider(height: 1),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        tooltip: 'Thu nhỏ',
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom - 1);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. THẺ THÔNG TIN & NÚT CHỈ ĐƯỜNG GOOGLE MAPS CHÍNH THỨC (Bottom Card)
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                        child: const Icon(Icons.directions_car_filled_rounded, color: Color(0xFF1A73E8), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  child?.name ?? 'Bé Bo (Gia Bảo)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Online • 85% Pin', style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Lộ trình: $displayDistance (~$displayMinutes)',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // GPS Coordinates & Toggle Trail
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pin_drop_rounded, size: 16, color: Color(0xFFEA4335)),
                            const SizedBox(width: 6),
                            Text(
                              'GPS: ${childPos.latitude.toStringAsFixed(4)}° N, ${childPos.longitude.toStringAsFixed(4)}° E',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isNavigating = true;
                              _showTrail = !_showTrail;
                            });
                          },
                          child: Text(
                            _showTrail ? 'Ẩn lịch sử' : 'Hiện lịch sử',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF1A73E8), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3 NÚT THAO TÁC: MỞ CHỈ ĐƯỜNG GOOGLE MAPS, CHI TIẾT HƯỚNG ĐI VÀ CHIA SẺ VỊ TRÍ
                  Row(
                    children: [
                      // NÚT CHỈ ĐƯỜNG (MỞ TRỰC TIẾP APP GOOGLE MAPS CHÍNH THỨC)
                      Expanded(
                        flex: 5,
                        child: ElevatedButton.icon(
                          onPressed: () => _openOfficialGoogleMaps(childPos.latitude, childPos.longitude),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A73E8),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text('Chỉ Đường', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // NÚT CHI TIẾT HƯỚNG ĐI
                      Expanded(
                        flex: 4,
                        child: OutlinedButton.icon(
                          onPressed: _showNavigationStepsDialog,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(color: Color(0xFF0F9D58), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.alt_route_rounded, size: 18, color: Color(0xFF0F9D58)),
                          label: const Text('Hướng Đi', style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // NÚT CHIA SẺ VỊ TRÍ
                      IconButton(
                        onPressed: () => _shareLocation(childPos.latitude, childPos.longitude, child?.name ?? 'Bé Bo'),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF1A73E8)),
                        tooltip: 'Chia sẻ vị trí',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelModeChip(TravelMode mode, String label, LatLng childPos) {
    final isSelected = _travelMode == mode;
    return InkWell(
      onTap: () {
        setState(() => _travelMode = mode);
        _fetchRealStreetRoute(_parentLocation, childPos);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0F9D58) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// Vẽ đầu nhọn tam giác chỉ xuống đất cho ghim vị trí chuẩn Google Maps Pin
class _PinPointPainter extends CustomPainter {
  final Color color;
  _PinPointPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vẽ mũi tên định hướng chỉ đường Google Maps Navigation Heading Beam
class _HeadingArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width / 2, size.height / 2),
        Offset(size.width / 2, 0),
        [
          const Color(0xFF1A73E8).withValues(alpha: 0.75),
          const Color(0xFF4285F4).withValues(alpha: 0.0),
        ],
      )
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(size.width / 2, size.height / 2)
      ..lineTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.8, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
