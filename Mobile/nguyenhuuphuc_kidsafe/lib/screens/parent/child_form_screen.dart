import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/child_model.dart';
import '../../providers/children_provider.dart';
import '../../theme/app_theme.dart';

class ChildFormScreen extends StatefulWidget {
  final ChildModel? child;

  const ChildFormScreen({super.key, this.child});

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _screenLimitController;
  late String _gender;
  late String _avatar;

  bool get isEditing => widget.child != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child?.name ?? '');
    _ageController = TextEditingController(text: widget.child != null ? widget.child!.age.toString() : '8');
    _phoneController = TextEditingController(text: widget.child?.phone ?? '');
    _screenLimitController = TextEditingController(
      text: widget.child != null ? widget.child!.dailyScreenLimitMinutes.toString() : '180',
    );
    _gender = widget.child?.gender ?? 'male';
    _avatar = widget.child?.avatar ?? 'avatar_boy_1';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _screenLimitController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final age = int.tryParse(_ageController.text.trim()) ?? 8;
    final limit = int.tryParse(_screenLimitController.text.trim()) ?? 180;

    if (isEditing) {
      final updated = widget.child!.copyWith(
        name: _nameController.text.trim(),
        age: age,
        gender: _gender,
        phone: _phoneController.text.trim(),
        avatar: _avatar,
        dailyScreenLimitMinutes: limit,
      );
      await childrenProvider.updateChild(updated);
    } else {
      await childrenProvider.addChild(
        parentId: 'usr_parent_01',
        name: _nameController.text.trim(),
        age: age,
        gender: _gender,
        phone: _phoneController.text.trim(),
        avatar: _avatar,
        dailyLimitMinutes: limit,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Đã cập nhật hồ sơ bé!' : 'Đã thêm bé mới thành công!'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Hồ Sơ Bé' : 'Thêm Bé Mới (CRUD)'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar selector
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Icon(
                        _gender == 'female' ? Icons.face_3_rounded : Icons.face_rounded,
                        size: 50,
                        color: _gender == 'female' ? Colors.pink : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Chọn giới tính & đại diện:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.boy, size: 18, color: AppTheme.primary),
                          label: const Text('Bé Trai'),
                          selected: _gender == 'male',
                          onSelected: (_) => setState(() => _gender = 'male'),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          avatar: const Icon(Icons.girl, size: 18, color: Colors.pink),
                          label: const Text('Bé Gái'),
                          selected: _gender == 'female',
                          onSelected: (_) => setState(() => _gender = 'female'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tên bé
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị của bé *',
                  hintText: 'VD: Bé Bo (Gia Bảo)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên bé' : null,
              ),
              const SizedBox(height: 16),

              // Tuổi & Số điện thoại
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tuổi *',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nhập tuổi' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại của bé',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Giới hạn thời gian dùng máy mỗi ngày
              TextFormField(
                controller: _screenLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giới hạn dùng máy mỗi ngày (Phút) *',
                  hintText: 'VD: 180 (3 tiếng)',
                  prefixIcon: Icon(Icons.timer_outlined),
                  suffixText: 'phút',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập số phút' : null,
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
                  isEditing ? 'Lưu Thay Đổi' : 'Thêm Thiết Bị Bé',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
