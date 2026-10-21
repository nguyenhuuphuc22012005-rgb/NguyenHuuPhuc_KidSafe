import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../services/api_service.dart';

class ChildrenProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ChildModel> _children = [];
  ChildModel? _selectedChild;
  bool _isLoading = false;

  List<ChildModel> get children => _children;
  ChildModel? get selectedChild => _selectedChild;
  bool get isLoading => _isLoading;

  ChildrenProvider() {
    loadChildren();
  }

  Future<void> loadChildren({String? parentId}) async {
    _isLoading = true;
    notifyListeners();

    _children = await _api.getChildren(parentId: parentId);
    if (_children.isNotEmpty) {
      if (_selectedChild == null || !_children.any((c) => c.id == _selectedChild!.id)) {
        _selectedChild = _children.first;
      } else {
        _selectedChild = _children.firstWhere((c) => c.id == _selectedChild!.id);
      }
    } else {
      _selectedChild = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectChild(ChildModel child) {
    _selectedChild = child;
    notifyListeners();
  }

  Future<ChildModel> addChild({
    required String parentId,
    required String name,
    required int age,
    String gender = 'male',
    String? phone,
    String avatar = 'avatar_boy_1',
    int dailyLimitMinutes = 180,
  }) async {
    final newChild = await _api.createChild(
      parentId: parentId,
      name: name,
      age: age,
      gender: gender,
      phone: phone,
      avatar: avatar,
      dailyLimitMinutes: dailyLimitMinutes,
    );
    await loadChildren(parentId: parentId);
    _selectedChild = newChild;
    notifyListeners();
    return newChild;
  }

  Future<void> updateChild(ChildModel child) async {
    await _api.updateChild(child);
    final idx = _children.indexWhere((c) => c.id == child.id);
    if (idx != -1) {
      _children[idx] = child;
      if (_selectedChild?.id == child.id) {
        _selectedChild = child;
      }
      notifyListeners();
    }
  }

  Future<void> deleteChild(String id) async {
    await _api.deleteChild(id);
    _children.removeWhere((c) => c.id == id);
    if (_selectedChild?.id == id) {
      _selectedChild = _children.isNotEmpty ? _children.first : null;
    }
    notifyListeners();
  }

  /// Ghép nối thiết bị qua quét mã QR (Gửi lên Web API & SQL Server)
  Future<bool> pairWithDeviceId(String deviceId, String name) async {
    final paired = await _api.pairDevice(
      parentId: 'usr_parent_01',
      deviceId: deviceId,
      name: name,
    );

    if (paired != null) {
      final existingIdx = _children.indexWhere((c) => c.id == paired.id || c.deviceId == deviceId);
      if (existingIdx != -1) {
        _children[existingIdx] = paired;
      } else {
        _children.add(paired);
      }
      _selectedChild = paired;
      notifyListeners();
      return true;
    }

    final existingIdx = _children.indexWhere((c) => c.deviceId == deviceId);
    if (existingIdx != -1) {
      _selectedChild = _children[existingIdx];
      notifyListeners();
      return true;
    }

    // Nếu là thiết bị mới thì thêm vào danh sách
    final newChild = await addChild(
      parentId: 'usr_parent_01',
      name: name.isNotEmpty ? name : 'Thiết bị trẻ em ($deviceId)',
      age: 7,
      avatar: 'avatar_boy_1',
    );
    _selectedChild = newChild;
    notifyListeners();
    return true;
  }

  void updateLocation(double lat, double lng) {
    if (_selectedChild != null) {
      _selectedChild = _selectedChild!.copyWith(
        latitude: lat,
        longitude: lng,
        lastSeen: 'Vừa xong',
      );
      updateChild(_selectedChild!);
    }
  }

  void updateChildNoise(String childId, double db, {String status = 'Normal'}) {
    final idx = _children.indexWhere((c) => c.id == childId);
    if (idx != -1) {
      _children[idx] = _children[idx].copyWith(currentNoiseDb: db);
    }
    if (_selectedChild?.id == childId) {
      _selectedChild = _selectedChild!.copyWith(currentNoiseDb: db);
    }
    notifyListeners();
    _api.reportChildNoise(childId: childId, decibel: db, status: status);
  }

  void updateNoiseDb(double db) {
    if (_selectedChild != null) {
      updateChildNoise(_selectedChild!.id, db);
    }
  }

  void extendScreenTime(String childId, int extraMinutes) {
    final idx = _children.indexWhere((c) => c.id == childId);
    if (idx != -1) {
      final updatedLimit = _children[idx].dailyScreenLimitMinutes + extraMinutes;
      _children[idx] = _children[idx].copyWith(dailyScreenLimitMinutes: updatedLimit);
    }
    if (_selectedChild?.id == childId) {
      final updatedLimit = _selectedChild!.dailyScreenLimitMinutes + extraMinutes;
      _selectedChild = _selectedChild!.copyWith(dailyScreenLimitMinutes: updatedLimit);
    }
    notifyListeners();
  }
}
