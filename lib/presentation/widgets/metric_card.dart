import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'glass_card.dart';

/// Compact glass tile for secondary biometrics such as pressure and floors.
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Optional 0..1 progress rendered as a slim gradient track at the bottom.
  final double? progress;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    this.onTap,
    this.trailing,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      accent: accentColor,
      tint: accentColor.withOpacity(0.05),
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withOpacity(0.24),
                      accentColor.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.20)),
                ),
                child: Icon(icon, color: accentColor, size: 17),
              ),
              const Spacer(),
              if (trailing != null)
                trailing!
              else
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    height: 1.0,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 7),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 12),
            _Track(progress: progress!, color: accentColor),
          ],
        ],
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 4,
                color: Colors.white.withOpacity(0.06),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.5), color],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
