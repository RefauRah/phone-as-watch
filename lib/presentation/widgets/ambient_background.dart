import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Slow-moving aurora gradients and a faint dot matrix behind the dashboard.
///
/// The animation is intentionally subtler than the foreground cards so it adds
/// depth without competing with the live biometric data.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AmbientPainter(_controller.value),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.t);

  /// Normalised time in the 0..1 range.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = AppColors.canvasGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height * 1.15),
        ),
    );

    final double tau = t * math.pi * 2;

    _orb(
      canvas,
      center: Offset(
        size.width * 0.92 + math.sin(tau) * 26,
        size.height * 0.10 + math.cos(tau * 0.8) * 34,
      ),
      radius: size.width * 0.68,
      color: AppColors.sleepPrimary,
      opacity: 0.20,
    );

    _orb(
      canvas,
      center: Offset(
        size.width * 0.02 + math.cos(tau * 0.7) * 32,
        size.height * 0.42 + math.sin(tau * 0.9) * 48,
      ),
      radius: size.width * 0.75,
      color: AppColors.barometerPrimary,
      opacity: 0.10,
    );

    _orb(
      canvas,
      center: Offset(
        size.width * 0.82 + math.sin(tau * 1.2) * 24,
        size.height * 0.86 + math.cos(tau) * 36,
      ),
      radius: size.width * 0.62,
      color: AppColors.heartRatePrimary,
      opacity: 0.08,
    );

    _orb(
      canvas,
      center: Offset(
        size.width * 0.30 + math.sin(tau * 0.5) * 40,
        size.height * 0.94,
      ),
      radius: size.width * 0.60,
      color: AppColors.activityPrimary,
      opacity: 0.06,
    );

    _dotMatrix(canvas, size);

    // Soft top-to-bottom vignette to keep the header legible.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 180),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withOpacity(0.55),
            AppColors.background.withOpacity(0.0),
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 400, 180)),
    );
  }

  void _orb(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.45),
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
  }

  void _dotMatrix(Canvas canvas, Size size) {
    const double gap = 30;
    final List<Offset> dots = <Offset>[];
    for (double x = 18; x < size.width; x += gap) {
      for (double y = 18; y < size.height; y += gap) {
        dots.add(Offset(x, y));
      }
    }
    canvas.drawPoints(
      PointMode.points,
      dots,
      Paint()
        ..color = Colors.white.withOpacity(0.035)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => oldDelegate.t != t;
}
