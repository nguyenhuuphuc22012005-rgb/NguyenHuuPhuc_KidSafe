import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingEmail;
  String? _suggestedOtp;
  String _deliveryMethod = 'email'; // 'email' hoặc 'sms'
  String? _deliveryMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get pendingEmail => _pendingEmail;
  String? get suggestedOtp => _suggestedOtp;
  String get deliveryMethod => _deliveryMethod;
  String? get deliveryMessage => _deliveryMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    _currentUser = await StorageService.getUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password, {String deliveryMethod = 'email'}) async {
    _isLoading = true;
    _errorMessage = null;
    _deliveryMethod = deliveryMethod;
    notifyListeners();

    try {
      final res = await _api.login(email, password, deliveryMethod: deliveryMethod);
      _pendingEmail = res['email'] ?? email;
      _suggestedOtp = res['otp'] ?? '123456';
      _deliveryMessage = res['message'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp({String? deliveryMethod}) async {
    if (_pendingEmail == null) return false;
    _isLoading = true;
    if (deliveryMethod != null) _deliveryMethod = deliveryMethod;
    notifyListeners();

    try {
      final res = await _api.resendOTP(_pendingEmail!, deliveryMethod: _deliveryMethod);
      _suggestedOtp = res['otp'] ?? '123456';
      _deliveryMessage = res['message'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otp, {String? email}) async {
    final targetEmail = email ?? _pendingEmail ?? 'nguyenhuuphuc22012005@gmail.com';
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _api.verifyOTP(targetEmail, otp);
      if (user != null) {
        _currentUser = user;
        await StorageService.saveUser(user);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Mã OTP không hợp lệ!';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'parent',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _api.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _pendingEmail = null;
    _suggestedOtp = null;
    await StorageService.clearUser();
    notifyListeners();
  }

  /// Nút chuyển đổi vai trò nhanh để thuyết trình và chấm điểm (Admin <-> Staff <-> Parent <-> Child)
  void switchRole(String role) {
    if (_currentUser == null) {
      _currentUser = UserModel(
        id: 'usr_demo',
        name: 'Người dùng Demo ($role)',
        email: '$role@kidsafe.vn',
        role: role,
      );
    } else {
      _currentUser = _currentUser!.copyWith(
        role: role,
        name: role == 'admin' 
            ? 'Quản Trị Viên (Admin)' 
            : (role == 'staff' ? 'Chuyên Viên Cứu Hộ (Staff)' : (role == 'child' ? 'Bé Bo (Child)' : 'Nguyễn Hữu Phúc (Parent)')),
      );
    }
    StorageService.saveUser(_currentUser!);
    notifyListeners();
  }
}
