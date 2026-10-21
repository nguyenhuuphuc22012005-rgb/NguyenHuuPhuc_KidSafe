import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sos_ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sos_provider.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../child/child_device_screen.dart';
import '../features/location_map_screen.dart';
import '../parent/parent_home_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  String _selectedStatus = 'all';

  void _showResolveDialog(SOSTicketModel ticket) {
    final noteController = TextEditingController(text: 'Đã liên hệ phụ huynh và xác nhận bé an toàn.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Giải Quyết Ca Cứu Hộ An Toàn', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ca khẩn cấp: ${ticket.childName}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Lý do: ${ticket.reason}', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú xử lý ca an toàn *',
                hintText: 'Nhập tóm tắt kết quả xử lý...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () {
              final sos = Provider.of<SOSProvider>(context, listen: false);
              sos.updateTicketStatus(
                ticket.id,
                'resolved',
                staffId: 'usr_staff_01',
                notes: noteController.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đánh dấu ca cứu hộ ĐÃ GIẢI QUYẾT AN TOÀN!'),
                  backgroundColor: AppTheme.accent,
                ),
              );
            },
            child: const Text('Xác Nhận Giải Quyết'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final sos = Provider.of<SOSProvider>(context);

    final tickets = sos.tickets.where((t) {
      if (_selectedStatus == 'all') return true;
      return t.status == _selectedStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung Tâm Cứu Hộ & An Toàn (Staff)'),
        elevation: 0,
        actions: [
          // Switch Role
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primary),
            tooltip: 'Chuyển đổi vai trò kiểm thử',
            onSelected: (role) {
              auth.switchRole(role);
              if (role == 'admin') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              } else if (role == 'parent') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentHomeScreen()));
              } else if (role == 'child') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChildDeviceScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'parent', child: Text('👤 Chuyển sang Phụ Huynh')),
              const PopupMenuItem(value: 'admin', child: Text('👑 Chuyển sang Admin')),
              const PopupMenuItem(value: 'child', child: Text('📱 Chuyển sang Máy Bé')),
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
      body: Column(
        children: [
          // Operator Status Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFFF0FDF4),
                  child: Icon(Icons.headset_mic_rounded, color: AppTheme.accent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            auth.currentUser?.name ?? 'Chuyên Viên Cứu Hộ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, color: Color(0xFF16A34A), size: 8),
                                SizedBox(width: 4),
                                Text(
                                  'Đang trực tuyến',
                                  style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tổng đài khẩn cấp 24/7 • Giám sát vị trí & tiếng ồn trẻ em',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text('Tất cả (${sos.tickets.length})'),
                    selected: _selectedStatus == 'all',
                    onSelected: (_) => setState(() => _selectedStatus = 'all'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.danger),
                    label: Text('Chờ xử lý (${sos.pendingTickets.length})'),
                    selected: _selectedStatus == 'pending',
                    selectedColor: const Color(0xFFFEE2E2),
                    onSelected: (_) => setState(() => _selectedStatus = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: const Icon(Icons.pending_actions_rounded, size: 14, color: AppTheme.warning),
                    label: Text('Đang ứng cứu (${sos.inProgressTickets.length})'),
                    selected: _selectedStatus == 'in_progress',
                    selectedColor: const Color(0xFFFEF3C7),
                    onSelected: (_) => setState(() => _selectedStatus = 'in_progress'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.accent),
                    label: Text('Đã an toàn (${sos.resolvedTickets.length})'),
                    selected: _selectedStatus == 'resolved',
                    selectedColor: const Color(0xFFDCFCE7),
                    onSelected: (_) => setState(() => _selectedStatus = 'resolved'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Tickets List
          Expanded(
            child: tickets.isEmpty
                ? const Center(
                    child: Text('Không có ca cảnh báo nào trong mục này', style: TextStyle(color: AppTheme.textMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final t = tickets[index];

                      Color badgeColor;
                      Color badgeBg;
                      if (t.isPending) {
                        badgeColor = AppTheme.danger;
                        badgeBg = const Color(0xFFFEE2E2);
                      } else if (t.isInProgress) {
                        badgeColor = AppTheme.warning;
                        badgeBg = const Color(0xFFFEF3C7);
                      } else {
                        badgeColor = AppTheme.accent;
                        badgeBg = const Color(0xFFDCFCE7);
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: t.isPending ? AppTheme.danger.withOpacity(0.5) : AppTheme.cardBorder,
                            width: t.isPending ? 1.5 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: badgeBg,
                                    child: Icon(
                                      t.isPending ? Icons.warning_rounded : (t.isInProgress ? Icons.run_circle_outlined : Icons.check_circle_rounded),
                                      color: badgeColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.childName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          'Phụ huynh: ${t.parentName ?? "N/A"} • ${t.parentPhone ?? ""}',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      t.statusDisplay,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: badgeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Reason & Noise badge
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            t.reason,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (t.noiseLevel > 0) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.volume_up_rounded, size: 16, color: AppTheme.danger),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Cường độ âm thanh đo được: ${t.noiseLevel.toStringAsFixed(1)} dB (Ngưỡng nguy hiểm)',
                                            style: const TextStyle(fontSize: 12, color: AppTheme.danger, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              if (t.resolutionNotes != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Ghi chú xử lý: ${t.resolutionNotes}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.accent, fontStyle: FontStyle.italic),
                                ),
                              ],

                              const SizedBox(height: 12),

                              // Action Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LocationMapScreen()),
                                      );
                                    },
                                    icon: const Icon(Icons.map_outlined, size: 16),
                                    label: const Text('Xem Bản Đồ'),
                                  ),
                                  const SizedBox(width: 8),
                                  if (t.isPending)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        sos.updateTicketStatus(t.id, 'in_progress', staffId: 'usr_staff_01');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Đã nhận xử lý ca cứu hộ!'), backgroundColor: AppTheme.warning),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
                                      icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
                                      label: const Text('Tiếp Nhận Ca'),
                                    ),
                                  if (t.isInProgress)
                                    ElevatedButton.icon(
                                      onPressed: () => _showResolveDialog(t),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Giải Quyết Ca'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
