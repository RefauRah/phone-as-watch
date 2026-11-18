import 'dart:async';
import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../dsp/sleep_classifier.dart';

class SleepSessionState {
  final bool isTracking;
  final DateTime? startTime;
  final Duration elapsedDuration;
  final Duration awakeDuration;
  final Duration lightSleepDuration;
  final Duration deepSleepDuration;
  final int snoreEpisodes;
  final int qualityScore;
  final SleepStage currentStage;
  final List<SleepEpoch> epochHistory;

  const SleepSessionState({
    required this.isTracking,
    required this.startTime,
    required this.elapsedDuration,
    required this.awakeDuration,
    required this.lightSleepDuration,
    required this.deepSleepDuration,
    required this.snoreEpisodes,
    required this.qualityScore,
    required this.currentStage,
    required this.epochHistory,
  });

  factory SleepSessionState.initial() {
    return const SleepSessionState(
      isTracking: false,
      startTime: null,
      elapsedDuration: Duration.zero,
      awakeDuration: Duration.zero,
      lightSleepDuration: Duration.zero,
      deepSleepDuration: Duration.zero,
      snoreEpisodes: 0,
      qualityScore: 0,
      currentStage: SleepStage.awake,
      epochHistory: [],
    );
  }
}

/// Service managing bed actigraphy, microphone monitoring, and wake lock
class SleepTrackerService {
  final SleepClassifier _classifier = SleepClassifier();
  final AudioRecorder _audioRecorder = AudioRecorder();

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<Amplitude>? _audioSubscription;
  Timer? _epochTimer;
  Timer? _durationTimer;

  final StreamController<SleepSessionState> _stateController =
      StreamController<SleepSessionState>.broadcast();

  Stream<SleepSessionState> get stateStream => _stateController.stream;

  DateTime? _sessionStartTime;
  bool _isTracking = false;
  bool get isTracking => _isTracking;

  Duration _awakeDuration = Duration.zero;
  Duration _lightSleepDuration = Duration.zero;
  Duration _deepSleepDuration = Duration.zero;
  SleepStage _currentStage = SleepStage.awake;
  final List<SleepEpoch> _epochs = [];

  static const Duration _epochInterval = Duration(seconds: 15);

  Future<void> startSleepTracking() async {
    if (_isTracking) return;
    _isTracking = true;
    _sessionStartTime = DateTime.now();
    _epochs.clear();
    _awakeDuration = Duration.zero;
    _lightSleepDuration = Duration.zero;
    _deepSleepDuration = Duration.zero;
    _classifier.reset();

    // 1. Keep CPU and Sensors alive throughout the night
    try {
      await WakelockPlus.enable();
    } catch (_) {}

    // 2. High sensitivity Bed Actigraphy (mattress vibration)
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!_isTracking) return;
      _classifier.addMotionSample(event.x, event.y, event.z);
    });

    // 3. Audio / Snoring / Respiration monitoring
    try {
      final bool hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        // Start listening to microphone amplitude level stream
        _audioSubscription = _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 300))
            .listen((Amplitude amp) {
          final int nowMs = DateTime.now().millisecondsSinceEpoch;
          _classifier.addAudioSample(amp.current, nowMs);
        });
      }
    } catch (_) {
      // Audio fallback without crashing sleep actigraphy
    }

    // 4. Timer to evaluate 15-30s sleep epochs
    _epochTimer = Timer.periodic(_epochInterval, (_) => _processEpoch());

    // 5. Timer to update second-by-second elapsed time
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) => _emitCurrentState());

    _emitCurrentState();
  }

  void _processEpoch() {
    if (!_isTracking) return;

    final SleepEpoch epoch = _classifier.classifyCurrentEpoch(DateTime.now());
    _epochs.add(epoch);
    _currentStage = epoch.stage;

    switch (epoch.stage) {
      case SleepStage.awake:
        _awakeDuration += _epochInterval;
        break;
      case SleepStage.lightSleep:
        _lightSleepDuration += _epochInterval;
        break;
      case SleepStage.deepSleep:
        _deepSleepDuration += _epochInterval;
        break;
    }

    _emitCurrentState();
  }

  void _emitCurrentState() {
    final DateTime now = DateTime.now();
    final Duration elapsed = _sessionStartTime != null ? now.difference(_sessionStartTime!) : Duration.zero;

    final int score = SleepClassifier.calculateQualityScore(
      deepSleepDuration: _deepSleepDuration,
      lightSleepDuration: _lightSleepDuration,
      awakeDuration: _awakeDuration,
      snoreCount: _classifier.totalSnoresDetected,
    );

    final state = SleepSessionState(
      isTracking: _isTracking,
      startTime: _sessionStartTime,
      elapsedDuration: elapsed,
      awakeDuration: _awakeDuration,
      lightSleepDuration: _lightSleepDuration,
      deepSleepDuration: _deepSleepDuration,
      snoreEpisodes: _classifier.totalSnoresDetected,
      qualityScore: score,
      currentStage: _currentStage,
      epochHistory: List.unmodifiable(_epochs),
    );

    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  Future<void> stopSleepTracking() async {
    _isTracking = false;
    _accelSubscription?.cancel();
    _audioSubscription?.cancel();
    _epochTimer?.cancel();
    _durationTimer?.cancel();
    _accelSubscription = null;
    _audioSubscription = null;
    _epochTimer = null;
    _durationTimer = null;

    // Release wakelock when sleeping session concludes
    try {
      await WakelockPlus.disable();
    } catch (_) {}

    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (_) {}

    _emitCurrentState();
  }

  void dispose() {
    stopSleepTracking();
    _audioRecorder.dispose();
    _stateController.close();
  }
}
