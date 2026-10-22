import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/noise_log_model.dart';
import '../services/mock_data_service.dart';
import '../services/noise_service.dart';

class NoiseProvider extends ChangeNotifier {
  static const String _keyNoiseThreshold = 'kidsafe_noise_threshold';
  static const String _keyThresholdEnabled = 'kidsafe_noise_threshold_enabled';

  final NoiseService _noiseService = NoiseService();
  final MockDataService _mock = MockDataService();

  double _currentDecibel = 42.0;
  NoiseLevelCategory _category = NoiseLevelCategory.normal;
  bool _isMonitoring = false;
  bool _isAlertTriggered = false;
  String _alertMessage = '';

  // Ngưỡng cảnh báo do người dùng thiết lập (mặc định 75 dB)
  double _warningThreshold = 75.0;
  bool _isThresholdAlertEnabled = true;

  // AI Acoustic Shield Feature state
  bool _aiShieldEnabled = true;
  double _studyFocusScore = 92.0; // 0 - 100%

  double get currentDecibel => _currentDecibel;
  NoiseLevelCategory get category => _category;
  bool get isMonitoring => _isMonitoring;
  bool get isAlertTriggered => _isAlertTriggered;
  String get alertMessage => _alertMessage;
  double get warningThreshold => _warningThreshold;
  bool get isThresholdAlertEnabled => _isThresholdAlertEnabled;
  bool get aiShieldEnabled => _aiShieldEnabled;
  double get studyFocusScore => _studyFocusScore;
  bool get isRealMicrophone => _noiseService.isRealMicrophone;
  List<double> get waveform => _noiseService.waveformHistory;

  NoiseProvider() {
    _loadSettings();

    _noiseService.addListener((db, cat) {
      _currentDecibel = db;
      _category = cat;

      // Cập nhật điểm tập trung học tập
      if (db > 75) {
        _studyFocusScore = (_studyFocusScore - 2).clamp(30.0, 100.0);
      } else if (db < 50) {
        _studyFocusScore = (_studyFocusScore + 0.5).clamp(30.0, 100.0);
      }

      // Kiểm tra cảnh báo khi vượt ngưỡng thiết lập
      if (_isThresholdAlertEnabled && db >= _warningThreshold && !_isAlertTriggered) {
        _isAlertTriggered = true;
        _alertMessage = 'CẢNH BÁO TIẾNG ỒN: Mức âm thanh ${db.toStringAsFixed(1)} dB đã vượt ngưỡng bạn thiết lập (${_warningThreshold.toStringAsFixed(0)} dB)!';
        HapticFeedback.heavyImpact();

        // Tự động ghi nhật ký và tạo ticket cứu hộ nếu ở mức nguy hiểm
        _mock.addNoiseLog('ch_01', db, cat.name, 'Vượt ngưỡng thiết lập (${_warningThreshold.toStringAsFixed(0)} dB)');

        if (_aiShieldEnabled && db >= 85) {
          _mock.createSOSTicket(
            childId: 'ch_01',
            childName: 'Bé Bo (Gia Bảo)',
            latitude: 10.7769,
            longitude: 106.7009,
            noiseLevel: db,
            reason: 'Phát hiện tiếng ồn vượt ngưỡng cảnh báo (${db.toStringAsFixed(1)} dB >= ${_warningThreshold.toStringAsFixed(0)} dB)',
          );
        }
      }

      notifyListeners();
    });
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _warningThreshold = prefs.getDouble(_keyNoiseThreshold) ?? 75.0;
      _isThresholdAlertEnabled = prefs.getBool(_keyThresholdEnabled) ?? true;
      notifyListeners();
    } catch (_) {}
  }

  /// Thiết lập ngưỡng cảnh báo tiếng ồn (dB)
  Future<void> setWarningThreshold(double value) async {
    _warningThreshold = value.clamp(40.0, 110.0);
    // Nếu âm thanh hiện tại nhỏ hơn ngưỡng mới, tắt cảnh báo
    if (_currentDecibel < _warningThreshold) {
      _isAlertTriggered = false;
      _alertMessage = '';
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyNoiseThreshold, _warningThreshold);
    } catch (_) {}
  }

  /// Bật/tắt chế độ cảnh báo theo ngưỡng
  Future<void> toggleThresholdAlert(bool enabled) async {
    _isThresholdAlertEnabled = enabled;
    if (!enabled) {
      _isAlertTriggered = false;
      _alertMessage = '';
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyThresholdEnabled, _isThresholdAlertEnabled);
    } catch (_) {}
  }

  void startMonitoring() {
    _isMonitoring = true;
    _noiseService.startMonitoring();
    notifyListeners();
  }

  Future<bool> enableRealMicrophone() async {
    _isMonitoring = true;
    final res = await _noiseService.enableRealMicrophone();
    notifyListeners();
    return res;
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _noiseService.stopMonitoring();
    notifyListeners();
  }

  void setScenario(String scenario) {
    _noiseService.setScenario(scenario);
    notifyListeners();
  }

  void setManualDecibel(double value) {
    _noiseService.setManualDecibel(value);
    notifyListeners();
  }

  void dismissAlert() {
    _isAlertTriggered = false;
    _alertMessage = '';
    notifyListeners();
  }

  void toggleAiShield(bool enabled) {
    _aiShieldEnabled = enabled;
    notifyListeners();
  }

  List<NoiseLogModel> getLogs(String childId) {
    return _mock.getNoiseLogs(childId);
  }

  void addLog(String childId, String note) {
    _mock.addNoiseLog(childId, _currentDecibel, _category.name, note);
    notifyListeners();
  }
}
