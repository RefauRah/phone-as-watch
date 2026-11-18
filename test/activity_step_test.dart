import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_as_watch/features/activity/dsp/step_detector.dart';

void main() {
  group('Pedometer StepDetector DSP Tests', () {
    test('Detects rhythmic footsteps with Euclidean vector magnitude and adaptive thresholding', () {
      final detector = StepDetector();

      const double fs = 50.0; // 50 Hz accelerometer sampling
      const double stepCadenceHz = 1.8; // ~108 steps per minute
      const int durationSec = 10;
      final int totalSamples = (durationSec * fs).toInt();

      int detectedSteps = 0;

      for (int i = 0; i < totalSamples; i++) {
        final double t = i / fs;
        final int timestampMs = (t * 1000).toInt();

        // Synthetic walking step: peak acceleration of ~3.5 m/s^2 along vertical Z axis
        final double zVal = 3.5 * math.max(0.0, math.sin(2 * math.pi * stepCadenceHz * t));
        final double xVal = 0.5 * math.sin(2 * math.pi * (stepCadenceHz / 2) * t);
        const double yVal = 0.2;

        final event = detector.processAccelerometerSample(xVal, yVal, zVal, timestampMs);
        if (event != null) {
          detectedSteps = event.stepCount;
        }
      }

      // In 10s at 1.8 Hz, expect ~15-18 steps (minus hysteresis lead-in)
      expect(detectedSteps, greaterThanOrEqualTo(10));
      expect(detectedSteps, lessThanOrEqualTo(20));
    });

    test('Rejects idle noise below minimum acceleration threshold', () {
      final detector = StepDetector();

      // Micro-tremors < 1.0 m/s^2 should never increment steps
      for (int i = 0; i < 200; i++) {
        final int timestampMs = i * 20;
        final event = detector.processAccelerometerSample(0.1, 0.2, 0.15, timestampMs);
        expect(event, isNull);
      }

      expect(detector.currentStepCount, equals(0));
    });
  });
}
