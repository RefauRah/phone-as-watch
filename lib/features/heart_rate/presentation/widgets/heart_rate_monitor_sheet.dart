import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../presentation/widgets/pressable_scale.dart';
import '../../../../presentation/widgets/pulse_dot.dart';
import '../controllers/heart_rate_controller.dart';
import 'live_waveform_painter.dart';

class HeartRateMonitorSheet extends StatefulWidget {
  const HeartRateMonitorSheet({super.key});

  static Future<void> show(BuildContext context) {
    final HeartRateController controller =
        context.read<HeartRateController>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => const HeartRateMonitorSheet(),
    ).whenComplete(controller.stopMeasurement);
  }

  @override
  State<HeartRateMonitorSheet> createState() => _HeartRateMonitorSheetState();
}

class _HeartRateMonitorSheetState extends State<HeartRateMonitorSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HeartRateController>().startMeasurement();
      }
    });
  }

  Future<void> _closeSheet() async {
    final NavigatorState nav = Navigator.of(context);
    final HeartRateController controller =
        context.read<HeartRateController>();
    await controller.stopMeasurement();
    if (mounted) nav.pop();
  }

  void _restartOrFinish(HeartRateController controller) {
    HapticFeedback.mediumImpact();
    if (controller.isMeasurementComplete) {
      _closeSheet();
    } else {
      controller.startMeasurement();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HeartRateController>(
      builder: (context, controller, _) {
        final bool isFingerOn = controller.isFingerDetected;
        final bool isDone = controller.isMeasurementComplete;
        final double? bpm = controller.currentBpm;
        final double? hrv = controller.hrvRmssd;
        final double progress = controller.measurementProgress;
        final String? error = controller.errorMessage;

        final Color statusColor = isDone
            ? AppColors.success
            : isFingerOn
                ? AppColors.heartRatePrimary
                : AppColors.warning;

        return Container(
          height: MediaQuery.sizeOf(context).height * 0.90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0C111A), AppColors.background],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(34)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.10),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                _buildHeader(controller),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatusBanner(
                    isFingerOn: isFingerOn,
                    isDone: isDone,
                    progress: progress,
                    statusColor: statusColor,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildErrorBanner(error),
                  ),
                ],
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.favorite_rounded,
                          label: 'HEART RATE',
                          value: bpm?.toStringAsFixed(0) ?? '--',
                          unit: 'BPM',
                          color: AppColors.heartRatePrimary,
                          gradient: AppColors.heartGradient,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.monitor_heart_outlined,
                          label: 'HRV · RMSSD',
                          value: hrv?.toStringAsFixed(0) ?? '--',
                          unit: 'ms',
                          color: AppColors.barometerPrimary,
                          gradient: AppColors.aquaGradient,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'CAPTURE WINDOW',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(progress * 15).toStringAsFixed(0)}s / 15s',
                            style: TextStyle(
                              color: isFingerOn
                                  ? AppColors.textSecondary
                                  : AppColors.textMuted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _GradientProgressBar(
                        value: progress,
                        color: isDone
                            ? AppColors.success
                            : AppColors.heartRatePrimary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildWaveformArea(
                      controller: controller,
                      isFingerOn: isFingerOn,
                      isDone: isDone,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _buildPrimaryButton(
                    controller: controller,
                    isDone: isDone,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(HeartRateController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          AnimatedScale(
            scale: controller.isPeak ? 1.18 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.heartRatePrimary.withOpacity(0.30),
                    AppColors.heartRatePrimary.withOpacity(0.06),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.heartRatePrimary.withOpacity(0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.heartRatePrimary.withOpacity(0.20),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.heartRatePrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Camera PPG',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Fingertip optical pulse · HRV',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          PressableScale(
            onTap: _closeSheet,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required bool isFingerOn,
    required bool isDone,
    required double progress,
    required Color statusColor,
  }) {
    final String title;
    final String subtitle;
    final IconData icon;

    if (isDone) {
      title = 'Reading captured';
      subtitle = 'BPM and HRV saved to your dashboard';
      icon = Icons.check_circle_rounded;
    } else if (isFingerOn) {
      title = 'Fingertip detected — hold still';
      subtitle =
          '${(15 - progress * 15).ceil().clamp(0, 15)} seconds remaining';
      icon = Icons.fingerprint_rounded;
    } else {
      title = 'Place your index finger on the camera';
      subtitle = 'Cover the rear lens and flash completely';
      icon = Icons.touch_app_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Column(
                key: ValueKey('$isDone-$isFingerOn'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFingerOn && !isDone)
            const PulseDot(color: AppColors.heartRatePrimary, size: 6),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 10.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformArea({
    required HeartRateController controller,
    required bool isFingerOn,
    required bool isDone,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF080C13),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.heartRatePrimary.withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: -8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: LiveWaveformPainter(
                signalHistory: controller.waveformBuffer,
                isFingerDetected: isFingerOn,
                isPeak: controller.isPeak,
              ),
            ),
          ),
          // Top overlay: live status + FPS.
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xCC0B111A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Row(
                children: [
                  PulseDot(
                    color: isFingerOn
                        ? AppColors.success
                        : AppColors.textMuted,
                    size: 5,
                  ),
                  Text(
                    isFingerOn ? 'LIVE PPG' : 'WAITING',
                    style: TextStyle(
                      color: isFingerOn
                          ? AppColors.success
                          : AppColors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 14,
            child: Text(
              '30 FPS',
              style: TextStyle(
                color: AppColors.textMuted.withOpacity(0.8),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          // Bottom overlay: filter info.
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Row(
              children: [
                const Icon(
                  Icons.graphic_eq_rounded,
                  size: 12,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                const Text(
                  '0.7 – 3.5 Hz IIR BANDPASS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (isDone)
                  const Text(
                    'CAPTURED',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
              ],
            ),
          ),
          if (!isFingerOn)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.03),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Icon(
                          Icons.fingerprint_rounded,
                          color: Colors.white.withOpacity(0.22),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Awaiting fingertip',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.28),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required HeartRateController controller,
    required bool isDone,
  }) {
    final Gradient gradient =
        isDone ? AppColors.activityGradient : AppColors.heartGradient;
    final Color foreground =
        isDone ? const Color(0xFF0B1207) : Colors.white;

    return PressableScale(
      onTap: () => _restartOrFinish(controller),
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (isDone ? AppColors.activityPrimary : AppColors.heartRatePrimary)
                  .withOpacity(0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDone ? Icons.check_rounded : Icons.refresh_rounded,
              size: 19,
              color: foreground,
            ),
            const SizedBox(width: 8),
            Text(
              isDone ? 'Save reading & finish' : 'Restart measurement',
              style: TextStyle(
                color: foreground,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.09),
            AppColors.surface.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (Rect bounds) => gradient.createShader(bounds),
                child: Icon(icon, size: 13, color: Colors.white),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  value,
                  key: ValueKey(value),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    letterSpacing: -1.6,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      builder: (context, animated, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: Colors.white.withOpacity(0.06)),
                ),
                FractionallySizedBox(
                  widthFactor: animated,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.55),
                          color,
                          Colors.white.withOpacity(0.9),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
