import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/schedule_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';

class ScheduleFormScreen extends StatefulWidget {
  final ScheduleModel? schedule;

  const ScheduleFormScreen({super.key, this.schedule});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _blockApps;

  final Map<String, bool> _days = {
    'Mon': true,
    'Tue': true,
    'Wed': true,
    'Thu': true,
    'Fri': true,
    'Sat': false,
    'Sun': false,
  };

  bool get isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.schedule?.title ?? '');
    _blockApps = widget.schedule?.blockApps ?? true;

    if (widget.schedule != null) {
      final sParts = widget.schedule!.startTime.split(':');
      final eParts = widget.schedule!.endTime.split(':');
      _startTime = TimeOfDay(hour: int.tryParse(sParts[0]) ?? 19, minute: int.tryParse(sParts[1]) ?? 30);
      _endTime = TimeOfDay(hour: int.tryParse(eParts[0]) ?? 21, minute: int.tryParse(eParts[1]) ?? 0);

      for (var k in _days.keys) {
        _days[k] = widget.schedule!.days.contains(k);
      }
    } else {
      _startTime = const TimeOfDay(hour: 19, minute: 30);
      _endTime = const TimeOfDay(hour: 21, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(context: context, initialTime: _startTime);
    if (t != null) setState(() => _startTime = t);
  }

  Future<void> _pickEndTime() async {
    final t = await showTimePicker(context: context, initialTime: _endTime);
    if (t != null) setState(() => _endTime = t);
  }

  void _fillPreset(String title, TimeOfDay start, TimeOfDay end, bool allWeek) {
    setState(() {
      _titleController.text = title;
      _startTime = start;
      _endTime = end;
      for (var k in _days.keys) {
        _days[k] = allWeek ? true : (k != 'Sat' && k != 'Sun');
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final schProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final childId = childrenProvider.selectedChild?.id ?? 'ch_01';

    final selectedDays = _days.entries.where((e) => e.value).map((e) => e.key).join(',');
    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ngày áp dụng!'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    if (isEditing) {
      final updated = widget.schedule!.copyWith(
        title: _titleController.text.trim(),
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        days: selectedDays,
        blockApps: _blockApps,
      );
      await schProvider.updateSchedule(updated);
    } else {
      final newSch = ScheduleModel(
        id: '',
        childId: childId,
        title: _titleController.text.trim(),
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        days: selectedDays,
        blockApps: _blockApps,
      );
      await schProvider.addSchedule(newSch);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Đã cập nhật lịch biểu!' : 'Đã tạo lịch biểu giới hạn mới!'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Lịch Biểu' : 'Tạo Lịch Giới Hạn Mới (CRUD)'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Presets quick-fill
              const Text('Chọn mẫu lịch thường dùng:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.menu_book, size: 14, color: AppTheme.primary),
                    label: const Text('Học Bài Tối (19:30 - 21:00)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _fillPreset('Giờ Học Bài Tối', const TimeOfDay(hour: 19, minute: 30), const TimeOfDay(hour: 21, minute: 0), false),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.bedtime, size: 14, color: Colors.purple),
                    label: const Text('Giờ Đi Ngủ (22:00 - 06:30)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _fillPreset('Giờ Đi Ngủ', const TimeOfDay(hour: 22, minute: 0), const TimeOfDay(hour: 6, minute: 30), true),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tiêu đề quy tắc
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên lịch biểu *',
                  hintText: 'VD: Giờ Học Bài, Giờ Ngủ Trưa',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên lịch biểu' : null,
              ),
              const SizedBox(height: 20),

              // Time Pickers (Bắt đầu & Kết thúc)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartTime,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Giờ bắt đầu', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text(_formatTime(_startTime), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndTime,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Giờ kết thúc', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text(_formatTime(_endTime), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Days of week selector
              const Text('Ngày áp dụng trong tuần:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDayChip('T2', 'Mon'),
                  _buildDayChip('T3', 'Tue'),
                  _buildDayChip('T4', 'Wed'),
                  _buildDayChip('T5', 'Thu'),
                  _buildDayChip('T6', 'Fri'),
                  _buildDayChip('T7', 'Sat'),
                  _buildDayChip('CN', 'Sun'),
                ],
              ),
              const SizedBox(height: 20),

              // Block apps toggle
              Card(
                child: SwitchListTile(
                  value: _blockApps,
                  activeColor: AppTheme.primary,
                  title: const Text('Khóa ứng dụng giải trí', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Chỉ cho phép gọi điện thoại và ứng dụng từ điển/học tập', style: TextStyle(fontSize: 12)),
                  onChanged: (val) => setState(() => _blockApps = val),
                ),
              ),
              const SizedBox(height: 32),

              // Nút Lưu
              ElevatedButton.icon(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  isEditing ? 'Lưu Thay Đổi' : 'Tạo Lịch Biểu Mới',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, String key) {
    final isSelected = _days[key] ?? false;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primary.withOpacity(0.2),
      checkmarkColor: AppTheme.primary,
      onSelected: (val) {
        setState(() => _days[key] = val);
      },
    );
  }
}
