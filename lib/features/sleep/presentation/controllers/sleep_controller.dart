import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../dsp/sleep_classifier.dart';
import '../../services/sleep_tracker_service.dart';

class SleepController extends ChangeNotifier {
  final SleepTrackerService _service = SleepTrackerService();
  StreamSubscription<SleepSessionState>? _subscription;

  SleepSessionState _sessionState = SleepSessionState.initial();
  SleepSessionState get sessionState => _sessionState;

  bool get isTracking => _sessionState.isTracking;

  SleepController() {
    _populateDemoHistoryIfEmpty();
  }

  void _populateDemoHistoryIfEmpty() {
    // Generate a realistic last-night sleep log for the dashboard preview.
    final DateTime now = DateTime.now();
    final DateTime sleepEnd =
        now.hour >= 8 ? DateTime(now.year, now.month, now.day, 7) : now;

    const List<SleepStage> stages = [
      SleepStage.awake,
      SleepStage.lightSleep,
      SleepStage.lightSleep,
      SleepStage.deepSleep,
      SleepStage.deepSleep,
      SleepStage.deepSleep,
      SleepStage.lightSleep,
      SleepStage.lightSleep,
      SleepStage.deepSleep,
      SleepStage.deepSleep,
      SleepStage.lightSleep,
      SleepStage.lightSleep,
      SleepStage.deepSleep,
      SleepStage.lightSleep,
      SleepStage.awake,
    ];
    const Set<int> snoreEpochs = {2, 3, 8, 11};
    const Set<int> deepEpochs = {3, 4, 5, 8, 9, 12};
    const Set<int> awakeEpochs = {0, 14};

    final List<SleepEpoch> mockEpochs = <SleepEpoch>[];
    for (int i = 0; i < stages.length; i++) {
      mockEpochs.add(
        SleepEpoch(
          timestamp: sleepEnd.subtract(
            Duration(minutes: (stages.length - i) * 30),
          ),
          stage: stages[i],
          motionVariance: deepEpochs.contains(i)
              ? 0.001
              : awakeEpochs.contains(i)
                  ? 0.031
                  : 0.006,
          averageAudioDb: snoreEpochs.contains(i) ? -28.0 : -44.0,
          snoreDetected: snoreEpochs.contains(i),
        ),
      );
    }

    _sessionState = SleepSessionState(
      isTracking: false,
      startTime: sleepEnd.subtract(const Duration(hours: 7, minutes: 30)),
      elapsedDuration: const Duration(hours: 7, minutes: 30),
      awakeDuration: const Duration(hours: 1),
      lightSleepDuration: const Duration(hours: 3, minutes: 30),
      deepSleepDuration: const Duration(hours: 3),
      snoreEpisodes: snoreEpochs.length,
      qualityScore: 88,
      currentStage: SleepStage.awake,
      epochHistory: mockEpochs,
    );
  }

  Future<void> startTracking() async {
    await _service.startSleepTracking();

    _subscription?.cancel();
    _subscription = _service.stateStream.listen((state) {
      _sessionState = state;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> stopTracking() async {
    await _service.stopSleepTracking();
    _subscription?.cancel();
    _subscription = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
