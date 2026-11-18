import 'dart:collection';
import 'dart:math' as math;
import 'biquad_filter.dart';

/// Data model representing the processed biometric output of a single PPG frame
class PpgProcessingResult {
  final double rawRed;
  final double filteredValue;
  final bool isFingerDetected;
  final bool isPeak;
  final double? currentBpm;
  final double? hrvRmssd;
  final double measurementDurationSec;
  final bool isMeasurementComplete;
  final double signalQuality; // 0.0 - 1.0

  const PpgProcessingResult({
    required this.rawRed,
    required this.filteredValue,
    required this.isFingerDetected,
    required this.isPeak,
    required this.currentBpm,
    required this.hrvRmssd,
    required this.measurementDurationSec,
    required this.isMeasurementComplete,
    required this.signalQuality,
  });
}

/// Digital Signal Processor (DSP) for Camera Photoplethysmography (PPG)
/// Implements bandpass filtering, adaptive peak detection, IBI estimation,
/// and Root Mean Square of Successive Differences (RMSSD) for HRV.
class PpgSignalProcessor {
  final double nominalSampleRate;
  late final PpgBandpassFilter _bandpassFilter;

  // Signal history for adaptive thresholding
  final Queue<double> _filterWindow = Queue<double>();
  static const int _windowSize = 45; // ~1.5 seconds at 30 FPS

  // 3-point peak detector buffer
  double _y0 = 0.0;
  double _y1 = 0.0;
  double _y2 = 0.0;

  // Timestamps
  int? _measurementStartTimeMs;
  int? _lastPeakTimeMs;
  int _lastFrameTimeMs = 0;

  // Inter-Beat Intervals (IBI) in milliseconds
  final List<double> _ibiHistory = <double>[];
  static const int _maxIbiHistory = 50;

  // Stability counters
  int _consecutiveFingerFrames = 0;
  static const int _fingerStabilityThreshold = 15;

  // Minimum refractory period: 270 ms corresponds to max 222 BPM
  static const int _minRefractoryPeriodMs = 270;
  // Maximum interval: 1500 ms corresponds to min 40 BPM
  static const int _maxBeatIntervalMs = 1500;

  PpgSignalProcessor({this.nominalSampleRate = 30.0}) {
    _bandpassFilter = PpgBandpassFilter(
      sampleRate: nominalSampleRate,
      lowCutoff: 0.7, // 42 BPM
      highCutoff: 3.5, // 210 BPM
    );
  }

