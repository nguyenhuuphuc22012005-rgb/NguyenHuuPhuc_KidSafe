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

  static const String _keySchedules = 'kidsafe_schedules';
  static const String _keyContacts = 'kidsafe_contacts';
  static const String _keyTimeRequests = 'kidsafe_time_requests';
  static const String _keyServerUrl = 'kidsafe_server_url';

  static Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url);
  }

  static Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }

  static Future<void> saveSchedules(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySchedules, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>?> getSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keySchedules);
    if (str == null) return null;
    try {
      final List decoded = jsonDecode(str);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveContacts(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyContacts, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>?> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyContacts);
    if (str == null) return null;
    try {
      final List decoded = jsonDecode(str);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveTimeRequests(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTimeRequests, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>?> getTimeRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyTimeRequests);
    if (str == null) return null;
    try {
      final List decoded = jsonDecode(str);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }
}
