import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

class NavDestination {
  const NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color accent;
}

/// Floating, scroll-aware bottom navigation with a glass pill and animated
/// selection surface.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<NavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated.withOpacity(0.96),
            AppColors.surface.withOpacity(0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: destinations[selectedIndex].accent.withOpacity(0.08),
            blurRadius: 30,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < destinations.length; i++)
            Expanded(
              child: _NavItem(
                destination: destinations[i],
                selected: i == selectedIndex,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? destination.accent.withOpacity(0.13)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? destination.accent.withOpacity(0.22)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(
                selected ? destination.activeIcon : destination.icon,
                size: 21,
                color: selected
                    ? destination.accent
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.1,
                fontFamily: 'Roboto',
              ),
              child: Text(destination.label),
            ),
          ],
        ),
      ),
    );
  }
}
