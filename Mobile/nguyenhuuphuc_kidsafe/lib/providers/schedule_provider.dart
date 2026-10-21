import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/api_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;

  Future<void> loadSchedules(String childId) async {
    _isLoading = true;
    notifyListeners();

    _schedules = await _api.getSchedules(childId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSchedule(ScheduleModel sch) async {
    final created = await _api.createSchedule(sch);
    _schedules.insert(0, created);
    notifyListeners();
  }

  Future<void> updateSchedule(ScheduleModel sch) async {
    await _api.updateSchedule(sch);
    final idx = _schedules.indexWhere((s) => s.id == sch.id);
    if (idx != -1) {
      _schedules[idx] = sch;
      notifyListeners();
    }
  }

  Future<void> toggleSchedule(String id, bool active) async {
    final idx = _schedules.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final updated = _schedules[idx].copyWith(isActive: active);
      await updateSchedule(updated);
    }
  }

  Future<void> deleteSchedule(String id) async {
    await _api.deleteSchedule(id);
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
