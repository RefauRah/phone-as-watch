import 'package:flutter/material.dart';

/// A status dot with a softly expanding halo. Used to signal live tracking.
class PulseDot extends StatefulWidget {
  const PulseDot({
    super.key,
    this.color = const Color(0xFF7DF5A4),
    this.size = 7,
    this.period = const Duration(milliseconds: 1800),
  });

  final Color color;
  final double size;
  final Duration period;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
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
    final double extent = widget.size * 3.4;

    return SizedBox(
      width: extent,
      height: extent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final double t = Curves.easeOut.transform(_controller.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t) * 0.55,
                child: Container(
                  width: widget.size + (extent - widget.size) * t,
                  height: widget.size + (extent - widget.size) * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(0.55),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.65),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
