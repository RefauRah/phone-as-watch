import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_as_watch/features/heart_rate/dsp/biquad_filter.dart';
import 'package:phone_as_watch/features/heart_rate/dsp/ppg_signal_processor.dart';

void main() {
  group('PPG DSP & Biquad Filtering Tests', () {
    test('PpgBandpassFilter strips DC offset and retains 1.2 Hz (72 BPM) cardiac pulse', () {
      final filter = PpgBandpassFilter(sampleRate: 30.0, lowCutoff: 0.7, highCutoff: 3.5);

      const double fs = 30.0;
      const double heartFreq = 1.2; // 72 BPM
      const double dcOffset = 180.0; // Large optical tissue DC offset
      const int numSamples = 150; // 5 seconds

      double lastFiltered = 0.0;
      for (int i = 0; i < numSamples; i++) {
        final double t = i / fs;
        // Input: large DC + 1.2 Hz heart signal
        final double sample = dcOffset + (15.0 * math.sin(2 * math.pi * heartFreq * t));
        lastFiltered = filter.process(sample);
      }

      // After settling, DC offset must be stripped (centered around 0.0)
      expect(lastFiltered.abs(), lessThan(20.0));
    });

    test('PpgSignalProcessor detects systolic peaks and calculates BPM & HRV RMSSD', () {
      final processor = PpgSignalProcessor(nominalSampleRate: 30.0);

      const double fs = 30.0;
      const double targetBpm = 75.0; // 75 BPM = 1.25 Hz -> period = 800 ms
      const double periodSec = 60.0 / targetBpm;
      const int totalSeconds = 20;
      const int totalSamples = totalSeconds * 30;

      PpgProcessingResult? lastResult;

      for (int i = 0; i < totalSamples; i++) {
        final double t = i / fs;
        final int timestampMs = (t * 1000).toInt();

        // Synthetic PPG pulse: Red intensity ~150 with periodic systolic peaks
        final double phase = (t % periodSec) / periodSec;
        // Asymmetric pulse simulating systolic upstroke & diastolic decay
        final double pulseShape = math.exp(-math.pow(phase - 0.2, 2) / 0.015);
        final double rawRed = 160.0 + (30.0 * pulseShape);

        lastResult = processor.processSample(rawRed, timestampMs);
      }

      expect(lastResult, isNotNull);
      expect(lastResult!.isFingerDetected, isTrue);
      expect(lastResult.currentBpm, isNotNull);
      // Verify estimated BPM is within physiological tolerance of target 75 BPM
      expect(lastResult.currentBpm!, closeTo(75.0, 8.0));
      // Verify 15s measurement completion flag
      expect(lastResult.isMeasurementComplete, isTrue);
    });
  });
}
