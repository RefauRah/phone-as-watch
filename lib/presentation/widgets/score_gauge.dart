import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Compact circular score indicator used for sleep quality and similar metrics.
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({
    super.key,
    required this.value,
    this.size = 62,
    this.strokeWidth = 5,
    this.accent = AppColors.sleepPrimary,
    this.label = 'SCORE',
  });

  /// 0..100.
  final double value;
  final double size;
  final double strokeWidth;
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: (value / 100).clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return CustomPaint(
            painter: _GaugePainter(
              progress: progress,
              accent: accent,
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: size * 0.30,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: size * 0.115,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.accent,
    required this.strokeWidth,
  });

  final double progress;
  final Color accent;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accent.withOpacity(0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final Paint arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [accent.withOpacity(0.55), accent],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );

    // Glow pass for the leading edge.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = accent.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
