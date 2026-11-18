import 'package:flutter/material.dart';

/// A number that smoothly tweens toward its new value with locale-friendly
/// thousands separators. Keeps live sensor readouts feeling fluid.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.decimals = 0,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.easeOutCubic,
  });

  final double value;
  final int decimals;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, _) {
        return Text(
          '$prefix${_format(animatedValue)}$suffix',
          style: style,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
        );
      },
    );
  }

  String _format(double raw) {
    final double safe = raw.isFinite ? raw : 0;
    final String fixed = safe.toStringAsFixed(decimals);
    final List<String> parts = fixed.split('.');
    final String digits = parts.first;
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final int remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    if (parts.length > 1) {
      buffer.write('.');
      buffer.write(parts[1]);
    }
    return buffer.toString();
  }
}
