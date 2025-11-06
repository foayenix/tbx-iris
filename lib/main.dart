// lib/main.dart
// Main entry point for the Iris wellness and art app

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/camera/presentation/screens/iris_camera_screen_v2.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Set preferred orientations (portrait mode primarily)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Check if user has completed onboarding
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
  final hasAcceptedDisclaimer = prefs.getBool('has_accepted_disclaimer') ?? false;

  runApp(
    ProviderScope(
      child: IrisApp(
        showOnboarding: !hasCompletedOnboarding || !hasAcceptedDisclaimer,
      ),
    ),
  );
}

class IrisApp extends StatelessWidget {
  final bool showOnboarding;

  const IrisApp({
    super.key,
    this.showOnboarding = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iris - Wellness & Art',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Initial route
      home: showOnboarding
          ? const OnboardingScreen()
          : const IrisCameraScreenV2(),

      // Routes
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/camera': (context) => const IrisCameraScreenV2(),
      },
    );
  }
}
