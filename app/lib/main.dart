import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/easy_word_provider.dart';
import 'theme/app_colors.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final userStr = prefs.getString('current_user');
  final onboarded = prefs.getBool('is_onboarded') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => EasyReadProvider(
        initialToken: token,
        initialUserJson: userStr,
        initialIsOnboarded: onboarded || (token != null && token.isNotEmpty),
      ),
      child: const EasyReadApp(),
    ),
  );

  // Initialize Native & Firebase Push Notifications asynchronously (never blocks UI)
  PushNotificationService.initialize();
}

class EasyReadApp extends StatelessWidget {
  const EasyReadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Read',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.moss,
          primary: AppColors.ink,
          secondary: AppColors.gold,
          surface: AppColors.paper,
        ),
        useMaterial3: true,
      ),
      home: Consumer<EasyReadProvider>(
        builder: (context, provider, child) {
          if (provider.isOnboarding) {
            return const OnboardingScreen();
          }
          return const MainNavigationScreen();
        },
      ),
    );
  }
}
