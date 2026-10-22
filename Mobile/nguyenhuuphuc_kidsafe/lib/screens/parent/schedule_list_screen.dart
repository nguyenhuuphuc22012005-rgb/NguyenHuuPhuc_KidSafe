import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/schedule_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import 'schedule_form_screen.dart';

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childId = Provider.of<ChildrenProvider>(context, listen: false).selectedChild?.id ?? 'ch_01';
      Provider.of<ScheduleProvider>(context, listen: false).loadSchedules(childId);
    });
  }

  void _confirmDelete(BuildContext context, ScheduleModel sch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa lịch biểu?'),
        content: Text('Bạn có chắc muốn xóa lịch biểu "${sch.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              final schProvider = Provider.of<ScheduleProvider>(context, listen: false);
              schProvider.deleteSchedule(sch.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa lịch biểu!'), backgroundColor: AppTheme.danger),
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
    final schProvider = Provider.of<ScheduleProvider>(context);
    final child = childrenProvider.selectedChild;

    final schedules = schProvider.schedules;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch Biểu Giới Hạn (${child?.name ?? "Bé"})'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm_rounded, color: AppTheme.primary),
            tooltip: 'Thêm lịch biểu mới',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleFormScreen()));
            },
          ),
        ],
      ),
      body: schedules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule_rounded, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text('Chưa có lịch biểu giới hạn nào', style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleFormScreen()));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo Lịch Biểu Đầu Tiên'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final sch = schedules[index];

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
                              backgroundColor: sch.isActive ? const Color(0xFFEEF2FF) : AppTheme.bgLight,
                              child: Icon(
                                Icons.access_time_filled_rounded,
                                color: sch.isActive ? AppTheme.primary : AppTheme.textMuted,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sch.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${sch.startTime} - ${sch.endTime}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: sch.isActive,
                              activeColor: AppTheme.primary,
                              onChanged: (val) {
                                schProvider.toggleSchedule(sch.id, val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      sch.daysDisplay,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                                    ),
                                  ),
                                  if (sch.blockApps)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.lock_clock, size: 12, color: AppTheme.warning),
                                          SizedBox(width: 4),
                                          Text('Khóa ứng dụng', style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
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
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleFormScreen(schedule: sch)));
                              },
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                              tooltip: 'Xóa',
                              onPressed: () => _confirmDelete(context, sch),
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleFormScreen()));
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm Lịch Biểu', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