  /// Processes one raw optical Red intensity sample from camera
  PpgProcessingResult processSample(double rawRed, int timestampMs) {
    if (_lastFrameTimeMs == 0) {
      _lastFrameTimeMs = timestampMs;
    }
    _lastFrameTimeMs = timestampMs;

    final bool fingerDetected = rawRed > 85.0;

    if (!fingerDetected) {
      _consecutiveFingerFrames = 0;
      _measurementStartTimeMs = null;
      _lastPeakTimeMs = null;
      _ibiHistory.clear();
      _filterWindow.clear();
      _bandpassFilter.reset();

      return PpgProcessingResult(
        rawRed: rawRed,
        filteredValue: 0.0,
        isFingerDetected: false,
        isPeak: false,
        currentBpm: null,
        hrvRmssd: null,
        measurementDurationSec: 0.0,
        isMeasurementComplete: false,
        signalQuality: 0.0,
      );
    }

    _consecutiveFingerFrames++;
    if (_measurementStartTimeMs == null && _consecutiveFingerFrames >= _fingerStabilityThreshold) {
      _measurementStartTimeMs = timestampMs;
    }

    // Step 1: Bandpass Filtering (0.7 Hz - 3.5 Hz)
    final double filtered = _bandpassFilter.process(rawRed);

    // Update 3-sample buffer for 2nd derivative / peak detection
    _y2 = _y1;
    _y1 = _y0;
    _y0 = filtered;

    // Maintain running window for adaptive threshold
    _filterWindow.addLast(filtered);
    if (_filterWindow.length > _windowSize) {
      _filterWindow.removeFirst();
    }

    // Step 2: Compute Adaptive Threshold (Mean + k * StdDev)
    double mean = 0.0;
    double stdDev = 0.0;
    if (_filterWindow.length >= 10) {
      final double sum = _filterWindow.reduce((a, b) => a + b);
      mean = sum / _filterWindow.length;
      final double variance = _filterWindow
              .map((v) => math.pow(v - mean, 2))
              .reduce((a, b) => a + b) /
          _filterWindow.length;
      stdDev = math.sqrt(variance);
    }
    final double adaptiveThreshold = mean + (0.35 * stdDev);

    // Step 3: Peak Detection with Refractory Period
    bool isPeak = false;
    final bool isLocalMax = (_y1 > _y2) && (_y1 >= _y0);
    final bool exceedsThreshold = _y1 > adaptiveThreshold && _y1 > 0.05;

    if (isLocalMax && exceedsThreshold) {
      final int timeSinceLastPeak = _lastPeakTimeMs == null ? 9999 : (timestampMs - _lastPeakTimeMs!);

      if (timeSinceLastPeak >= _minRefractoryPeriodMs) {
        if (_lastPeakTimeMs != null && timeSinceLastPeak <= _maxBeatIntervalMs) {
          final double ibiMs = timeSinceLastPeak.toDouble();
          _addIbi(ibiMs);
        }
        _lastPeakTimeMs = timestampMs;
        isPeak = true;
      }
    }

    // Step 4: Calculate BPM and HRV (RMSSD)
    final double? currentBpm = _calculateBpm();
    final double? hrvRmssd = _calculateHrvRmssd();

    final double elapsedSec = _measurementStartTimeMs == null
        ? 0.0
        : (timestampMs - _measurementStartTimeMs!) / 1000.0;

    final bool isComplete = elapsedSec >= 15.0 && _ibiHistory.length >= 8;

    // Signal quality based on standard deviation and stable rhythm
    final double signalQuality = (_consecutiveFingerFrames < _fingerStabilityThreshold)
        ? (_consecutiveFingerFrames / _fingerStabilityThreshold) * 0.4
        : (stdDev > 0.2 ? 1.0 : 0.6);

    return PpgProcessingResult(
      rawRed: rawRed,
      filteredValue: filtered,
      isFingerDetected: true,
      isPeak: isPeak,
      currentBpm: currentBpm,
      hrvRmssd: hrvRmssd,
      measurementDurationSec: elapsedSec,
      isMeasurementComplete: isComplete,
      signalQuality: signalQuality,
    );
  }

  void _addIbi(double ibiMs) {
    // Basic outlier check: within 30% of median if buffer has entries
    if (_ibiHistory.length >= 4) {
      final double med = _calculateMedian(List<double>.from(_ibiHistory));
      if ((ibiMs - med).abs() > med * 0.35) {
        return; // Discard ectopic beat or motion artifact
      }
    }

    _ibiHistory.add(ibiMs);
    if (_ibiHistory.length > _maxIbiHistory) {
      _ibiHistory.removeAt(0);
    }
  }

  double? _calculateBpm() {
    if (_ibiHistory.length < 3) return null;

    // Use recent IBIs (last 8 beats)
    final List<double> recent = _ibiHistory.sublist(math.max(0, _ibiHistory.length - 8));
    final double medianIbi = _calculateMedian(recent);

    if (medianIbi <= 0) return null;
    final double bpm = 60000.0 / medianIbi;
    return bpm.clamp(40.0, 210.0);
  }

  /// Calculates RMSSD (Root Mean Square of Successive Differences)
  /// RMSSD = sqrt( 1/(N-1) * sum((IBI_{i+1} - IBI_i)^2) )
  /// Standard clinical metric for Parasympathetic HRV in milliseconds
  double? _calculateHrvRmssd() {
    if (_ibiHistory.length < 5) return null;

    double sumSquaredDiffs = 0.0;
    int count = 0;

    for (int i = 0; i < _ibiHistory.length - 1; i++) {
      final double diff = _ibiHistory[i + 1] - _ibiHistory[i];
      sumSquaredDiffs += diff * diff;
      count++;
    }

    if (count == 0) return null;
    final double rmssd = math.sqrt(sumSquaredDiffs / count);
    return rmssd;
  }

  double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;
    final List<double> sorted = List<double>.from(values)..sort();
    final int middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
  }

  void reset() {
    _consecutiveFingerFrames = 0;
    _measurementStartTimeMs = null;
    _lastPeakTimeMs = null;
    _lastFrameTimeMs = 0;
    _ibiHistory.clear();
    _filterWindow.clear();
    _bandpassFilter.reset();
    _y0 = 0.0;
    _y1 = 0.0;
    _y2 = 0.0;
  }
}
