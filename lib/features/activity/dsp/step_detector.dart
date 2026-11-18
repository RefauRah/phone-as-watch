import 'dart:collection';
import 'dart:math' as math;

/// Output event generated when a valid human walking step is confirmed
class StepEvent {
  final int stepCount;
  final double cadenceSpm; // Steps per minute
  final double instantaneousMagnitude;
  final int timestampMs;

  const StepEvent({
    required this.stepCount,
    required this.cadenceSpm,
    required this.instantaneousMagnitude,
    required this.timestampMs,
  });
}

/// DSP Step Detection Engine using dynamic acceleration magnitude,
/// lowpass smoothing, adaptive thresholding, and temporal refractory gating.
class StepDetector {
  // Low-pass filter smoothing coefficient (EMA: fc ≈ 3 Hz at 50 Hz sampling)
  static const double _filterAlpha = 0.32;
  double _smoothedMagnitude = 0.0;

  // 3-point peak detector buffer
  double _s0 = 0.0;
  double _s1 = 0.0;
  double _s2 = 0.0;

  // Adaptive threshold window
  final Queue<double> _magnitudeHistory = Queue<double>();
  static const int _historyWindowSize = 50; // ~1 second of samples

  // Step state tracking
  int _stepCount = 0;
  int? _lastStepTimeMs;

  // Minimum refractory duration between steps: 280 ms (max ~214 steps/min)
  static const int _minStepIntervalMs = 280;
  // Maximum step interval: 2000 ms (min ~30 steps/min)
  static const int _maxStepIntervalMs = 2000;

  // Hysteresis buffer to reject accidental phone jostles
  int _consecutiveSteps = 0;
  static const int _hysteresisThreshold = 3;

  int get currentStepCount => _stepCount;

  /// Ingests triaxial user acceleration (m/s^2 without gravity)
  StepEvent? processAccelerometerSample(double x, double y, double z, int timestampMs) {
    // 1. Calculate dynamic Euclidean acceleration vector magnitude
    final double rawMagnitude = math.sqrt(x * x + y * y + z * z);

    // 2. Low-Pass Filter (EMA) to attenuate high-frequency phone tremor
    _smoothedMagnitude = (_filterAlpha * rawMagnitude) + ((1.0 - _filterAlpha) * _smoothedMagnitude);

    // 3. Shift 3-sample window for local peak detection
    _s2 = _s1;
    _s1 = _s0;
    _s0 = _smoothedMagnitude;

    // 4. Update adaptive threshold window
    _magnitudeHistory.addLast(_smoothedMagnitude);
    if (_magnitudeHistory.length > _historyWindowSize) {
      _magnitudeHistory.removeFirst();
    }

    // Compute dynamic threshold (Mean + 0.5 * StdDev)
    double mean = 0.0;
    double stdDev = 0.0;
    if (_magnitudeHistory.length >= 20) {
      final double sum = _magnitudeHistory.reduce((a, b) => a + b);
      mean = sum / _magnitudeHistory.length;
      final double variance = _magnitudeHistory
              .map((v) => math.pow(v - mean, 2))
              .reduce((a, b) => a + b) /
          _magnitudeHistory.length;
      stdDev = math.sqrt(variance);
    }

    // Minimum physical acceleration threshold for human walking: 1.6 m/s^2
    final double dynamicThreshold = math.max(1.6, mean + (0.5 * stdDev));

    // 5. Peak Detection condition
    final bool isLocalMax = (_s1 > _s2) && (_s1 >= _s0);
    final bool exceedsThreshold = _s1 > dynamicThreshold;

    if (isLocalMax && exceedsThreshold) {
      final int timeSinceLastStep = _lastStepTimeMs == null ? 9999 : (timestampMs - _lastStepTimeMs!);

      if (timeSinceLastStep >= _minStepIntervalMs) {
        if (timeSinceLastStep <= _maxStepIntervalMs) {
          _consecutiveSteps++;
        } else {
          // Walking paused
          _consecutiveSteps = 1;
        }

        _lastStepTimeMs = timestampMs;

        // Confirm step once cadence rhythm is established
        if (_consecutiveSteps >= _hysteresisThreshold) {
          _stepCount++;

          final double intervalSec = timeSinceLastStep / 1000.0;
          final double spm = (intervalSec > 0 && intervalSec < 2.5) ? (60.0 / intervalSec) : 100.0;

          return StepEvent(
            stepCount: _stepCount,
            cadenceSpm: spm.clamp(40.0, 220.0),
            instantaneousMagnitude: _s1,
            timestampMs: timestampMs,
          );
        }
      }
    }

    return null;
  }

  void reset() {
    _stepCount = 0;
    _consecutiveSteps = 0;
    _lastStepTimeMs = null;
    _smoothedMagnitude = 0.0;
    _s0 = 0.0;
    _s1 = 0.0;
    _s2 = 0.0;
    _magnitudeHistory.clear();
  }
}
