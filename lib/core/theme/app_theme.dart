import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.activityPrimary,
      onPrimary: Color(0xFF0B1207),
      secondary: AppColors.heartRatePrimary,
      onSecondary: Colors.white,
      tertiary: AppColors.barometerPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceElevated,
      outline: AppColors.surfaceBorder,
      error: AppColors.danger,
    );

    final baseTextTheme = Typography.material2021().white.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
          fontFamily: 'Roboto',
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      primaryColor: AppColors.activityPrimary,
      cardColor: AppColors.surface,
      dividerColor: AppColors.surfaceBorder,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.6,
          height: 1.05,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.9,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 14,
          height: 1.45,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 13,
          height: 1.4,
          color: AppColors.textSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 11,
          height: 1.35,
          color: AppColors.textMuted,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: AppColors.textMuted,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
