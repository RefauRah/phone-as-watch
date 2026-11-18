import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/constants/app_colors.dart';
import '../../features/sleep/dsp/sleep_classifier.dart';

/// Interactive hypnogram: animated step-line chart with tap/drag scrubbing to
/// inspect an individual sleep epoch.
class SleepStageChart extends StatefulWidget {
  final List<SleepEpoch> epochs;

  const SleepStageChart({super.key, required this.epochs});

  @override
  State<SleepStageChart> createState() => _SleepStageChartState();
}

class _SleepStageChartState extends State<SleepStageChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );

  int? _selectedIndex;

  static const double _leftGutter = 42;

  @override
  void initState() {
    super.initState();
    if (widget.epochs.isNotEmpty) _reveal.forward();
  }

  @override
  void didUpdateWidget(covariant SleepStageChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.epochs.length != widget.epochs.length) {
      _selectedIndex = null;
      _reveal
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _handlePosition(Offset localPosition, double width) {
    if (widget.epochs.isEmpty) return;
    final double chartWidth = width - _leftGutter;
    if (chartWidth <= 0) return;
    final double dx =
        (localPosition.dx - _leftGutter).clamp(0.0, chartWidth - 1);
    final int index = (dx / (chartWidth / widget.epochs.length)).floor().clamp(
          0,
          widget.epochs.length - 1,
        );
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
    }
  }

  String _stageLabel(SleepStage stage) {
    switch (stage) {
      case SleepStage.awake:
        return 'Awake';
      case SleepStage.lightSleep:
        return 'Light sleep';
      case SleepStage.deepSleep:
        return 'Deep sleep';
    }
  }

  Color _stageColor(SleepStage stage) {
    switch (stage) {
      case SleepStage.awake:
        return AppColors.sleepAwake;
      case SleepStage.lightSleep:
        return AppColors.sleepLight;
      case SleepStage.deepSleep:
        return AppColors.sleepDeep;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.epochs.isEmpty) {
      return Container(
        height: 138,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.025),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bedtime_outlined,
                color: AppColors.sleepPrimary.withOpacity(0.7),
                size: 26,
              ),
              const SizedBox(height: 8),
              const Text(
                'No sleep session yet',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Start tracking tonight to build your hypnogram',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
              ),
            ],
          ),
        ),
      );
    }

    final SleepEpoch? selected =
        _selectedIndex != null && _selectedIndex! < widget.epochs.length
            ? widget.epochs[_selectedIndex!]
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 22,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: selected == null
                ? Row(
                    key: const ValueKey('hint'),
                    children: [
                      const Icon(
                        Icons.gesture_rounded,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Tap or drag the graph to inspect an epoch',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted.withOpacity(0.9),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TimeRange(epochs: widget.epochs),
                    ],
                  )
                : Row(
                    key: ValueKey(_selectedIndex),
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _stageColor(selected.stage),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${DateFormat('HH:mm').format(selected.timestamp)}  •  ${_stageLabel(selected.stage)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'motion ${selected.motionVariance.toStringAsFixed(3)}'
                        '${selected.snoreDetected ? '  •  snore' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 132,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _handlePosition(
                    details.localPosition, constraints.maxWidth),
                onHorizontalDragUpdate: (details) => _handlePosition(
                  details.localPosition,
                  constraints.maxWidth,
                ),
                child: AnimatedBuilder(
                  animation: _reveal,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _HypnogramPainter(
                        epochs: widget.epochs,
                        reveal: Curves.easeOutCubic.transform(_reveal.value),
                        selectedIndex: _selectedIndex,
                        leftGutter: _leftGutter,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LegendDot(color: AppColors.sleepAwake, label: 'Awake'),
            _LegendDot(color: AppColors.sleepLight, label: 'Light'),
            _LegendDot(color: AppColors.sleepDeep, label: 'Deep'),
            _LegendDot(
              color: AppColors.sleepSnore,
              label: 'Snore',
              small: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeRange extends StatelessWidget {
  const _TimeRange({required this.epochs});

  final List<SleepEpoch> epochs;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${DateFormat('HH:mm').format(epochs.first.timestamp)} – '
      '${DateFormat('HH:mm').format(epochs.last.timestamp)}',
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.small = false,
  });

  final Color color;
  final String label;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: small ? 6 : 8,
          height: small ? 6 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(small ? 3 : 2.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 5),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HypnogramPainter extends CustomPainter {
  _HypnogramPainter({
    required this.epochs,
    required this.reveal,
    required this.selectedIndex,
    required this.leftGutter,
  });

  final List<SleepEpoch> epochs;
  final double reveal;
  final int? selectedIndex;
  final double leftGutter;

  static const double _topPadding = 16;

  double _yForStage(SleepStage stage, double areaTop, double rowHeight) {
    final double rowIndex;
    switch (stage) {
      case SleepStage.awake:
        rowIndex = 0.38;
        break;
      case SleepStage.lightSleep:
        rowIndex = 1.35;
        break;
      case SleepStage.deepSleep:
        rowIndex = 2.32;
        break;
    }
    return areaTop + rowHeight * rowIndex;
  }

  Color _colorForStage(SleepStage stage) {
    switch (stage) {
      case SleepStage.awake:
        return AppColors.sleepAwake;
      case SleepStage.lightSleep:
        return AppColors.sleepLight;
      case SleepStage.deepSleep:
        return AppColors.sleepDeep;
    }
  }

  String _labelForStage(SleepStage stage) {
    switch (stage) {
      case SleepStage.awake:
        return 'AWAKE';
      case SleepStage.lightSleep:
        return 'LIGHT';
      case SleepStage.deepSleep:
        return 'DEEP';
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (epochs.isEmpty) return;

    final double chartBottom = size.height - 6;
    const double chartTop = _topPadding;
    final double rowHeight = (chartBottom - chartTop) / 3;
    final double chartLeft = leftGutter;
    final double chartWidth = size.width - chartLeft;
    if (chartWidth <= 0) return;

    // Stage guides + labels.
    for (final SleepStage stage in SleepStage.values) {
      final double y = _yForStage(stage, chartTop, rowHeight);

      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.white.withOpacity(0.055)
          ..strokeWidth = 1,
      );

      final TextPainter label = TextPainter(
        text: TextSpan(
          text: _labelForStage(stage),
          style: TextStyle(
            color: _colorForStage(stage).withOpacity(0.75),
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(chartLeft - label.width - 9, y - label.height / 2),
      );
    }

    final double barWidth = chartWidth / epochs.length;
    final List<double> ys = epochs
        .map((e) => _yForStage(e.stage, chartTop, rowHeight))
        .toList(growable: false);

    final double revealWidth = chartWidth * reveal;

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(chartLeft, 0, revealWidth + 0.5, size.height),
    );

    // 1. Gradient area fill under the step line.
    final Path fill = Path()..moveTo(chartLeft, chartBottom);
    fill.lineTo(chartLeft, ys.first);
    double xCursor = chartLeft;
    for (int i = 0; i < epochs.length; i++) {
      xCursor = chartLeft + (i + 1) * barWidth;
      fill.lineTo(xCursor, ys[i]);
      if (i < epochs.length - 1) fill.lineTo(xCursor, ys[i + 1]);
    }
    fill.lineTo(size.width, chartBottom);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sleepPrimary.withOpacity(0.30),
            AppColors.sleepPrimary.withOpacity(0.02),
          ],
        ).createShader(
            Rect.fromLTWH(chartLeft, chartTop, chartWidth, chartBottom)),
    );

    // 2. Step line, coloured per epoch.
    for (int i = 0; i < epochs.length; i++) {
      final double xStart = chartLeft + i * barWidth;
      final double xEnd = xStart + barWidth;
      final Color color = _colorForStage(epochs[i].stage);
      final Paint segment = Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(xStart, ys[i]), Offset(xEnd, ys[i]), segment);

      if (i < epochs.length - 1 && ys[i] != ys[i + 1]) {
        canvas.drawLine(
          Offset(xEnd, ys[i]),
          Offset(xEnd, ys[i + 1]),
          Paint()
            ..color = color.withOpacity(0.55)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
      }

      // Snore markers hover above the corresponding epoch.
      if (epochs[i].snoreDetected) {
        final Offset center = Offset(xStart + barWidth / 2, 5.5);
        canvas.drawCircle(
          center,
          3.6,
          Paint()
            ..color = AppColors.sleepSnore.withOpacity(0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(
          center,
          2.0,
          Paint()..color = AppColors.sleepSnore,
        );
      }
    }

    // 3. Selected epoch highlight.
    if (selectedIndex != null && selectedIndex! < epochs.length) {
      final double x = chartLeft + (selectedIndex! + 0.5) * barWidth;
      _drawDashedLine(
        canvas,
        Offset(x, 2),
        Offset(x, chartBottom),
        Colors.white.withOpacity(0.22),
      );
      final Offset point = Offset(x, ys[selectedIndex!]);
      canvas.drawCircle(
        point,
        7,
        Paint()..color = AppColors.sleepSecondary.withOpacity(0.20),
      );
      canvas.drawCircle(
        point,
        3.4,
        Paint()..color = Colors.white,
      );
    }

    // 4. Soft fade at the leading edge while revealing.
    if (reveal < 0.999) {
      canvas.drawRect(
        Rect.fromLTWH(
          chartLeft + revealWidth - 18,
          0,
          18,
          size.height,
        ),
        Paint()
          ..shader = LinearGradient(
            colors: [
              AppColors.sleepPrimary.withOpacity(0.0),
              AppColors.sleepPrimary.withOpacity(0.6),
            ],
          ).createShader(
            Rect.fromLTWH(chartLeft + revealWidth - 18, 0, 18, size.height),
          ),
      );
    }

    canvas.restore();
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
  ) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const double dash = 3.5;
    const double gap = 4;
    double y = start.dy;
    while (y < end.dy) {
      canvas.drawLine(
        Offset(start.dx, y),
        Offset(start.dx, (y + dash).clamp(start.dy, end.dy)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _HypnogramPainter oldDelegate) {
    return oldDelegate.reveal != reveal ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.epochs.length != epochs.length ||
        oldDelegate.epochs != epochs;
  }
}
