import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/mock_data_service.dart';
import '../../theme/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final MockDataService _mock = MockDataService();
  String _selectedRoleFilter = 'all';
  String _searchQuery = '';

  List<UserModel> get _filteredUsers {
    return _mock.users.where((u) {
      final matchesRole = _selectedRoleFilter == 'all' || u.role == _selectedRoleFilter;
      final matchesSearch = u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String role = 'parent';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm Người Dùng Mới', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Phân quyền *'),
                  items: const [
                    DropdownMenuItem(value: 'parent', child: Text('Phụ huynh (Khách hàng)')),
                    DropdownMenuItem(value: 'staff', child: Text('Nhân viên cứu hộ (Staff)')),
                    DropdownMenuItem(value: 'admin', child: Text('Quản trị viên (Admin)')),
                  ],
                  onChanged: (val) => setDialogState(() => role = val ?? 'parent'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) return;
                setState(() {
                  _mock.createUser(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    role: role,
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm người dùng thành công!'), backgroundColor: AppTheme.accent),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    String role = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Sửa Thông Tin Người Dùng', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Phân quyền'),
                  items: const [
                    DropdownMenuItem(value: 'parent', child: Text('Phụ huynh (Khách hàng)')),
                    DropdownMenuItem(value: 'staff', child: Text('Nhân viên cứu hộ (Staff)')),
                    DropdownMenuItem(value: 'admin', child: Text('Quản trị viên (Admin)')),
                  ],
                  onChanged: (val) => setDialogState(() => role = val ?? 'parent'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _mock.updateUser(
                    user.id,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    role: role,
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật người dùng!'), backgroundColor: AppTheme.accent),
                );
              },
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài khoản?'),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản "${user.name}" (${user.email}) khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              setState(() {
                _mock.deleteUser(user.id);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa người dùng khỏi hệ thống'), backgroundColor: AppTheme.danger),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'staff':
        return AppTheme.secondary;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Người Dùng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppTheme.primary),
            tooltip: 'Thêm người dùng',
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc email...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppTheme.bgLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _selectedRoleFilter == 'all',
                        onSelected: (_) => setState(() => _selectedRoleFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Phụ huynh'),
                        selected: _selectedRoleFilter == 'parent',
                        onSelected: (_) => setState(() => _selectedRoleFilter = 'parent'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Nhân viên (Staff)'),
                        selected: _selectedRoleFilter == 'staff',
                        onSelected: (_) => setState(() => _selectedRoleFilter = 'staff'),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Admin'),
                        selected: _selectedRoleFilter == 'admin',
                        onSelected: (_) => setState(() => _selectedRoleFilter = 'admin'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: users.isEmpty
                ? const Center(
                    child: Text('Không tìm thấy người dùng nào phù hợp', style: TextStyle(color: AppTheme.textMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      final roleColor = _getRoleColor(u.role);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppTheme.cardBorder),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: roleColor.withOpacity(0.15),
                                child: Icon(
                                  u.role == 'admin'
                                      ? Icons.admin_panel_settings_rounded
                                      : (u.role == 'staff' ? Icons.support_agent_rounded : Icons.family_restroom_rounded),
                                  color: roleColor,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            u.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: roleColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: roleColor.withOpacity(0.35)),
                                          ),
                                          child: Text(
                                            u.roleDisplay,
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      u.email,
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (u.phone != null && u.phone!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        'SĐT: ${u.phone}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.secondary),
                                    tooltip: 'Chỉnh sửa',
                                    onPressed: () => _showEditUserDialog(u),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                                    tooltip: 'Xóa tài khoản',
                                    onPressed: () => _confirmDelete(u),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm Người Dùng', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
