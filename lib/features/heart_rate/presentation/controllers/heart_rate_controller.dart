import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../dsp/ppg_signal_processor.dart';
import '../../services/camera_ppg_service.dart';

class HeartRateController extends ChangeNotifier {
  final CameraPpgService _service = CameraPpgService();
  StreamSubscription<PpgProcessingResult>? _subscription;

  // Waveform buffer for live drawing
  final List<double> _waveformBuffer = List<double>.filled(100, 0.0, growable: true);
  List<double> get waveformBuffer => List.unmodifiable(_waveformBuffer);

  bool _isMeasuring = false;
  bool get isMeasuring => _isMeasuring;

  bool _isFingerDetected = false;
  bool get isFingerDetected => _isFingerDetected;

  bool _isPeak = false;
  bool get isPeak => _isPeak;

  double? _currentBpm;
  double? get currentBpm => _currentBpm;

  double? _hrvRmssd;
  double? get hrvRmssd => _hrvRmssd;

  double _measurementProgress = 0.0;
  double get measurementProgress => _measurementProgress;

  bool _isMeasurementComplete = false;
  bool get isMeasurementComplete => _isMeasurementComplete;

  // Last confirmed reading stored on dashboard
  double? _lastConfirmedBpm = 72.0;
  double? get lastConfirmedBpm => _lastConfirmedBpm;

  double? _lastConfirmedHrv = 45.0;
  double? get lastConfirmedHrv => _lastConfirmedHrv;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CameraPpgService get service => _service;

  Future<void> startMeasurement() async {
    _errorMessage = null;
    _isMeasuring = true;
    _measurementProgress = 0.0;
    _isMeasurementComplete = false;
    _waveformBuffer.fillRange(0, _waveformBuffer.length, 0.0);
    notifyListeners();

    try {
      await _service.initialize();
      await _service.startMeasurement();

      _subscription?.cancel();
      _subscription = _service.resultStream.listen((result) {
        _onNewResult(result);
      }, onError: (e) {
        _errorMessage = "Camera sensor error: $e";
        _isMeasuring = false;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = "Could not initialize camera: $e";
      _isMeasuring = false;
      notifyListeners();
    }
  }

  void _onNewResult(PpgProcessingResult result) {
    _isFingerDetected = result.isFingerDetected;
    _isPeak = result.isPeak;

    // Shift waveform buffer
    _waveformBuffer.add(result.filteredValue);
    if (_waveformBuffer.length > 100) {
      _waveformBuffer.removeAt(0);
    }

    if (result.isFingerDetected) {
      _measurementProgress = (result.measurementDurationSec / 15.0).clamp(0.0, 1.0);

      if (result.currentBpm != null) {
        _currentBpm = result.currentBpm;
      }

      if (result.hrvRmssd != null) {
        _hrvRmssd = result.hrvRmssd;
      }

      if (result.isMeasurementComplete && !_isMeasurementComplete) {
        _isMeasurementComplete = true;
        if (_currentBpm != null) _lastConfirmedBpm = _currentBpm;
        if (_hrvRmssd != null) _lastConfirmedHrv = _hrvRmssd;
      }
    } else {
      _measurementProgress = 0.0;
    }

    notifyListeners();
  }

  Future<void> stopMeasurement() async {
    _isMeasuring = false;
    await _subscription?.cancel();
    _subscription = null;
    await _service.stopMeasurement();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
