import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact_model.dart';
import '../../providers/children_provider.dart';
import '../../providers/contact_provider.dart';
import '../../theme/app_theme.dart';

class ContactFormScreen extends StatefulWidget {
  final ContactModel? contact;

  const ContactFormScreen({super.key, this.contact});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _relationship;
  late bool _isSosContact;

  bool get isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _relationship = widget.contact?.relationship ?? 'Bố';
    _isSosContact = widget.contact?.isSosContact ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final childId = childrenProvider.selectedChild?.id ?? 'ch_01';

    if (isEditing) {
      final updated = widget.contact!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        relationship: _relationship,
        isSosContact: _isSosContact,
      );
      await contactProvider.updateContact(updated);
    } else {
      final newCon = ContactModel(
        id: '',
        childId: childId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        relationship: _relationship,
        isSosContact: _isSosContact,
      );
      await contactProvider.addContact(newCon);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Đã cập nhật danh bạ!' : 'Đã thêm liên hệ an toàn mới!'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Liên Hệ' : 'Thêm Danh Bạ An Toàn (CRUD)'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên người liên hệ *',
                  hintText: 'VD: Bố, Mẹ, Cô giáo chủ nhiệm',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại *',
                  hintText: 'VD: 0988776655 hoặc 113',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _relationship,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Mối quan hệ *',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Bố', child: Text('Bố')),
                  DropdownMenuItem(value: 'Mẹ', child: Text('Mẹ')),
                  DropdownMenuItem(value: 'Ông/Bà', child: Text('Ông / Bà')),
                  DropdownMenuItem(value: 'Giáo viên', child: Text('Thầy / Cô giáo chủ nhiệm')),
                  DropdownMenuItem(value: 'Người thân', child: Text('Người thân / Anh chị')),
                  DropdownMenuItem(value: 'Khẩn cấp', child: Text('Cảnh sát / Cứu thương')),
                ],
                onChanged: (val) => setState(() => _relationship = val ?? 'Bố'),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  value: _isSosContact,
                  activeColor: AppTheme.danger,
                  title: const Text('Đặt làm số điện thoại SOS khẩn cấp', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Hiển thị nút gọi nhanh trên màn hình khóa khi bé bấm SOS', style: TextStyle(fontSize: 12)),
                  onChanged: (val) => setState(() => _isSosContact = val),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  isEditing ? 'Lưu Thay Đổi' : 'Thêm Vào Danh Bạ An Toàn',
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
