import 'dart:math' as math;

enum SleepStage {
  awake,
  lightSleep,
  deepSleep,
}

/// Record of a classified 30-second sleep epoch
class SleepEpoch {
  final DateTime timestamp;
  final SleepStage stage;
  final double motionVariance;
  final double averageAudioDb;
  final bool snoreDetected;

  const SleepEpoch({
    required this.timestamp,
    required this.stage,
    required this.motionVariance,
    required this.averageAudioDb,
    required this.snoreDetected,
  });
}

/// Actigraphy and acoustic sensor-fusion classifier for sleep stages and snore episodes
class SleepClassifier {
  // Epoch window buffers (collects samples across ~30s epoch)
  final List<double> _epochMotionMagnitudes = [];
  final List<double> _epochAudioLevels = [];

  // Snoring pattern detector state
  int? _lastSnorePeakTimeMs;
  int _snoreCount = 0;

  int get totalSnoresDetected => _snoreCount;

  /// Ingests real-time bed accelerometer magnitude
  void addMotionSample(double x, double y, double z) {
    final double mag = math.sqrt(x * x + y * y + z * z);
    _epochMotionMagnitudes.add(mag);
  }

  /// Ingests real-time microphone amplitude in dBFS (e.g. -50 to 0)
  void addAudioSample(double dbFs, int timestampMs) {
    _epochAudioLevels.add(dbFs);

    // Snore heuristic: Loud acoustic burst (>-30 dBFS) spaced by 2.0s - 4.5s
    if (dbFs > -30.0) {
      if (_lastSnorePeakTimeMs != null) {
        final int deltaMs = timestampMs - _lastSnorePeakTimeMs!;
        if (deltaMs >= 2000 && deltaMs <= 4500) {
          // Periodic respiratory snore pulse confirmed
          _snoreCount++;
          _lastSnorePeakTimeMs = timestampMs;
          return;
        }
      }
      _lastSnorePeakTimeMs = timestampMs;
    }
  }

  /// Classifies the collected epoch and flushes buffers for next window
  SleepEpoch classifyCurrentEpoch(DateTime epochTime) {
    // 1. Compute Motion Energy & Variance from Bed Actigraphy
    double motionVariance = 0.0;
    if (_epochMotionMagnitudes.length >= 5) {
      final double meanMag =
          _epochMotionMagnitudes.reduce((a, b) => a + b) / _epochMotionMagnitudes.length;

      final double sumSqDiff = _epochMotionMagnitudes
          .map((m) => (m - meanMag) * (m - meanMag))
          .reduce((a, b) => a + b);

      motionVariance = sumSqDiff / _epochMotionMagnitudes.length;
    }

    // 2. Compute Mean Audio dBFS
    double meanDb = -60.0;
    if (_epochAudioLevels.isNotEmpty) {
      meanDb = _epochAudioLevels.reduce((a, b) => a + b) / _epochAudioLevels.length;
    }

    // 3. Sensor Fusion Sleep Staging Rule Engine:
    // - High motion variance (> 0.04) or loud wakeful noise (> -25 dB) -> Awake
    // - Moderate motion (0.003 - 0.04) -> Light Sleep / REM
    // - Near zero motion (< 0.003) -> Deep Sleep (muscular atonia)
    SleepStage stage;
    if (motionVariance > 0.04 || meanDb > -24.0) {
      stage = SleepStage.awake;
    } else if (motionVariance > 0.003) {
      stage = SleepStage.lightSleep;
    } else {
      stage = SleepStage.deepSleep;
    }

    final bool snoreInEpoch = _epochAudioLevels.any((db) => db > -28.0) && motionVariance < 0.02;

    _epochMotionMagnitudes.clear();
    _epochAudioLevels.clear();

    return SleepEpoch(
      timestamp: epochTime,
      stage: stage,
      motionVariance: motionVariance,
      averageAudioDb: meanDb,
      snoreDetected: snoreInEpoch,
    );
  }

  /// Calculates sleep quality score (0 - 100)
  static int calculateQualityScore({
    required Duration deepSleepDuration,
    required Duration lightSleepDuration,
    required Duration awakeDuration,
    required int snoreCount,
  }) {
    final int totalMinutes =
        deepSleepDuration.inMinutes + lightSleepDuration.inMinutes + awakeDuration.inMinutes;

    if (totalMinutes < 5) return 0;

    final double deepRatio = deepSleepDuration.inMinutes / totalMinutes;
    final double awakeRatio = awakeDuration.inMinutes / totalMinutes;

    // Ideal healthy sleep: 20-30% deep sleep, < 10% awake
    double score = (deepRatio * 180.0) + (1.0 - awakeRatio) * 40.0;

    // Penalty for excessive snoring
    score -= (snoreCount * 1.5);

    return score.round().clamp(10, 100);
  }

  void reset() {
    _epochMotionMagnitudes.clear();
    _epochAudioLevels.clear();
    _lastSnorePeakTimeMs = null;
    _snoreCount = 0;
  }
}
