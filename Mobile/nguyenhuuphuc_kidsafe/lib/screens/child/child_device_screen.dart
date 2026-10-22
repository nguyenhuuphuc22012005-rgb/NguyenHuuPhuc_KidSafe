import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/noise_provider.dart';
import '../../providers/sos_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/contact_provider.dart';
import '../../models/schedule_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/mock_data_service.dart';
import '../../services/noise_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../features/qr_generator_screen.dart';
import '../parent/parent_home_screen.dart';
import '../staff/staff_dashboard_screen.dart';

class ChildDeviceScreen extends StatefulWidget {
  const ChildDeviceScreen({super.key});

  @override
  State<ChildDeviceScreen> createState() => _ChildDeviceScreenState();
}

class _ChildDeviceScreenState extends State<ChildDeviceScreen> {
  final NoiseService _noiseService = NoiseService();
  double _currentDecibel = 42.0;
  NoiseLevelCategory _category = NoiseLevelCategory.normal;
  bool _isAutoSosEnabled = true;
  bool _isSosAlertTriggered = false;
  DateTime? _lastBackendSyncTime;
  Timer? _gpsTimer;
  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    _startChildNoiseMonitoring();
    _reportLocation();
    _gpsTimer = Timer.periodic(const Duration(seconds: 15), (_) => _reportLocation());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childId = Provider.of<ChildrenProvider>(context, listen: false).selectedChild?.id ?? 'ch_01';
      Provider.of<ScheduleProvider>(context, listen: false).loadSchedules(childId);
      Provider.of<ContactProvider>(context, listen: false).loadContacts(childId);
    });

    // Cập nhật trạng thái khóa ứng dụng & lịch biểu theo thời gian thực mỗi 2 giây
    _realtimeTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  String _getTodayKey() {
    switch (DateTime.now().weekday) {
      case DateTime.monday: return 'Mon';
      case DateTime.tuesday: return 'Tue';
      case DateTime.wednesday: return 'Wed';
      case DateTime.thursday: return 'Thu';
      case DateTime.friday: return 'Fri';
      case DateTime.saturday: return 'Sat';
      case DateTime.sunday: return 'Sun';
      default: return 'Mon';
    }
  }

  ScheduleModel? _findActiveLockSchedule(List<ScheduleModel> schedules) {
    final now = DateTime.now();
    final today = _getTodayKey();
    final currentMinutes = now.hour * 60 + now.minute;

    for (final s in schedules) {
      if (!s.isActive || !s.blockApps) continue;
      if (!s.days.split(',').map((e) => e.trim()).contains(today)) continue;

      try {
        final sParts = s.startTime.split(':');
        final eParts = s.endTime.split(':');
        final startMins = int.parse(sParts[0]) * 60 + int.parse(sParts[1]);
        final endMins = int.parse(eParts[0]) * 60 + int.parse(eParts[1]);

        if (startMins <= endMins) {
          if (currentMinutes >= startMins && currentMinutes <= endMins) {
            return s;
          }
        } else {
          // Khung giờ qua đêm (ví dụ: 22:00 - 06:30)
          if (currentMinutes >= startMins || currentMinutes <= endMins) {
            return s;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _reportLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
      final childId = childrenProvider.selectedChild?.id ?? 'ch_01';
      await ApiService().reportChildLocation(
        childId: childId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        batteryLevel: 88,
      );
    } catch (_) {}
  }

  void _startChildNoiseMonitoring() {
    _noiseService.startMonitoring();
    _noiseService.addListener(_onNoiseChanged);
  }

  void _onNoiseChanged(double db, NoiseLevelCategory cat) {
    if (!mounted) return;

    setState(() {
      _currentDecibel = db;
      _category = cat;
    });

    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final noiseProvider = Provider.of<NoiseProvider>(context, listen: false);
    final child = childrenProvider.selectedChild;
    final childId = child?.id ?? 'ch_01';

    // Đồng bộ thời gian thực vào Provider và Backend mỗi 2 giây
    final now = DateTime.now();
    if (_lastBackendSyncTime == null || now.difference(_lastBackendSyncTime!).inSeconds >= 2) {
      _lastBackendSyncTime = now;
      childrenProvider.updateChildNoise(childId, db, status: cat.name);
    }

    // Tự động kích hoạt SOS khi phát hiện âm thanh vượt ngưỡng thiết lập
    final threshold = noiseProvider.warningThreshold;
    if (_isAutoSosEnabled && noiseProvider.isThresholdAlertEnabled && db >= threshold && !_isSosAlertTriggered) {
      _isSosAlertTriggered = true;
      _triggerAutoLoudNoiseSOS(db, threshold);
    }
  }

  void _triggerAutoLoudNoiseSOS(double db, double threshold) {
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final sosProvider = Provider.of<SOSProvider>(context, listen: false);
    final child = childrenProvider.selectedChild;

    sosProvider.createSOS(
      childId: child?.id ?? 'ch_01',
      childName: child?.name ?? 'Bé Bo (Gia Bảo)',
      parentName: 'Nguyễn Hữu Phúc',
      parentPhone: '0988776655',
      latitude: child?.latitude ?? 10.7769,
      longitude: child?.longitude ?? 106.7009,
      noiseLevel: db,
      reason: 'AI Acoustic Shield: Phát hiện tiếng ồn (${db.toStringAsFixed(1)} dB) vượt ngưỡng an toàn đã thiết lập (${threshold.toStringAsFixed(0)} dB)!',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Đã phát hiện âm thanh lớn (${db.toStringAsFixed(1)} dB) vượt ngưỡng ${threshold.toStringAsFixed(0)} dB! Tín hiệu cảnh báo đã gửi đến Bố Mẹ!'),
        backgroundColor: AppTheme.danger,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _realtimeTimer?.cancel();
    _noiseService.removeListener(_onNoiseChanged);
    super.dispose();
  }

  void _triggerKidSOS(BuildContext context) {
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final sosProvider = Provider.of<SOSProvider>(context, listen: false);
    final child = childrenProvider.selectedChild;

    sosProvider.createSOS(
      childId: child?.id ?? 'ch_01',
      childName: child?.name ?? 'Bé Bo (Gia Bảo)',
      parentName: 'Nguyễn Hữu Phúc',
      parentPhone: '0988776655',
      latitude: child?.latitude ?? 10.7769,
      longitude: child?.longitude ?? 106.7009,
      noiseLevel: _currentDecibel,
      reason: 'Bé nhấn nút SOS Khẩn Cấp trên màn hình điện thoại!',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.danger, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đã Gửi Tín Hiệu SOS!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: const Text(
          'Đã gửi vị trí GPS của con và mức độ ồn môi trường đến Bố Mẹ và Tổng đài cứu hộ khẩn cấp. Con hãy đứng yên tại nơi an toàn và chờ người lớn đến nhé!',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Con Đã Hiểu'),
          ),
        ],
      ),
    );
  }

  void _showRequestTimeDialog(BuildContext context, dynamic child) {
    int selectedMinutes = 30;
    final reasonController = TextEditingController(text: 'Con cần học bài và làm bài tập');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.hourglass_top_rounded, color: AppTheme.primary, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Xin Thêm Giờ Dùng Máy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn số phút muốn xin thêm:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [15, 30, 45, 60].map((mins) {
                      final isSelected = selectedMinutes == mins;
                      return ChoiceChip(
                        label: Text('+$mins phút', style: TextStyle(color: isSelected ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.bold)),
                        selected: isSelected,
                        selectedColor: AppTheme.primary,
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedMinutes = mins);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Lý do xin thêm:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do gửi đến Bố Mẹ...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: isSubmitting ? null : () async {
                  setDialogState(() => isSubmitting = true);
                  final childId = child?.id ?? 'ch_01';
                  final childName = child?.name ?? 'Bé Bo (Gia Bảo)';
                  final parentId = child?.parentId ?? 'user_parent_01';
                  final reason = reasonController.text.trim().isEmpty ? 'Con cần học bài' : reasonController.text.trim();

                  final req = await ApiService().createTimeRequest(
                    childId: childId,
                    childName: childName,
                    parentId: parentId,
                    requestedMinutes: selectedMinutes,
                    reason: reason,
                  );

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(req != null
                            ? '✅ Đã gửi yêu cầu xin thêm $selectedMinutes phút đến Bố Mẹ thành công!'
                            : '⚠️ Đã gửi yêu cầu vào hệ thống.'),
                        backgroundColor: AppTheme.accent,
                      ),
                    );
                  }
                },
                icon: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: const Text('Gửi Đến Bố Mẹ'),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getDecibelColor(double db) {
    if (db >= 85) return AppTheme.danger;
    if (db >= 68) return AppTheme.warning;
    if (db >= 45) return AppTheme.secondary;
    return AppTheme.accent;
  }

  String _getCategoryText(NoiseLevelCategory cat) {
    switch (cat) {
      case NoiseLevelCategory.danger:
        return 'Nguy Hiểm (>85 dB)';
      case NoiseLevelCategory.loud:
        return 'Ồn Ào (68-84 dB)';
      case NoiseLevelCategory.normal:
        return 'Bình Thường (45-67 dB)';
      case NoiseLevelCategory.quiet:
        return 'Yên Tĩnh (<45 dB)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final child = childrenProvider.selectedChild;
    final catColor = _getDecibelColor(_currentDecibel);

    // Kiểm tra lịch biểu giới hạn & khóa app theo thời gian thực
    final schedules = scheduleProvider.schedules.isNotEmpty
        ? scheduleProvider.schedules
        : MockDataService().getSchedules(child?.id ?? 'ch_01');
    final activeLockSchedule = _findActiveLockSchedule(schedules);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Chế Độ Điện Thoại Trẻ Em (Child)'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primary),
            tooltip: 'Chuyển đổi vai trò kiểm thử',
            onSelected: (role) {
              auth.switchRole(role);
              if (role == 'admin') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              } else if (role == 'staff') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StaffDashboardScreen()));
              } else if (role == 'parent') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentHomeScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'parent', child: Text('👤 Chuyển sang Phụ Huynh')),
              const PopupMenuItem(value: 'admin', child: Text('👑 Chuyển sang Admin')),
              const PopupMenuItem(value: 'staff', child: Text('🎧 Chuyển sang Nhân Viên')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Welcome Child Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.sentiment_very_satisfied_rounded, size: 38, color: Colors.blue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào ${child?.name ?? "Bé"}! 👋',
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Điện thoại được bảo vệ bởi KidSafe AI',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // THỜI GIAN THỰC: Thẻ Cảnh Báo Khóa Ứng Dụng Theo Lịch Biểu Bố Mẹ Thiết Lập
            if (activeLockSchedule != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_clock_rounded, color: AppTheme.danger, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đang trong lịch: ${activeLockSchedule.title}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Khung giờ: ${activeLockSchedule.startTime} - ${activeLockSchedule.endTime} • Khóa ứng dụng giải trí',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppTheme.danger, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Ứng dụng giải trí bị khóa. Con hãy tập trung học bài nhé!',
                              style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () => _showRequestTimeDialog(context, child),
                            child: const Text('Xin mở', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Không có lịch giới hạn đang chạy. Điện thoại tự do.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Real-Time Ambient Noise Telemetry Card (Yêu cầu đo tiếng ồn & báo về Bố Mẹ)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: catColor.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: catColor.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mic_rounded, color: catColor, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Đo Tiếng Ồn Xung Quanh Bé',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sensors_rounded, size: 13, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text(
                              'Đang phát',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Gauge Meter Circle
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: catColor.withOpacity(0.12),
                          border: Border.all(color: catColor, width: 2.5),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentDecibel.toStringAsFixed(0),
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: catColor),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getCategoryText(_category),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: catColor),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentDecibel >= 80
                                  ? '⚠️ Âm thanh rất lớn! Cảnh báo nguy hiểm đang kích hoạt!'
                                  : 'Micro đang liên tục ghi nhận âm thanh môi trường quanh bé.',
                              style: TextStyle(
                                fontSize: 11,
                                color: _currentDecibel >= 80 ? AppTheme.danger : AppTheme.textMuted,
                                fontWeight: _currentDecibel >= 80 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Tự động báo về Bố Mẹ khi tiếng ồn >80 dB:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: _isAutoSosEnabled,
                        activeColor: AppTheme.accent,
                        onChanged: (val) => setState(() => _isAutoSosEnabled = val),
                      ),
                    ],
                  ),
                  // Demo Quick Scenario Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.volume_mute, size: 14, color: AppTheme.accent),
                        label: const Text('Bình thường (45 dB)', style: TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFFF0FDF4),
                        onPressed: () {
                          _noiseService.setScenario('normal');
                          _isSosAlertTriggered = false;
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.danger),
                        label: const Text('Thử La hét SOS (92 dB)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.danger)),
                        backgroundColor: const Color(0xFFFEE2E2),
                        onPressed: () {
                          _isSosAlertTriggered = false;
                          _noiseService.setScenario('danger');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Giant Emergency SOS Button
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFECACA), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.danger.withOpacity(0.12),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'KHI CẦN GIÚP ĐỠ KHẨN CẤP',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.danger, letterSpacing: 1),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _triggerKidSOS(context),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        gradient: AppTheme.emergencyGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.danger.withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_rounded, color: Colors.white, size: 44),
                          SizedBox(height: 4),
                          Text(
                            'SOS',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Bấm nút đỏ để gọi ngay Bố Mẹ và Tổng đài cứu hộ!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Remaining Screen Time Card
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
                      const Text('Thời Gian Dùng Máy Còn Lại', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        '${child?.remainingScreenMinutes ?? 105} phút',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: child?.screenTimeProgress ?? 0.4,
                      minHeight: 10,
                      backgroundColor: AppTheme.bgLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRequestTimeDialog(context, child),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.alarm_add_rounded, size: 20, color: AppTheme.primary),
                      label: const Text(
                        'Xin Thêm Thời Gian Sử Dụng',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Call Emergency Contacts (Đồng bộ danh bạ an toàn của Bố Mẹ)
            Consumer<ContactProvider>(
              builder: (context, contactProv, _) {
                final childContacts = contactProv.contacts.isNotEmpty
                    ? contactProv.contacts
                    : MockDataService().getContacts(child?.id ?? 'ch_01');

                return Container(
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
                          const Text('Danh Bạ An Toàn Từ Bố Mẹ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${childContacts.length} số', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (childContacts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Chưa có số nào trong danh bạ an toàn.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: childContacts.map((c) {
                              final isEmergency = c.isSosContact || c.phone == '113' || c.relationship == 'Khẩn cấp';
                              final color = isEmergency ? AppTheme.danger : (c.relationship == 'Mẹ' ? Colors.pink : AppTheme.primary);
                              return Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: _buildContactBtn(context, c.name, c.phone, isEmergency ? Icons.local_police : Icons.call, color),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Show My QR Button
            OutlinedButton.icon(
              onPressed: () {
                if (child != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => QRGeneratorScreen(child: child)));
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: const Text('Mở Mã QR Để Bố Mẹ Quét Kết Nối'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactBtn(BuildContext context, String name, String phone, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đang kết nối cuộc gọi đến $name ($phone)...'),
            backgroundColor: color,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
