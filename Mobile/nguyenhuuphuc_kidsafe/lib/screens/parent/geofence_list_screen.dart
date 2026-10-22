import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/geofence_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/geofence_provider.dart';
import '../../theme/app_theme.dart';
import 'geofence_form_screen.dart';

class GeofenceListScreen extends StatefulWidget {
  const GeofenceListScreen({super.key});

  @override
  State<GeofenceListScreen> createState() => _GeofenceListScreenState();
}

class _GeofenceListScreenState extends State<GeofenceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childId = Provider.of<ChildrenProvider>(context, listen: false).selectedChild?.id ?? 'ch_01';
      Provider.of<GeofenceProvider>(context, listen: false).loadGeofences(childId);
    });
  }

  void _confirmDelete(BuildContext context, GeofenceModel geo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa vùng an toàn?'),
        content: Text('Bạn có chắc chắn muốn xóa vùng "${geo.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              final geoProvider = Provider.of<GeofenceProvider>(context, listen: false);
              geoProvider.deleteGeofence(geo.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa vùng an toàn!'), backgroundColor: AppTheme.danger),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final geoProvider = Provider.of<GeofenceProvider>(context);
    final child = childrenProvider.selectedChild;

    final geofences = geoProvider.geofences;

    return Scaffold(
      appBar: AppBar(
        title: Text('Vùng An Toàn (${child?.name ?? "Bé"})'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded, color: AppTheme.primary),
            tooltip: 'Thêm vùng an toàn mới',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GeofenceFormScreen()));
            },
          ),
        ],
      ),
      body: geofences.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share_location_outlined, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text('Chưa có vùng an toàn nào được thiết lập', style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GeofenceFormScreen()));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thiết Lập Vùng Đầu Tiên'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: geofences.length,
              itemBuilder: (context, index) {
                final geo = geofences[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: geo.isActive ? const Color(0xFFF0FDF4) : AppTheme.bgLight,
                              child: Icon(
                                Icons.verified_user_rounded,
                                color: geo.isActive ? AppTheme.accent : AppTheme.textMuted,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    geo.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Bán kính: ${geo.radiusMeters.toStringAsFixed(0)}m • ${geo.latitude.toStringAsFixed(3)}, ${geo.longitude.toStringAsFixed(3)}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: geo.isActive,
                              activeColor: AppTheme.accent,
                              onChanged: (val) {
                                geoProvider.updateGeofence(geo.copyWith(isActive: val));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (geo.notifyOnExit)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.logout, size: 12, color: AppTheme.danger),
                                          SizedBox(width: 4),
                                          Text('Báo khi rời khỏi', style: TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  if (geo.notifyOnEntry)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.login, size: 12, color: Color(0xFF16A34A)),
                                          SizedBox(width: 4),
                                          Text('Báo khi đến', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.secondary),
                              tooltip: 'Chỉnh sửa',
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => GeofenceFormScreen(geofence: geo)));
                              },
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                              tooltip: 'Xóa',
                              onPressed: () => _confirmDelete(context, geo),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const GeofenceFormScreen()));
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm Vùng An Toàn', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
