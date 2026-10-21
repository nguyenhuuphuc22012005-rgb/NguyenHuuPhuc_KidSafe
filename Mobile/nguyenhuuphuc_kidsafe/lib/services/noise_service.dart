import 'dart:async';
import 'dart:math';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

enum NoiseLevelCategory {
  quiet,
  normal,
  loud,
  danger,
}

class NoiseService {
  static final NoiseService _instance = NoiseService._internal();
  factory NoiseService() => _instance;
  NoiseService._internal();

  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  Timer? _fallbackTimer;
  final Random _random = Random();

  double _currentDecibel = 38.0;
  double _targetDecibel = 38.0;
  bool _isMonitoring = false;
  bool _isRealMicrophone = false;
  final List<double> _waveformHistory = List.filled(30, 38.0);

  // Callback listeners
  final List<Function(double db, NoiseLevelCategory category)> _listeners = [];
  Function(double db)? onDangerDetected;

  double get currentDecibel => _currentDecibel;
  bool get isMonitoring => _isMonitoring;
  bool get isRealMicrophone => _isRealMicrophone;
  List<double> get waveformHistory => List.unmodifiable(_waveformHistory);

  NoiseLevelCategory get currentCategory {
    if (_currentDecibel >= 85.0) return NoiseLevelCategory.danger;
    if (_currentDecibel >= 68.0) return NoiseLevelCategory.loud;
    if (_currentDecibel >= 45.0) return NoiseLevelCategory.normal;
    return NoiseLevelCategory.quiet;
  }

  void addListener(Function(double db, NoiseLevelCategory category) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(double db, NoiseLevelCategory category) listener) {
    _listeners.remove(listener);
  }

  /// Khởi động đo tiếng ồn từ Micro thực tế của thiết bị
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // 1. Thử yêu cầu cấp quyền Micro trên điện thoại thật
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        _noiseMeter = NoiseMeter();
        _noiseSubscription = _noiseMeter!.noise.listen(
          (NoiseReading reading) {
            _onRealNoiseReading(reading);
          },
          onError: (Object error) {
            _startFallbackSimulation();
          },
          cancelOnError: false,
        );
        _isRealMicrophone = true;
        return;
      }
    } catch (_) {}

    // Fallback: Khi chạy trên desktop/máy ảo không có micro phần cứng
    _startFallbackSimulation();
  }

  void _onRealNoiseReading(NoiseReading reading) {
    _isRealMicrophone = true;
    double rawDb = reading.meanDecibel;
    if (!rawDb.isFinite || rawDb.isNaN) {
      rawDb = reading.maxDecibel;
    }
    if (!rawDb.isFinite || rawDb.isNaN) return;

    // Điều chỉnh giới hạn thang đo tiếng ồn môi trường thực tế (20 - 120 dB)
    final measuredDb = rawDb.clamp(20.0, 115.0);

    // Làm dịu tín hiệu âm thanh để giao diện phản hồi mượt mà
    _currentDecibel = (_currentDecibel * 0.35) + (measuredDb * 0.65);

    _waveformHistory.add(_currentDecibel);
    if (_waveformHistory.length > 30) {
      _waveformHistory.removeAt(0);
    }

    final cat = currentCategory;
    for (final listener in _listeners) {
      listener(_currentDecibel, cat);
    }

    if (_currentDecibel >= 85.0 && onDangerDetected != null) {
      onDangerDetected!(_currentDecibel);
    }
  }

  void _startFallbackSimulation() {
    _isRealMicrophone = false;
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      final jitter = (_random.nextDouble() - 0.5) * 3.5;
      _currentDecibel = (_currentDecibel * 0.7 + _targetDecibel * 0.3) + jitter;
      _currentDecibel = _currentDecibel.clamp(20.0, 110.0);

      _waveformHistory.add(_currentDecibel);
      if (_waveformHistory.length > 30) {
        _waveformHistory.removeAt(0);
      }

      final cat = currentCategory;
      for (final listener in _listeners) {
        listener(_currentDecibel, cat);
      }

      if (_currentDecibel >= 85.0 && onDangerDetected != null) {
        onDangerDetected!(_currentDecibel);
      }
    });
  }

  void stopMonitoring() {
    _noiseSubscription?.cancel();
    _noiseSubscription = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _isMonitoring = false;
  }

  void setScenario(String scenario) {
    switch (scenario) {
      case 'quiet':
        _targetDecibel = 32.0;
        break;
      case 'normal':
        _targetDecibel = 52.0;
        break;
      case 'loud':
        _targetDecibel = 76.0;
        break;
      case 'danger':
        _targetDecibel = 94.0;
        break;
      default:
        _targetDecibel = 45.0;
    }
  }

  void setManualDecibel(double value) {
    _targetDecibel = value;
    _currentDecibel = value;
  }
}
