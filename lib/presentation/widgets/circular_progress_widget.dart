import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'animated_counter.dart';

/// Apple-Watch-style three-ring activity indicator with animated sweep,
/// gradient strokes, trailing glow and a subtle outer tick track.
class TriRingProgressWidget extends StatelessWidget {
  final double stepProgress; // 0.0 - 1.0
  final double floorProgress;
  final double calorieProgress;
  final int currentSteps;
  final int stepGoal;

  const TriRingProgressWidget({
    super.key,
    required this.stepProgress,
    required this.floorProgress,
    required this.calorieProgress,
    required this.currentSteps,
    required this.stepGoal,
  });

  static const Duration _duration = Duration(milliseconds: 1150);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 238,
      height: 238,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: stepProgress),
        duration: _duration,
        curve: Curves.easeOutCubic,
        builder: (context, animatedSteps, _) {
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: floorProgress),
            duration: _duration,
            curve: Curves.easeOutCubic,
            builder: (context, animatedFloors, _) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: calorieProgress),
                duration: _duration,
                curve: Curves.easeOutCubic,
                builder: (context, animatedCalories, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(238, 238),
                        painter: _TriRingPainter(
                          stepProgress: animatedSteps,
                          floorProgress: animatedFloors,
                          calorieProgress: animatedCalories,
                        ),
                      ),
                      _buildCenter(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCenter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.activityPrimary.withOpacity(0.10),
            border: Border.all(
              color: AppColors.activityPrimary.withOpacity(0.18),
            ),
          ),
          child: const Icon(
            Icons.directions_walk_rounded,
            color: AppColors.activityPrimary,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCounter(
          value: currentSteps.toDouble(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
            height: 1.0,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'OF ${_compact(stepGoal)} STEPS',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  String _compact(int value) {
    if (value >= 1000 && value % 1000 == 0) {
      return '${value ~/ 1000}K';
    }
    return value.toString();
  }
}

class _TriRingPainter extends CustomPainter {
  final double stepProgress;
  final double floorProgress;
  final double calorieProgress;

  _TriRingPainter({
    required this.stepProgress,
    required this.floorProgress,
    required this.calorieProgress,
  });

  static const double _stroke = 11.5;
  static const double _gap = 4.5;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outerRadius = (size.width / 2) - _stroke / 2 - 8;
    final double radiusStep = outerRadius;
    final double radiusFloor = outerRadius - _stroke - _gap;
    final double radiusCalorie = radiusFloor - _stroke - _gap;

    _drawTicks(canvas, center, outerRadius + 12, stepProgress);

    _drawRing(
      canvas,
      center,
      radiusStep,
      AppColors.activityPrimary,
      stepProgress,
    );
    _drawRing(
      canvas,
      center,
      radiusFloor,
      AppColors.barometerPrimary,
      floorProgress,
    );
    _drawRing(
      canvas,
      center,
      radiusCalorie,
      const Color(0xFFFFB020),
      calorieProgress,
    );
  }

  void _drawTicks(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
  ) {
    const int ticks = 56;
    for (int i = 0; i < ticks; i++) {
      final double angle = (math.pi * 2 / ticks) * i - math.pi / 2;
      final bool highlighted = (i / ticks) <= progress;
      final double inner = radius;
      final double outer = radius + (highlighted ? 4.0 : 2.5);
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * inner,
          center.dy + math.sin(angle) * inner,
        ),
        Offset(
          center.dx + math.cos(angle) * outer,
          center.dy + math.sin(angle) * outer,
        ),
        Paint()
          ..color = highlighted
              ? AppColors.activityPrimary.withOpacity(0.35)
              : Colors.white.withOpacity(0.07)
          ..strokeWidth = highlighted ? 1.4 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double progress,
  ) {
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final double clamped = progress.clamp(0.0, 1.0);

    // Inactive track.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(0.11)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke,
    );

    if (clamped <= 0.001) return;

    const double start = -math.pi / 2;
    final double sweep = math.pi * 2 * clamped;

    // Ambient glow under the active arc.
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = color.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // Main gradient arc.
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: [
            color.withOpacity(0.55),
            color,
            color.withOpacity(0.85),
          ],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round,
    );

    // Bright leading cap.
    final double endAngle = start + sweep;
    final Offset capCenter = Offset(
      center.dx + math.cos(endAngle) * radius,
      center.dy + math.sin(endAngle) * radius,
    );
    canvas.drawCircle(
      capCenter,
      2.6,
      Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  @override
  bool shouldRepaint(covariant _TriRingPainter oldDelegate) {
    return oldDelegate.stepProgress != stepProgress ||
        oldDelegate.floorProgress != floorProgress ||
        oldDelegate.calorieProgress != calorieProgress;
  }
}
