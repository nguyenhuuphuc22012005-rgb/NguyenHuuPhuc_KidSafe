import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'parent';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      role: _selectedRole,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký tài khoản thành công! Vui lòng đăng nhập.'),
          backgroundColor: AppTheme.accent,
        ),
      );
      Navigator.pop(context);
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tạo Tài Khoản Mới',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Đăng ký tài khoản để quản lý và bảo vệ trẻ em an toàn',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Họ và tên
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập email';
                        if (!val.contains('@') || !val.contains('.')) return 'Email không đúng định dạng';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Số điện thoại
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vai trò (Chỉ cho phép Phụ Huynh hoặc Con)
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Vai trò người dùng *',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'parent',
                          child: Row(
                            children: [
                              Icon(Icons.family_restroom, size: 18, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text('Phụ Huynh (Quản lý & Giám sát)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'child',
                          child: Row(
                            children: [
                              Icon(Icons.child_care, size: 18, color: AppTheme.accent),
                              SizedBox(width: 8),
                              Text('Trẻ Em / Con (Thiết bị của con)'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val ?? 'parent'),
                    ),
                    const SizedBox(height: 16),

                    // Mật khẩu
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu *',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.length < 6) return 'Mật khẩu phải từ 6 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Xác nhận mật khẩu
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Xác nhận mật khẩu *',
                        prefixIcon: Icon(Icons.lock_reset_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val != _passwordController.text) return 'Mật khẩu xác nhận không khớp';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Nút Đăng ký
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primary,
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Hoàn Tất Đăng Ký',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
