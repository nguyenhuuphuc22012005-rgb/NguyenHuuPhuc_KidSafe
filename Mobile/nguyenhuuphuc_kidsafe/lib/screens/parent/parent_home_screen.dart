import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/geofence_provider.dart';
import '../../models/time_request_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../child/child_device_screen.dart';
import '../features/ai_acoustic_shield_screen.dart';
import '../features/location_map_screen.dart';
import '../features/noise_meter_screen.dart';
import '../features/qr_generator_screen.dart';
import '../features/qr_scanner_screen.dart';
import '../staff/staff_dashboard_screen.dart';
import 'child_detail_screen.dart';
import 'child_form_screen.dart';
import 'contact_list_screen.dart';
import 'geofence_list_screen.dart';
import 'schedule_list_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  List<TimeRequestModel> _pendingTimeRequests = [];

  @override
  void initState() {
    super.initState();
    _loadTimeRequests();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
      if (childrenProvider.selectedChild != null) {
        Provider.of<GeofenceProvider>(context, listen: false)
            .loadGeofences(childrenProvider.selectedChild!.id);
      }
    });
  }

  Future<void> _loadTimeRequests() async {
    try {
      final reqs = await ApiService().getTimeRequests();
      if (mounted) {
        setState(() {
          _pendingTimeRequests = reqs.where((r) => r.isPending).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _reviewRequest(TimeRequestModel req, bool isApproved) async {
    await ApiService().reviewTimeRequest(requestId: req.id, isApproved: isApproved);
    if (!mounted) return;

    if (isApproved) {
      Provider.of<ChildrenProvider>(context, listen: false)
          .extendScreenTime(req.childId, req.requestedMinutes);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isApproved
            ? '✅ Đã duyệt cho ${req.childName} thêm ${req.requestedMinutes} phút dùng máy!'
            : '❌ Đã từ chối yêu cầu xin thêm giờ của ${req.childName}.'),
        backgroundColor: isApproved ? AppTheme.accent : AppTheme.danger,
      ),
    );

    _loadTimeRequests();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final child = childrenProvider.selectedChild;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KidSafe - Giám Sát Trẻ Em'),
        elevation: 0,
        actions: [
          // Role switcher (Admin <-> Staff <-> Parent <-> Child)
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primary),
            tooltip: 'Chuyển đổi vai trò kiểm thử',
            onSelected: (role) {
              auth.switchRole(role);
              if (role == 'admin') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              } else if (role == 'staff') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StaffDashboardScreen()));
              } else if (role == 'child') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChildDeviceScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'admin', child: Text('👑 Chuyển sang Quản Trị Viên (Admin)')),
              const PopupMenuItem(value: 'staff', child: Text('🎧 Chuyển sang Nhân Viên Cứu Hộ (Staff)')),
              const PopupMenuItem(value: 'child', child: Text('📱 Chuyển sang Chế Độ Máy Bé (Child)')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            tooltip: 'Đăng xuất',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parent greeting card
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                  child: const Icon(Icons.family_restroom, color: AppTheme.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, ${auth.currentUser?.name ?? "Phụ Huynh"}! 👋',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Hệ thống đang bảo vệ các bé an toàn',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Quét QR', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Children selector list (CRUD Read & Select)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh Sách Trẻ Em',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildFormScreen()));
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm Bé Mới', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...childrenProvider.children.map((c) {
                    final isSelected = child?.id == c.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () {
                          childrenProvider.selectChild(c);
                          Provider.of<GeofenceProvider>(context, listen: false).loadGeofences(c.id);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isSelected ? Colors.white24 : AppTheme.primary.withOpacity(0.1),
                                child: Icon(
                                  c.gender == 'female' ? Icons.face_3_rounded : Icons.face_rounded,
                                  size: 18,
                                  color: isSelected ? Colors.white : (c.gender == 'female' ? Colors.pink : AppTheme.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isSelected ? Colors.white : AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    '${c.age} tuổi • ${c.batteryLevel}% Pin',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected ? Colors.white70 : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Alert Banner nếu phát hiện tiếng ồn nguy hiểm từ máy của bé
            if (child != null && child.currentNoiseDb >= 80)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.danger, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.danger.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_rounded, color: AppTheme.danger, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CẢNH BÁO TIẾNG ỒN TỪ MÁY ${child.name.toUpperCase()}!',
                            style: const TextStyle(
                              color: AppTheme.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Phát hiện độ ồn ${child.currentNoiseDb.toStringAsFixed(1)} dB (La hét / Va chạm mạnh)!',
                            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChildDetailScreen(child: child)),
                        );
                      },
                      child: const Text('Xem Ngay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Pending Time Extension Requests (Duyệt yêu cầu xin thêm giờ từ Bé theo sơ đồ kiến trúc)
            if (_pendingTimeRequests.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alarm_add_rounded, color: Color(0xFFD97706), size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Yêu Cầu Xin Thêm Giờ Từ Bé',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_pendingTimeRequests.length} yêu cầu',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._pendingTimeRequests.map((req) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${req.childName} xin thêm +${req.requestedMinutes} phút',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                                  ),
                                  Text(
                                    req.createdAt.isNotEmpty && req.createdAt.length >= 5 ? req.createdAt.substring(req.createdAt.length - 5) : 'Vừa xong',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lý do: "${req.reason}"',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.danger,
                                      side: const BorderSide(color: AppTheme.danger),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () => _reviewRequest(req, false),
                                    child: const Text('Từ chối', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () => _reviewRequest(req, true),
                                    child: Text('Đồng ý (+${req.requestedMinutes}p)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

            // Live Selected Child Status Card (Telemetry)
            if (child != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                            const Icon(Icons.sensors_rounded, color: AppTheme.accent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Trạng Thái: ${child.name}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChildDetailScreen(child: child)),
                            );
                          },
                          child: const Row(
                            children: [
                              Text('Chi tiết', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildStatusItem(Icons.battery_5_bar_rounded, '${child.batteryLevel}%', 'Pin máy', AppTheme.accent)),
                        Expanded(
                          child: _buildStatusItem(
                            Icons.volume_up_rounded,
                            '${child.currentNoiseDb.toStringAsFixed(0)} dB',
                            child.currentNoiseDb >= 80 ? '⚠️ Cảnh báo ồn' : 'Độ ồn quanh bé',
                            child.currentNoiseDb >= 80 ? AppTheme.danger : (child.currentNoiseDb >= 68 ? AppTheme.warning : AppTheme.primary),
                          ),
                        ),
                        Expanded(child: _buildStatusItem(Icons.location_on_rounded, 'Quận 1, TP.HCM', 'Vị trí hiện tại', AppTheme.secondary)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Thời gian dùng máy:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text(
                          '${child.usedScreenMinutes} / ${child.dailyScreenLimitMinutes} phút',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: child.screenTimeProgress,
                        minHeight: 8,
                        backgroundColor: AppTheme.bgLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          child.isScreenTimeExceeded ? AppTheme.danger : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // 8 Core Action Feature Grid
            const Text(
              'Chức Năng & Tiện Ích Giám Sát',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.15,
              children: [
                // 1. Chia sẻ vị trí & Bản đồ (Requirement 5.b)
                _buildActionCard(
                  title: 'Bản Đồ Vị Trí',
                  desc: 'GPS & Chia sẻ tọa độ',
                  badge: 'Đã thuyết trình',
                  icon: Icons.map_rounded,
                  color: AppTheme.primary,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationMapScreen()));
                  },
                ),

                // 2. Đo tiếng ồn môi trường (Requirement 5.d)
                _buildActionCard(
                  title: 'Đo Tiếng Ồn',
                  desc: 'Biểu đồ Decibel (dB)',
                  badge: 'Đã thuyết trình',
                  icon: Icons.graphic_eq_rounded,
                  color: AppTheme.secondary,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NoiseMeterScreen()));
                  },
                ),

                // 3. Quét mã QR ghép nối (Requirement 5.e)
                _buildActionCard(
                  title: 'Quét Mã QR',
                  desc: 'Nhận diện & ghép đôi',
                  badge: 'Đã thuyết trình',
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppTheme.purple,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
                  },
                ),

                // 4. Tạo mã QR thiết bị (Requirement 5.e)
                _buildActionCard(
                  title: 'Tạo Mã QR',
                  desc: 'Mã định danh bé',
                  badge: 'Tạo mã QR',
                  icon: Icons.qr_code_2_rounded,
                  color: Colors.teal,
                  onTap: () {
                    if (child != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => QRGeneratorScreen(child: child)));
                    }
                  },
                ),

                // 5. Vùng an toàn Geofencing (CRUD)
                _buildActionCard(
                  title: 'Vùng An Toàn',
                  desc: 'Quản lý Geofencing (CRUD)',
                  badge: 'CRUD 5.5đ',
                  icon: Icons.verified_user_rounded,
                  color: AppTheme.accent,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GeofenceListScreen()));
                  },
                ),

                // 6. Giới hạn giờ sử dụng (CRUD)
                _buildActionCard(
                  title: 'Lịch Biểu & Khóa App',
                  desc: 'Quản lý Screen Time (CRUD)',
                  badge: 'CRUD 5.5đ',
                  icon: Icons.alarm_on_rounded,
                  color: AppTheme.warning,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleListScreen()));
                  },
                ),

                // 7. Danh bạ an toàn (CRUD)
                _buildActionCard(
                  title: 'Danh Bạ An Toàn',
                  desc: 'Whitelist & Gọi SOS (CRUD)',
                  badge: 'CRUD 5.5đ',
                  icon: Icons.contact_phone_rounded,
                  color: const Color(0xFF0284C7),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactListScreen()));
                  },
                ),

                // 8. Tính năng mới lạ độc quyền (Requirement 6)
                _buildActionCard(
                  title: 'Lá Chắn AI & SOS',
                  desc: 'Acoustic Shield độc quyền',
                  badge: 'Mới lạ 1đ',
                  icon: Icons.psychology_rounded,
                  color: const Color(0xFFE11D48),
                  isSpecial: true,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AIAcousticShieldScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Demo Child Device Switcher Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android_rounded, color: AppTheme.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xem Thử Giao Diện Máy Bé',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
                        ),
                        Text(
                          'Mở giao diện được thiết kế riêng cho điện thoại của trẻ em',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildDeviceScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text('Mở Thử', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String desc,
    required String badge,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSpecial ? color.withOpacity(0.5) : AppTheme.cardBorder,
            width: isSpecial ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSpecial ? color.withOpacity(0.12) : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
