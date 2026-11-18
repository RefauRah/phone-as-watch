import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../dsp/step_detector.dart';

/// Combined state for real-time motion and elevation metrics
class ActivityMetrics {
  final int steps;
  final double cadenceSpm;
  final double floorsClimbed;
  final double currentPressureHpa;
  final double relativeAltitudeMeters;
  final double distanceKm;
  final double caloriesKcal;

  const ActivityMetrics({
    required this.steps,
    required this.cadenceSpm,
    required this.floorsClimbed,
    required this.currentPressureHpa,
    required this.relativeAltitudeMeters,
    required this.distanceKm,
    required this.caloriesKcal,
  });

  factory ActivityMetrics.initial() {
    return const ActivityMetrics(
      steps: 0,
      cadenceSpm: 0.0,
      floorsClimbed: 0.0,
      currentPressureHpa: 1013.25,
      relativeAltitudeMeters: 0.0,
      distanceKm: 0.0,
      caloriesKcal: 0.0,
    );
  }
}

/// Service managing sensors_plus accelerometer and barometer streams
class ActivityTrackerService {
  final StepDetector _stepDetector = StepDetector();

  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<BarometerEvent>? _baroSubscription;

  final StreamController<ActivityMetrics> _metricsController =
      StreamController<ActivityMetrics>.broadcast();

  Stream<ActivityMetrics> get metricsStream => _metricsController.stream;

  // Barometer variables
  double? _baselinePressureHpa;
  double _filteredPressureHpa = 1013.25;
  double _accumulatedFloors = 0.0;
  double _recentCadence = 0.0;

  // Standard architectural stair ascent constant: ~0.36 hPa drop per floor (~3.0 meters)
  static const double _hpaPerFloor = 0.36;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;

    // 1. Listen to Triaxial User Accelerometer (gravity-compensated)
    _accelSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      final int nowMs = DateTime.now().millisecondsSinceEpoch;
      final stepEvent = _stepDetector.processAccelerometerSample(
        event.x,
        event.y,
        event.z,
        nowMs,
      );

      if (stepEvent != null) {
        _recentCadence = stepEvent.cadenceSpm;
        _emitUpdatedMetrics();
      }
    });

    // 2. Listen to Atmospheric Barometer
    _baroSubscription = barometerEventStream().listen((BarometerEvent event) {
      _processBarometerSample(event.pressure);
    }, onError: (_) {
      // Barometer not available on some specific phone hardware
    });
  }

  void _processBarometerSample(double rawHpa) {
    if (_baselinePressureHpa == null) {
      _baselinePressureHpa = rawHpa;
      _filteredPressureHpa = rawHpa;
      return;
    }

    // Exponential Moving Average to smooth out barometer sensor jitter
    _filteredPressureHpa = (0.05 * rawHpa) + (0.95 * _filteredPressureHpa);

    // Negative pressure differential implies ascending altitude
    final double deltaPressure = _baselinePressureHpa! - _filteredPressureHpa;

    // Hypsometric elevation conversion: Δh ≈ -ΔP / (0.12 hPa/m)
    final double relativeAltitude = deltaPressure * 8.33;

    // When pressure decreases by threshold (e.g., 0.36 hPa) and user is walking
    if (deltaPressure >= _hpaPerFloor) {
      final double newFloors = deltaPressure / _hpaPerFloor;
      _accumulatedFloors += newFloors;
      // Advance baseline reference to avoid double-counting
      _baselinePressureHpa = _filteredPressureHpa;
    } else if (deltaPressure <= -_hpaPerFloor) {
      // User descended stairs or elevator
      _baselinePressureHpa = _filteredPressureHpa;
    }

    _emitUpdatedMetrics(relativeAltitude: relativeAltitude);
  }

  void _emitUpdatedMetrics({double? relativeAltitude}) {
    final int steps = _stepDetector.currentStepCount;
    // Standard stride length: ~0.762 meters per step
    final double distanceKm = (steps * 0.762) / 1000.0;
    // Calorie estimation: ~0.045 kcal per walking step + 3.2 kcal per floor climbed
    final double calories = (steps * 0.045) + (_accumulatedFloors * 3.2);

    final double altitude = relativeAltitude ??
        (_baselinePressureHpa != null
            ? (_baselinePressureHpa! - _filteredPressureHpa) * 8.33
            : 0.0);

    final metrics = ActivityMetrics(
      steps: steps,
      cadenceSpm: _recentCadence,
      floorsClimbed: _accumulatedFloors,
      currentPressureHpa: _filteredPressureHpa,
      relativeAltitudeMeters: altitude,
      distanceKm: distanceKm,
      caloriesKcal: calories,
    );

    if (!_metricsController.isClosed) {
      _metricsController.add(metrics);
    }
  }

  void stopTracking() {
    _isTracking = false;
    _accelSubscription?.cancel();
    _baroSubscription?.cancel();
    _accelSubscription = null;
    _baroSubscription = null;
  }

  void reset() {
    _stepDetector.reset();
    _baselinePressureHpa = null;
    _accumulatedFloors = 0.0;
    _recentCadence = 0.0;
    _emitUpdatedMetrics();
  }

  void dispose() {
    stopTracking();
    _metricsController.close();
  }
}
