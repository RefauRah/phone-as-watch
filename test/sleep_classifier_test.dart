import 'package:flutter_test/flutter_test.dart';
import 'package:phone_as_watch/features/sleep/dsp/sleep_classifier.dart';

void main() {
  group('SleepClassifier & Sonar Tests', () {
    test('Classifies near-zero bed motion as Deep Sleep', () {
      final classifier = SleepClassifier();

      // Simulate 30 motion samples of motionless bed
      for (int i = 0; i < 30; i++) {
        classifier.addMotionSample(0.01, 0.02, 9.81);
        classifier.addAudioSample(-52.0, i * 1000);
      }

      final epoch = classifier.classifyCurrentEpoch(DateTime.now());
      expect(epoch.stage, equals(SleepStage.deepSleep));
      expect(epoch.snoreDetected, isFalse);
    });

    test('Classifies vigorous bed motion as Awake', () {
      final classifier = SleepClassifier();

      for (int i = 0; i < 30; i++) {
        // High variance motion simulating tossing & turning
        final double zMotion = (i % 2 == 0) ? 14.0 : 6.0;
        classifier.addMotionSample(1.5, 1.0, zMotion);
        classifier.addAudioSample(-38.0, i * 1000);
      }

      final epoch = classifier.classifyCurrentEpoch(DateTime.now());
      expect(epoch.stage, equals(SleepStage.awake));
    });

    test('Detects rhythmic snoring pattern from acoustic bursts', () {
      final classifier = SleepClassifier();

      // Snore burst 1 at t = 1000ms
      classifier.addAudioSample(-25.0, 1000);
      // Snore burst 2 at t = 4000ms (delta = 3000ms, typical respiratory cycle)
      classifier.addAudioSample(-24.0, 4000);

      expect(classifier.totalSnoresDetected, equals(1));
    });
  });
}
