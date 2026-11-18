import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../features/activity/presentation/controllers/activity_controller.dart';
import '../features/heart_rate/presentation/controllers/heart_rate_controller.dart';
import '../features/heart_rate/presentation/widgets/heart_rate_monitor_sheet.dart';
import '../features/sleep/presentation/controllers/sleep_controller.dart';
import 'widgets/ambient_background.dart';
import 'widgets/animated_counter.dart';
import 'widgets/circular_progress_widget.dart';
import 'widgets/entrance.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/glass_card.dart';
import 'widgets/metric_card.dart';
import 'widgets/mini_ecg.dart';
import 'widgets/pressable_scale.dart';
import 'widgets/pulse_dot.dart';
import 'widgets/score_gauge.dart';
import 'widgets/sleep_stage_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _calorieColor = Color(0xFFFFB020);

  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys =
      List<GlobalKey>.generate(4, (_) => GlobalKey());

  int _activeSection = 0;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  static const List<NavDestination> _destinations = [
    NavDestination(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Today',
      accent: AppColors.barometerPrimary,
    ),
    NavDestination(
      icon: Icons.directions_walk_outlined,
      activeIcon: Icons.directions_walk_rounded,
      label: 'Activity',
      accent: AppColors.activityPrimary,
    ),
    NavDestination(
      icon: Icons.favorite_outline_rounded,
      activeIcon: Icons.favorite_rounded,
      label: 'Heart',
      accent: AppColors.heartRatePrimary,
    ),
    NavDestination(
      icon: Icons.bedtime_outlined,
      activeIcon: Icons.bedtime_rounded,
      label: 'Sleep',
      accent: AppColors.sleepPrimary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
      try {
        context.read<ActivityController>().startTracking();
      } catch (_) {
        // Sensors are unavailable on some targets (e.g. Flutter web preview).
      }
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    try {
      await [
        Permission.camera,
        Permission.sensors,
        Permission.microphone,
        Permission.activityRecognition,
      ].request();
    } catch (_) {
      // Permission APIs are not available on every platform.
    }
  }

  void _scrollToSection(int index) {
    final BuildContext? target = _sectionKeys[index].currentContext;
    if (target == null) return;
    setState(() => _activeSection = index);
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 680),
      curve: Curves.easeInOutCubic,
      alignment: index == 0 ? 0.0 : 0.02,
    );
  }

  void _syncActiveSection() {
    const double viewportTarget = 120;
    double closest = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _sectionKeys.length; i++) {
      final RenderObject? object =
          _sectionKeys[i].currentContext?.findRenderObject();
      if (object is! RenderBox || !object.hasSize) continue;
      final double dy = object.localToGlobal(Offset.zero).dy;
      final double distance = (dy - viewportTarget).abs();
      if (distance < closest) {
        closest = distance;
        closestIndex = i;
      }
    }

    if (closestIndex != _activeSection && mounted) {
      setState(() => _activeSection = closestIndex);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollEndNotification) _syncActiveSection();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      bottomNavigationBar: SafeArea(
        top: false,
        child: FloatingNavBar(
          selectedIndex: _activeSection,
          onTap: _scrollToSection,
          destinations: _destinations,
        ),
      ),
      body: SizedBox.expand(
        child: AmbientBackground(
          child: SafeArea(
            bottom: false,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(20, 10, 20, 124 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KeyedSubtree(
                      key: _sectionKeys[0],
                      child: _buildHeader(),
                    ),
                    const SizedBox(height: 24),
                    KeyedSubtree(
                      key: _sectionKeys[1],
                      child: Entrance(
                        delay: const Duration(milliseconds: 80),
                        child: _buildActivityCard(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    KeyedSubtree(
                      key: _sectionKeys[2],
                      child: Entrance(
                        delay: const Duration(milliseconds: 160),
                        child: _buildHeartCard(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Entrance(
                      delay: const Duration(milliseconds: 240),
                      child: _buildEnvironmentCards(),
                    ),
                    const SizedBox(height: 18),
                    KeyedSubtree(
                      key: _sectionKeys[3],
                      child: Entrance(
                        delay: const Duration(milliseconds: 320),
                        child: _buildSleepCard(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Entrance(
                      delay: Duration(milliseconds: 400),
                      child: _DspDetailsCard(),
                    ),
                    const SizedBox(height: 26),
                    const _Footer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    final int hour = _now.hour;
    final String greeting = hour < 5
        ? 'Still up?'
        : hour < 12
            ? 'Good morning'
            : hour < 17
                ? 'Good afternoon'
                : hour < 21
                    ? 'Good evening'
                    : 'Good night';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      PulseDot(
                        color: AppColors.success,
                        size: 6,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'PHONE AS WATCH',
                        style: TextStyle(
                          color: AppColors.activityPrimary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (Rect bounds) {
                      return AppColors.headlineGradient.createShader(bounds);
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 34,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${DateFormat('EEEE, d MMMM').format(_now)}  ·  '
                    '${DateFormat('HH:mm').format(_now)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _StatusOrb(),
          ],
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            _LiveChip(
              label: 'ALL SENSORS LIVE',
              color: AppColors.success,
            ),
            SizedBox(width: 8),
            _GhostChip(label: 'PPG · BARO · ACTIGRAPH'),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Activity
  // ---------------------------------------------------------------------------

  Widget _buildActivityCard() {
    return Consumer<ActivityController>(
      builder: (context, controller, _) {
        final metrics = controller.metrics;

        return GlassCard(
          accent: AppColors.activityPrimary,
          glow: true,
          tint: AppColors.activityPrimary.withOpacity(0.05),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            children: [
              _CardHeader(
                accent: AppColors.activityPrimary,
                gradient: AppColors.activityGradient,
                icon: Icons.directions_run_rounded,
                title: 'Activity',
                subtitle: 'Move · Climb · Burn',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LiveChip(
                      label: controller.isTracking ? 'TRACKING' : 'PAUSED',
                      color: controller.isTracking
                          ? AppColors.activityPrimary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    _CircleAction(
                      icon: controller.isTracking
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      accent: AppColors.activityPrimary,
                      tooltip: controller.isTracking
                          ? 'Pause activity tracking'
                          : 'Resume activity tracking',
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        controller.isTracking
                            ? controller.stopTracking()
                            : controller.startTracking();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TriRingProgressWidget(
                stepProgress: controller.stepProgress,
                floorProgress: controller.floorProgress,
                calorieProgress: controller.calorieProgress,
                currentSteps: metrics.steps,
                stepGoal: controller.stepGoal,
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.white.withOpacity(0.06), height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  _RingStat(
                    color: AppColors.activityPrimary,
                    icon: Icons.directions_walk_rounded,
                    label: 'STEPS',
                    value: metrics.steps.toString(),
                    caption:
                        '${(controller.stepProgress * 100).round()}% of goal',
                  ),
                  const _StatDivider(),
                  _RingStat(
                    color: AppColors.barometerPrimary,
                    icon: Icons.stairs_rounded,
                    label: 'FLOORS',
                    value: metrics.floorsClimbed.toStringAsFixed(1),
                    caption:
                        'of ${controller.floorGoal.toStringAsFixed(0)} floors',
                  ),
                  const _StatDivider(),
                  _RingStat(
                    color: _calorieColor,
                    icon: Icons.local_fire_department_rounded,
                    label: 'BURN',
                    value: metrics.caloriesKcal.toStringAsFixed(0),
                    caption: 'kcal today',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Heart rate
  // ---------------------------------------------------------------------------

  Widget _buildHeartCard() {
    return Consumer<HeartRateController>(
      builder: (context, controller, _) {
        final double? bpm = controller.lastConfirmedBpm;
        final double? hrv = controller.lastConfirmedHrv;

        return GlassCard(
          accent: AppColors.heartRatePrimary,
          glow: true,
          tint: AppColors.heartRatePrimary.withOpacity(0.05),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHeader(
                accent: AppColors.heartRatePrimary,
                gradient: AppColors.heartGradient,
                icon: Icons.favorite_rounded,
                title: 'Heart rate',
                subtitle: 'Camera PPG · 0.7–3.5 Hz IIR',
                trailing: _GhostChip(
                  label: 'LAST READING',
                  color: AppColors.heartRateSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _BeatHeart(color: AppColors.heartRatePrimary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  if (bpm != null)
                                    AnimatedCounter(
                                      value: bpm,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 46,
                                        fontWeight: FontWeight.w800,
                                        height: 0.95,
                                        letterSpacing: -2.2,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    )
                                  else
                                    const Text(
                                      '--',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 46,
                                        fontWeight: FontWeight.w800,
                                        height: 0.95,
                                        letterSpacing: -2.2,
                                      ),
                                    ),
                                  const SizedBox(width: 5),
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      'BPM',
                                      style: TextStyle(
                                        color: AppColors.heartRatePrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Resting · last confirmed',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 46,
                    color: Colors.white.withOpacity(0.07),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'HRV · RMSSD',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          if (hrv != null)
                            AnimatedCounter(
                              value: hrv,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                height: 1.0,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            )
                          else
                            const Text(
                              '--',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          const SizedBox(width: 4),
                          const Text(
                            'ms',
                            style: TextStyle(
                              color: AppColors.barometerPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF090E16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.055)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'PPG SIGNAL',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.heartRatePrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.heartRatePrimary.withOpacity(0.7),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'LIVE PREVIEW',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const MiniEcg(height: 48),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _GradientButton(
                label: 'Measure heart rate',
                icon: Icons.favorite_rounded,
                gradient: AppColors.heartGradient,
                glow: AppColors.heartRatePrimary,
                foreground: Colors.white,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  HeartRateMonitorSheet.show(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Environment cards
  // ---------------------------------------------------------------------------

  Widget _buildEnvironmentCards() {
    return Consumer<ActivityController>(
      builder: (context, controller, _) {
        final metrics = controller.metrics;
        final double altitude = metrics.relativeAltitudeMeters;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MetricCard(
                title: 'Barometer',
                value: metrics.currentPressureHpa.toStringAsFixed(1),
                unit: 'hPa',
                subtitle:
                    'Altitude ${altitude >= 0 ? '+' : ''}${altitude.toStringAsFixed(1)} m',
                icon: Icons.speed_rounded,
                accentColor: AppColors.barometerPrimary,
                progress:
                    ((metrics.currentPressureHpa - 950) / 150).clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Floors',
                value: metrics.floorsClimbed.toStringAsFixed(1),
                unit: 'floors',
                subtitle:
                    '${(controller.floorProgress * 100).round()}% of daily goal',
                icon: Icons.stairs_rounded,
                accentColor: AppColors.activityPrimary,
                progress: controller.floorProgress,
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Sleep
  // ---------------------------------------------------------------------------

  Widget _buildSleepCard() {
    return Consumer<SleepController>(
      builder: (context, controller, _) {
        final state = controller.sessionState;
        final bool isTracking = controller.isTracking;

        final String duration =
            '${state.elapsedDuration.inHours}h ${state.elapsedDuration.inMinutes % 60}m';
        final String deep =
            '${state.deepSleepDuration.inHours}h ${state.deepSleepDuration.inMinutes % 60}m';

        return GlassCard(
          accent: AppColors.sleepPrimary,
          glow: isTracking,
          tint: AppColors.sleepPrimary.withOpacity(0.05),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(
                accent: AppColors.sleepPrimary,
                gradient: AppColors.sleepGradient,
                icon: Icons.bedtime_rounded,
                title: 'Sleep',
                subtitle: isTracking
                    ? 'Recording · wakelock active'
                    : 'Last night · acoustic actigraphy',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isTracking) ...[
                      const _LiveChip(
                        label: 'LIVE',
                        color: AppColors.sleepSecondary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    ScoreGauge(
                      value: state.qualityScore.toDouble(),
                      size: 56,
                      strokeWidth: 4.5,
                      accent: AppColors.sleepSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _SleepStat(
                    icon: Icons.schedule_rounded,
                    color: AppColors.sleepSecondary,
                    label: 'DURATION',
                    value: duration,
                  ),
                  const _StatDivider(),
                  _SleepStat(
                    icon: Icons.dark_mode_rounded,
                    color: AppColors.sleepLight,
                    label: 'DEEP SLEEP',
                    value: deep,
                  ),
                  const _StatDivider(),
                  _SleepStat(
                    icon: Icons.graphic_eq_rounded,
                    color: AppColors.sleepSnore,
                    label: 'SNORES',
                    value: '${state.snoreEpisodes}x',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SleepStageChart(epochs: state.epochHistory),
              const SizedBox(height: 18),
              _GradientButton(
                label:
                    isTracking ? 'End sleep session' : 'Start sleep tracking',
                icon: isTracking
                    ? Icons.stop_circle_outlined
                    : Icons.nightlight_round,
                gradient: isTracking
                    ? const LinearGradient(
                        colors: [Color(0xFFFF8FA3), AppColors.danger],
                      )
                    : AppColors.sleepGradient,
                glow: isTracking ? AppColors.danger : AppColors.sleepPrimary,
                foreground: Colors.white,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  isTracking
                      ? controller.stopTracking()
                      : controller.startTracking();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Small components
// -----------------------------------------------------------------------------

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.accent,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final Color accent;
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(0.30),
                accent.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withOpacity(0.24)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.18),
                blurRadius: 16,
                spreadRadius: -4,
              ),
            ],
          ),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (Rect bounds) => gradient.createShader(bounds),
            child: Icon(icon, size: 21, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class _RingStat extends StatelessWidget {
  const _RingStat({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.0,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepStat extends StatelessWidget {
  const _SleepStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withOpacity(0.06),
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.7), blurRadius: 5),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostChip extends StatelessWidget {
  const _GhostChip({
    required this.label,
    this.color = AppColors.textMuted,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.accent,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget button = PressableScale(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: accent.withOpacity(0.22)),
        ),
        child: Icon(icon, size: 18, color: accent),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
    required this.foreground,
    this.glow,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final Color foreground;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: (glow ?? foreground).withOpacity(0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 16, color: foreground),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Animated decorations
// -----------------------------------------------------------------------------

class _StatusOrb extends StatefulWidget {
  const _StatusOrb();

  @override
  State<_StatusOrb> createState() => _StatusOrbState();
}

class _StatusOrbState extends State<_StatusOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.rotate(
                angle: _controller.value * math.pi * 2,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.activityPrimary.withOpacity(0.0),
                        AppColors.activityPrimary.withOpacity(0.65),
                        AppColors.barometerPrimary.withOpacity(0.35),
                        AppColors.activityPrimary.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.35, 0.6, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.watch_rounded,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const Positioned(
            right: 2,
            bottom: 2,
            child: PulseDot(color: AppColors.success, size: 5),
          ),
        ],
      ),
    );
  }
}

class _BeatHeart extends StatefulWidget {
  const _BeatHeart({required this.color});

  final Color color;

  @override
  State<_BeatHeart> createState() => _BeatHeartState();
}

class _BeatHeartState extends State<_BeatHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.0, end: 1.16)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 12,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.16, end: 1.0)
          .chain(CurveTween(curve: Curves.easeIn)),
      weight: 16,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.0, end: 1.08)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 10,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.08, end: 1.0)
          .chain(CurveTween(curve: Curves.easeIn)),
      weight: 14,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 48),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(scale: _scale.value, child: child);
      },
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.color.withOpacity(0.26),
              widget.color.withOpacity(0.06),
            ],
          ),
          border: Border.all(color: widget.color.withOpacity(0.26)),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.22),
              blurRadius: 18,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Icon(Icons.favorite_rounded, size: 21, color: widget.color),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.watch_rounded,
                size: 11,
                color: AppColors.textMuted.withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                'PHONE AS WATCH  ·  ON-DEVICE DSP',
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.8),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'No cloud. No wearables. Just your phone.',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.65),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Expandable DSP explainer
// -----------------------------------------------------------------------------

class _DspDetailsCard extends StatefulWidget {
  const _DspDetailsCard();

  @override
  State<_DspDetailsCard> createState() => _DspDetailsCardState();
}

class _DspDetailsCardState extends State<_DspDetailsCard> {
  bool _expanded = false;

  static const List<(String, String, String, IconData)> _pipelines = [
    (
      'PPG',
      'Butterworth bandpass 0.7–3.5 Hz → adaptive peak gate → RMSSD HRV',
      'HRV',
      Icons.favorite_rounded,
    ),
    (
      'Pedometer',
      'Triaxial magnitude LPF → refractory cadence hysteresis',
      'STEPS',
      Icons.directions_walk_rounded,
    ),
    (
      'Barometer',
      'Hypsometric Δh = −ΔP / 0.12 hPa/m · 0.36 hPa per floor',
      'FLOORS',
      Icons.stairs_rounded,
    ),
    (
      'Actigraphy',
      'Mattress variance fusion + periodic acoustic snore detector',
      'SLEEP',
      Icons.bedtime_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accent: AppColors.barometerPrimary,
      tint: Colors.white.withOpacity(0.012),
      padding: const EdgeInsets.all(18),
      radius: 24,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _expanded = !_expanded);
      },
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: const Icon(
                  Icons.memory_rounded,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Under the hood',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '4 DSP pipelines · pure Dart',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        for (int i = 0; i < _pipelines.length; i++) ...[
                          _PipelineRow(
                            index: i + 1,
                            title: _pipelines[i].$1,
                            description: _pipelines[i].$2,
                            tag: _pipelines[i].$3,
                            icon: _pipelines[i].$4,
                          ),
                          if (i != _pipelines.length - 1)
                            Divider(
                              color: Colors.white.withOpacity(0.05),
                              height: 18,
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({
    required this.index,
    required this.title,
    required this.description,
    required this.tag,
    required this.icon,
  });

  final int index;
  final String title;
  final String description;
  final String tag;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.barometerPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.barometerPrimary,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
