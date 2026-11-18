import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/activity_tracker_service.dart';

class ActivityController extends ChangeNotifier {
  final ActivityTrackerService _service = ActivityTrackerService();
  StreamSubscription<ActivityMetrics>? _subscription;

  ActivityMetrics _metrics = ActivityMetrics.initial();
  ActivityMetrics get metrics => _metrics;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  // Daily target goals (smartwatch standards)
  final int stepGoal = 10000;
  final double floorGoal = 10.0;
  final double calorieGoal = 400.0;

  double get stepProgress => (_metrics.steps / stepGoal).clamp(0.0, 1.0);
  double get floorProgress => (_metrics.floorsClimbed / floorGoal).clamp(0.0, 1.0);
  double get calorieProgress => (_metrics.caloriesKcal / calorieGoal).clamp(0.0, 1.0);

  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;

    _service.startTracking();
    _subscription = _service.metricsStream.listen((data) {
      _metrics = data;
      notifyListeners();
    });

    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    _subscription?.cancel();
    _subscription = null;
    _service.stopTracking();
    notifyListeners();
  }

  void resetMetrics() {
    _service.reset();
    _metrics = ActivityMetrics.initial();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
