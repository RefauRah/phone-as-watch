import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Decorative ECG strip that scrolls continuously, giving the heart-rate card
/// a sense of a live bedside monitor even between readings.
class MiniEcg extends StatefulWidget {
  const MiniEcg({
    super.key,
    this.height = 54,
    this.color = AppColors.heartRatePrimary,
    this.beatsPerView = 2.2,
    this.period = const Duration(milliseconds: 2200),
  });

  final double height;
  final Color color;
  final double beatsPerView;
  final Duration period;

  @override
  State<MiniEcg> createState() => _MiniEcgState();
}

class _MiniEcgState extends State<MiniEcg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.0, 0.12, 0.86, 1.0],
          ).createShader(bounds);
        },
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _EcgPainter(
                  progress: _controller.value,
                  color: widget.color,
                  beatsPerView: widget.beatsPerView,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  _EcgPainter({
    required this.progress,
    required this.color,
    required this.beatsPerView,
  });

  final double progress;
  final Color color;
  final double beatsPerView;

  static double _beatWave(double phase) {
    double wave = 0;
    double gauss(double center, double width, double amplitude) {
      final double d = (phase - center) / width;
      return amplitude * math.exp(-(d * d));
    }

    wave += gauss(0.16, 0.030, 0.10); // P wave
    wave += gauss(0.335, 0.013, -0.16); // Q dip
    wave += gauss(0.365, 0.010, 0.95); // R spike
    wave += gauss(0.395, 0.016, -0.26); // S dip
    wave += gauss(0.58, 0.055, 0.24); // T wave
    return wave;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height * 0.56;
    final double amplitude = size.height * 0.34;
    const int samples = 150;

    final Path path = Path();
    for (int i = 0; i <= samples; i++) {
      final double xNorm = i / samples;
      final double phase =
          (xNorm * beatsPerView - progress * beatsPerView) % 1.0;
      final double x = xNorm * size.width;
      final double y =
          (midY - _beatWave(phase) * amplitude).clamp(2.0, size.height - 2.0);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(0.35), color, color.withOpacity(0.35)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.beatsPerView != beatsPerView;
  }
}
