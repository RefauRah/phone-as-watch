import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/activity/presentation/controllers/activity_controller.dart';
import 'features/heart_rate/presentation/controllers/heart_rate_controller.dart';
import 'features/sleep/presentation/controllers/sleep_controller.dart';
import 'presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw edge-to-edge behind the translucent status / navigation bars.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Prevent unexpected rotation during camera PPG or mattress bed tracking.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const PhoneAsWatchApp());
}

class PhoneAsWatchApp extends StatelessWidget {
  const PhoneAsWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HeartRateController>(
          create: (_) => HeartRateController(),
        ),
        ChangeNotifierProvider<ActivityController>(
          create: (_) => ActivityController(),
        ),
        ChangeNotifierProvider<SleepController>(
          create: (_) => SleepController(),
        ),
      ],
      child: MaterialApp(
        title: 'PhoneAsWatch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const DashboardScreen(),
      ),
    );
  }
}
