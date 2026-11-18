import 'package:flutter/material.dart';

/// Design tokens for the PhoneAsWatch interface.
///
/// The palette leans into a deep-space dark canvas with vivid, high-chroma
/// accents so each biometric domain keeps a distinct identity.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Canvas & surfaces
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFF06090F);
  static const Color backgroundAlt = Color(0xFF0A1019);
  static const Color surface = Color(0xFF0E141E);
  static const Color surfaceElevated = Color(0xFF151D2A);
  static const Color surfaceHigh = Color(0xFF1B2534);
  static const Color surfaceBorder = Color(0xFF233044);

  /// Translucent fills used by glass panels.
  static const Color glassFill = Color(0xB30E141E);
  static const Color glassHighlight = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x24FFFFFF);

  // ---------------------------------------------------------------------------
  // Heart rate / PPG (Coral)
  // ---------------------------------------------------------------------------
  static const Color heartRatePrimary = Color(0xFFFF4D6D);
  static const Color heartRateSecondary = Color(0xFFFF8FA3);
  static const Color heartRateGlow = Color(0x55FF4D6D);
  static const Color heartRateBg = Color(0x1FFF4D6D);

  // ---------------------------------------------------------------------------
  // Activity / Pedometer (Volt lime)
  // ---------------------------------------------------------------------------
  static const Color activityPrimary = Color(0xFFC8F751);
  static const Color activitySecondary = Color(0xFFE7FF9E);
  static const Color activityGlow = Color(0x55C8F751);
  static const Color activityBg = Color(0x1FC8F751);

  // ---------------------------------------------------------------------------
  // Barometer / Altimeter (Electric cyan)
  // ---------------------------------------------------------------------------
  static const Color barometerPrimary = Color(0xFF3CE5FF);
  static const Color barometerSecondary = Color(0xFF9AF3FF);
  static const Color barometerBg = Color(0x1F3CE5FF);

  // ---------------------------------------------------------------------------
  // Sleep / Sonar (Ultraviolet)
  // ---------------------------------------------------------------------------
  static const Color sleepPrimary = Color(0xFF8B5CF6);
  static const Color sleepSecondary = Color(0xFFC4B5FD);
  static const Color sleepDeep = Color(0xFF5B21B6);
  static const Color sleepLight = Color(0xFF9F8CFB);
  static const Color sleepAwake = Color(0xFFFFB86B);
  static const Color sleepSnore = Color(0xFFFF6B81);
  static const Color sleepBg = Color(0x1F8B5CF6);

  // ---------------------------------------------------------------------------
  // Typography
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF5F8FC);
  static const Color textSecondary = Color(0xFFA8B5C7);
  static const Color textMuted = Color(0xFF6B7A90);

  // ---------------------------------------------------------------------------
  // Semantic status
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF7DF5A4);
  static const Color warning = Color(0xFFFFC24B);
  static const Color danger = Color(0xFFFF5C7C);
  static const Color info = Color(0xFF7DD3FC);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------
  static const LinearGradient activityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE7FF9E), Color(0xFFC8F751), Color(0xFF6BE08A)],
  );

  static const LinearGradient heartGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8FA3), Color(0xFFFF4D6D), Color(0xFFFF2E63)],
  );

  static const LinearGradient sleepGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC4B5FD), Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  );

  static const LinearGradient aquaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9AF3FF), Color(0xFF3CE5FF), Color(0xFF0EA5E9)],
  );

  static const LinearGradient canvasGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1019), Color(0xFF06090F)],
    stops: [0.0, 0.55],
  );

  /// Primary "ink" gradient used for headline accents.
  static const LinearGradient headlineGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF5F8FC), Color(0xFFB9C6D9)],
  );
}
