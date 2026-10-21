import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyUser = 'kidsafe_user';
  static const String _keyToken = 'kidsafe_token';
  static const String _keyUseBackend = 'kidsafe_use_backend';

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    if (user.token != null) {
      await prefs.setString(_keyToken, user.token!);
    }
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_keyUser);
    if (userStr != null) {
      try {
        return UserModel.fromJson(jsonDecode(userStr));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyToken);
  }

  static Future<bool> isUsingBackend() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseBackend) ?? false;
  }

  static Future<void> setUseBackend(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseBackend, value);
  }
}
