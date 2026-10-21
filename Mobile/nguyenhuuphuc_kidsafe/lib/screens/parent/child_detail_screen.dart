import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/child_model.dart';
import '../../providers/children_provider.dart';
import '../../theme/app_theme.dart';
import '../features/location_map_screen.dart';
import '../features/noise_meter_screen.dart';
import '../features/qr_generator_screen.dart';
import 'child_form_screen.dart';

class ChildDetailScreen extends StatelessWidget {
  final ChildModel child;

  const ChildDetailScreen({super.key, required this.child});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa hồ sơ bé?'),
        content: Text('Bạn có chắc chắn muốn xóa hồ sơ "${child.name}" và toàn bộ dữ liệu vị trí, lịch biểu liên quan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
              childrenProvider.deleteChild(child.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa hồ sơ bé thành công!'),
                  backgroundColor: AppTheme.danger,
                ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(child.name),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primary),
            tooltip: 'Mã QR kết nối',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QRGeneratorScreen(child: child)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.secondary),
            tooltip: 'Chỉnh sửa',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChildFormScreen(child: child)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            tooltip: 'Xóa hồ sơ bé',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: child.gender == 'female' ? const Color(0xFFFCE7F3) : const Color(0xFFEEF2FF),
                    child: Icon(
                      child.gender == 'female' ? Icons.face_3_rounded : Icons.face_rounded,
                      size: 44,
                      color: child.gender == 'female' ? Colors.pink : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${child.age} tuổi • Mã máy: ${child.deviceId}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        if (child.phone != null && child.phone!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('SĐT: ${child.phone}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Status Card (Telemetry)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Trạng Thái Thời Gian Thực', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sensors_rounded, size: 12, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text('Live Telemetry', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildMetric(Icons.battery_charging_full_rounded, '${child.batteryLevel}%', 'Pin', AppTheme.accent)),
                      Expanded(
                        child: _buildMetric(
                          Icons.volume_up_rounded,
                          '${child.currentNoiseDb.toStringAsFixed(0)} dB',
                          'Độ ồn',
                          child.currentNoiseDb >= 80 ? AppTheme.danger : (child.currentNoiseDb >= 68 ? AppTheme.warning : AppTheme.primary),
                        ),
                      ),
                      Expanded(child: _buildMetric(Icons.location_on_rounded, 'Quận 1', 'Vị trí', AppTheme.secondary)),
                      Expanded(child: _buildMetric(Icons.wifi_rounded, child.isOnline ? 'Online' : 'Offline', 'Kết nối', AppTheme.accent)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Real-Time Ambient Noise Telemetry Card (Báo về máy phụ huynh theo thời gian thực)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: child.currentNoiseDb >= 80 ? const Color(0xFFFEF2F2) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: child.currentNoiseDb >= 80 ? AppTheme.danger : AppTheme.cardBorder,
                  width: child.currentNoiseDb >= 80 ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (child.currentNoiseDb >= 80 ? AppTheme.danger : Colors.black).withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: child.currentNoiseDb >= 80 ? AppTheme.danger : AppTheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Giám Sát Âm Thanh Máy Bé',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: child.currentNoiseDb >= 80 ? AppTheme.danger : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: child.currentNoiseDb >= 80 ? AppTheme.danger : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          child.currentNoiseDb >= 80 ? 'CẢNH BÁO NGUY HIỂM' : 'Đang Giám Sát',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: child.currentNoiseDb >= 80 ? Colors.white : const Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (child.currentNoiseDb >= 80)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.danger.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'CẢNH BÁO: Độ ồn bên máy ${child.name} đạt ${child.currentNoiseDb.toStringAsFixed(1)} dB! Có dấu hiệu la hét hoặc va chạm lớn!',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.danger, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (child.currentNoiseDb >= 80
                                  ? AppTheme.danger
                                  : (child.currentNoiseDb >= 68 ? AppTheme.warning : AppTheme.accent))
                              .withOpacity(0.12),
                          border: Border.all(
                            color: child.currentNoiseDb >= 80
                                ? AppTheme.danger
                                : (child.currentNoiseDb >= 68 ? AppTheme.warning : AppTheme.accent),
                            width: 2.5,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                child.currentNoiseDb.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: child.currentNoiseDb >= 80
                                      ? AppTheme.danger
                                      : (child.currentNoiseDb >= 68 ? AppTheme.warning : AppTheme.primary),
                                ),
                              ),
                              const Text('dB', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.currentNoiseDb >= 80
                                  ? 'Khu vực cực kỳ ồn ào / Nguy hiểm'
                                  : (child.currentNoiseDb >= 68
                                      ? 'Môi trường nhiều tiếng ồn (Còi xe, đông người)'
                                      : (child.currentNoiseDb >= 45 ? 'Môi trường sinh hoạt bình thường' : 'Không gian rất yên tĩnh (Lớp học, phòng ngủ)')),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Dữ liệu thu nhận trực tiếp từ micro điện thoại của bé theo thời gian thực.',
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NoiseMeterScreen()));
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                      icon: const Icon(Icons.graphic_eq_rounded, size: 16),
                      label: const Text('Mở Máy Đo Tiếng Ồn & Sóng Âm Toàn Diện', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Screen Time Progress Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thời Gian Dùng Máy Hôm Nay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        '${child.usedScreenMinutes}/${child.dailyScreenLimitMinutes} phút',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: child.screenTimeProgress,
                      minHeight: 10,
                      backgroundColor: AppTheme.bgLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        child.isScreenTimeExceeded ? AppTheme.danger : AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    child.isScreenTimeExceeded
                        ? '⚠️ Đã vượt quá giới hạn thời gian! Ứng dụng giải trí đã bị khóa tạm thời.'
                        : 'Bé còn lại ${child.remainingScreenMinutes} phút sử dụng hôm nay.',
                    style: TextStyle(
                      fontSize: 12,
                      color: child.isScreenTimeExceeded ? AppTheme.danger : AppTheme.textMuted,
                      fontWeight: child.isScreenTimeExceeded ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Direct Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationMapScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('Mở Bản Đồ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NoiseMeterScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.graphic_eq_rounded, size: 18),
                    label: const Text('Đo Tiếng Ồn'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }
}
