import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../staff/staff_dashboard_screen.dart';
import '../parent/parent_home_screen.dart';
import '../child/child_device_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String suggestedOtp;
  final String initialDeliveryMethod; // 'email' hoặc 'sms'
  final String? deliveryMessage;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.suggestedOtp,
    this.initialDeliveryMethod = 'email',
    this.deliveryMessage,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Bắt đầu với các ô trống để người dùng nhập mã nhận được từ Gmail
  }

  void _clearOtp() {
    for (int i = 0; i < 6; i++) {
      _controllers[i].clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    final otp = _enteredOtp;
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số mã OTP nhận được từ email!'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.verifyOtp(otp, email: widget.email);

    if (success && mounted) {
      final user = auth.currentUser;
      Widget targetScreen;

      // Phân quyền theo vai trò (Requirement #3)
      if (user?.isAdmin == true) {
        targetScreen = const AdminDashboardScreen();
      } else if (user?.isStaff == true) {
        targetScreen = const StaffDashboardScreen();
      } else if (user?.isChild == true) {
        targetScreen = const ChildDeviceScreen();
      } else {
        targetScreen = const ParentHomeScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
        (route) => false,
      );
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.resendOtp(deliveryMethod: 'email');
    if (success && mounted) {
      _startTimer();
      _clearOtp();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi lại mã OTP mới đến Gmail: ${widget.email}. Vui lòng kiểm tra hộp thư.'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác Thực Hai Lớp (OTP)'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Gmail chính thức
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        size: 40,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Kiểm Tra Hộp Thư Gmail',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Hộp hiển thị địa chỉ Email người nhận
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mail_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.email,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    'Hệ thống đã gửi một email chứa mã xác thực 6 chữ số đến địa chỉ Gmail của bạn. Vui lòng mở ứng dụng Gmail (kiểm tra cả Hộp thư đến và Thư mục Spam) và nhập mã vào các ô bên dưới:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 6 Ô NHẬP MÃ OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 48,
                        height: 58,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
                            ),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (val.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Xóa nhập lại
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _clearOtp,
                      icon: const Icon(Icons.backspace_outlined, size: 14, color: AppTheme.textMuted),
                      label: const Text('Xóa tất cả', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nút Xác Nhận
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFDC2626), // Màu đỏ Gmail
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Xác Nhận & Đăng Nhập',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.check_circle_outline, size: 18),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Gửi lại mã OTP
                  Center(
                    child: _secondsRemaining > 0
                        ? Text(
                            'Chưa nhận được email? Gửi lại sau $_secondsRemaining giây',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          )
                        : TextButton.icon(
                            onPressed: auth.isLoading ? null : _resendCode,
                            icon: const Icon(Icons.refresh, size: 18, color: Color(0xFFDC2626)),
                            label: const Text(
                              'Gửi lại mã OTP về Gmail',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Lưu ý bảo mật
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 18, color: Color(0xFFB45309)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lưu ý: Mã OTP có hiệu lực trong vòng 5 phút. Vui lòng không chia sẻ mã xác thực này cho bất kỳ ai để đảm bảo an toàn.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
