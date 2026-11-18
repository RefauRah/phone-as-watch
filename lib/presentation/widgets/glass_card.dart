import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'pressable_scale.dart';

/// A dark translucent panel with a soft gradient border, top-edge highlight and
/// optional accent glow. The bread-and-butter container for the dashboard.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.margin = EdgeInsets.zero,
    this.radius = 28,
    this.accent,
    this.tint,
    this.borderColor,
    this.onTap,
    this.glow = false,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;

  /// Accent used for the tint, border and glow.
  final Color? accent;
  final Color? tint;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool glow;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = accent ?? AppColors.textSecondary;
    final Color topTint = tint ?? accentColor.withOpacity(0.06);

    final panel = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(topTint, AppColors.surface).withOpacity(0.97),
            Color.alphaBlend(topTint.withOpacity(0.35), AppColors.surface)
                .withOpacity(0.92),
          ],
        ),
        border: Border.all(
          color: (borderColor ?? accentColor).withOpacity(0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
          if (glow)
            BoxShadow(
              color: accentColor.withOpacity(0.10),
              blurRadius: 46,
              spreadRadius: -10,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Stack(
          children: [
            // Top-edge "glass" highlight.
            Positioned(
              top: 0,
              left: 28,
              right: 28,
              child: IgnorePointer(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.16),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );

    if (!clip) return panel;
    return onTap == null
        ? panel
        : PressableScale(onTap: onTap, pressedScale: 0.985, child: panel);
  }
}
