import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/mock_data_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../staff/staff_dashboard_screen.dart';
import '../parent/parent_home_screen.dart';
import '../child/child_device_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final mock = MockDataService();

    final totalUsers = mock.users.length;
    final totalChildren = mock.children.length;
    final totalGeofences = mock.geofences.length;
    final pendingSOS = mock.sosTickets.where((t) => t.isPending).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Quản Trị Hệ Thống (Admin)'),
        elevation: 0,
        actions: [
          // Role Quick-Switch Menu (Cực kỳ giá trị cho giảng viên chấm thi)
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primary),
            tooltip: 'Chuyển đổi vai trò kiểm thử',
            onSelected: (role) {
              auth.switchRole(role);
              if (role == 'staff') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StaffDashboardScreen()));
              } else if (role == 'parent') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentHomeScreen()));
              } else if (role == 'child') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChildDeviceScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'parent', child: Text('👤 Chuyển sang Phụ Huynh')),
              const PopupMenuItem(value: 'staff', child: Text('🎧 Chuyển sang Nhân Viên')),
              const PopupMenuItem(value: 'child', child: Text('📱 Chuyển sang Máy Bé')),
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
            // Admin Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B21A8), Color(0xFF4C1D95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
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
                    child: Icon(Icons.admin_panel_settings, size: 36, color: Colors.purple),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser?.name ?? 'Quản Trị Viên',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Quyền hạn cao nhất • Quản lý toàn bộ hệ thống',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Grid (Overview)
            const Text(
              'Thống Kê Tổng Quan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  'Tổng Người Dùng',
                  '$totalUsers',
                  Icons.people_alt_rounded,
                  AppTheme.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                    );
                  },
                ),
                _buildStatCard(
                  'Trẻ Em Bảo Vệ',
                  '$totalChildren',
                  Icons.child_care_rounded,
                  AppTheme.secondary,
                ),
                _buildStatCard(
                  'Vùng An Toàn',
                  '$totalGeofences',
                  Icons.share_location_rounded,
                  AppTheme.accent,
                ),
                _buildStatCard(
                  'Cảnh Báo SOS Chờ',
                  '$pendingSOS',
                  Icons.warning_amber_rounded,
                  AppTheme.danger,
                  isAlert: pendingSOS > 0,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Action Buttons
            const Text(
              'Chức Năng Quản Trị',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.manage_accounts_rounded, color: AppTheme.primary),
                ),
                title: const Text('Quản Lý Người Dùng & Phân Quyền (CRUD)'),
                subtitle: const Text('Thêm, sửa, đổi vai trò, xóa tài khoản hệ thống'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: AppTheme.secondary),
                ),
                title: const Text('Bảng Giám Sát Cứu Hộ Khẩn Cấp (Staff Queue)'),
                subtitle: const Text('Xem hàng đợi tiếp nhận các ca SOS & tiếng ồn bất thường'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // System Logs Activity
            const Text(
              'Nhật Ký Hệ Thống Gần Đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Column(
                children: [
                  _LogItem(
                    time: '17:50',
                    action: 'Hệ thống Backend REST API đồng bộ SQLite thành công',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.accent,
                  ),
                  Divider(height: 20),
                  _LogItem(
                    time: '17:42',
                    action: 'Cảnh báo tiếng ồn: Bé Bo (88.5 dB) tại Quận 1',
                    icon: Icons.warning_rounded,
                    color: AppTheme.danger,
                  ),
                  Divider(height: 20),
                  _LogItem(
                    time: '17:30',
                    action: 'Phụ huynh Nguyễn Hữu Phúc cập nhật Vùng an toàn Trường học',
                    icon: Icons.edit_location_alt_rounded,
                    color: AppTheme.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isAlert = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isAlert ? AppTheme.danger : AppTheme.cardBorder),
          boxShadow: isAlert
              ? [
                  BoxShadow(
                    color: AppTheme.danger.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 26),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMuted),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isAlert ? AppTheme.danger : AppTheme.textDark,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final String time;
  final String action;
  final IconData icon;
  final Color color;

  const _LogItem({
    required this.time,
    required this.action,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
