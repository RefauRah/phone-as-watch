import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// High-performance CustomPainter rendering a real-time medical
/// plethysmogram (PPG) with a soft clinical grid and glowing trace.
class LiveWaveformPainter extends CustomPainter {
  final List<double> signalHistory;
  final bool isFingerDetected;
  final bool isPeak;

  LiveWaveformPainter({
    required this.signalHistory,
    required this.isFingerDetected,
    required this.isPeak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGridBackground(canvas, size);

    if (signalHistory.length < 2 || !isFingerDetected) {
      _drawFlatBaseline(canvas, size);
      return;
    }

    _drawWaveform(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, -0.8),
          radius: 1.2,
          colors: [
            AppColors.heartRatePrimary.withOpacity(0.09),
            AppColors.heartRatePrimary.withOpacity(0.0),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _drawGridBackground(Canvas canvas, Size size) {
    final Paint minor = Paint()
      ..color = Colors.white.withOpacity(0.024)
      ..strokeWidth = 0.8;
    final Paint major = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..strokeWidth = 0.9;

    const int hDivisions = 8;
    final double dy = size.height / hDivisions;
    for (int i = 1; i < hDivisions; i++) {
      final double y = dy * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i % 2 == 0 ? major : minor,
      );
    }

    const int vDivisions = 16;
    final double dx = size.width / vDivisions;
    for (int i = 1; i < vDivisions; i++) {
      final double x = dx * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i % 4 == 0 ? major : minor,
      );
    }

    // Centre reference line.
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = Colors.white.withOpacity(0.07)
        ..strokeWidth = 1,
    );
  }

  void _drawFlatBaseline(Canvas canvas, Size size) {
    final double midY = size.height / 2.0;

    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      Paint()
        ..color = AppColors.textMuted.withOpacity(0.35)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // Dim heartbeat-ish shimmer so the empty canvas still feels alive.
    canvas.drawLine(
      Offset(size.width * 0.38, midY),
      Offset(size.width * 0.40, midY - 4),
      Paint()
        ..color = AppColors.heartRatePrimary.withOpacity(0.12)
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(size.width * 0.40, midY - 4),
      Offset(size.width * 0.42, midY + 3),
      Paint()
        ..color = AppColors.heartRatePrimary.withOpacity(0.12)
        ..strokeWidth = 1.2,
    );
  }

  void _drawWaveform(Canvas canvas, Size size) {
    final int count = signalHistory.length;
    final double stepX = size.width / (count - 1);
    final double midY = size.height / 2.0;

    double maxAbs = 0.1;
    for (final double value in signalHistory) {
      if (value.abs() > maxAbs) maxAbs = value.abs();
    }
    final double scaleY = (size.height * 0.36) / maxAbs;

    final Path wavePath = Path();
    final Path fillPath = Path()..moveTo(0, size.height);

    double lastX = 0;
    double lastY = midY;

    for (int i = 0; i < count; i++) {
      final double x = i * stepX;
      final double y =
          (midY - (signalHistory[i] * scaleY)).clamp(6.0, size.height - 6.0);
      lastX = x;
      lastY = y;

      if (i == 0) {
        wavePath.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        final double prevX = (i - 1) * stepX;
        final double prevY =
            (midY - (signalHistory[i - 1] * scaleY)).clamp(
              6.0,
              size.height - 6.0,
            );
        final double midControlX = (prevX + x) / 2.0;
        wavePath.cubicTo(midControlX, prevY, midControlX, y, x, y);
        fillPath.cubicTo(midControlX, prevY, midControlX, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // 1. Gradient area fill.
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.heartRatePrimary.withOpacity(0.30),
            AppColors.heartRatePrimary.withOpacity(0.015),
          ],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.fill,
    );

    // 2. Wide blurred glow pass.
    canvas.drawPath(
      wavePath,
      Paint()
        ..color = AppColors.heartRatePrimary.withOpacity(0.38)
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 3. Crisp gradient trace.
    canvas.drawPath(
      wavePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.heartRateSecondary.withOpacity(0.75),
            AppColors.heartRatePrimary,
            AppColors.heartRateSecondary,
          ],
        ).createShader(Offset.zero & size)
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // 4. Scan line at the leading edge.
    canvas.drawRect(
      Rect.fromLTWH(lastX - 0.6, 0, 1.2, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.heartRatePrimary.withOpacity(0.0),
            AppColors.heartRatePrimary.withOpacity(0.28),
            AppColors.heartRatePrimary.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(lastX, 0, 1.2, size.height)),
    );

    // 5. Leading pulse dot.
    canvas.drawCircle(
      Offset(lastX, lastY),
      7,
      Paint()
        ..color = AppColors.heartRatePrimary.withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      3.2,
      Paint()..color = Colors.white,
    );

    if (isPeak) {
      canvas.drawCircle(
        Offset(lastX, lastY),
        9,
        Paint()
          ..color = AppColors.heartRatePrimary.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      canvas.drawCircle(
        Offset(lastX, lastY),
        15,
        Paint()
          ..color = AppColors.heartRatePrimary.withOpacity(0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LiveWaveformPainter oldDelegate) {
    return true; // Live 30-60 FPS continuous update.
  }
}
