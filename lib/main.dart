import 'package:driver_assist/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:driver_assist/theme/app_theme.dart';
import 'package:driver_assist/screens/splash_screen.dart';
import 'package:driver_assist/screens/login_screen.dart';
import 'package:driver_assist/screens/register_screen.dart';
import 'package:driver_assist/screens/main_navigation_screen.dart';
import 'package:driver_assist/screens/profile_screen.dart';
import 'package:driver_assist/screens/services_screen.dart';
import 'package:driver_assist/screens/emergency_screen.dart';
import 'package:driver_assist/screens/settings_screen.dart';
import 'package:driver_assist/screens/onboarding_screen.dart';
import 'package:driver_assist/screens/change_password_screen.dart';
import 'package:driver_assist/providers/auth_provider.dart';
import 'package:driver_assist/providers/location_provider.dart';
import 'package:driver_assist/providers/theme_provider.dart';
import 'package:driver_assist/providers/saved_locations_provider.dart';
import 'package:driver_assist/providers/biometric_provider.dart';
import 'package:driver_assist/utils/constants.dart';
import 'package:driver_assist/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePreference();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => SavedLocationsProvider()),
        ChangeNotifierProvider(create: (_) => BiometricProvider()),
        Provider<NotificationService>(
          create: (_) => notificationService,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'DriverAssist',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            navigatorKey: NotificationService.navigatorKey,
            initialRoute: AppConstants.splashRoute,
            routes: {
              AppConstants.splashRoute: (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              AppConstants.loginRoute: (context) => const LoginScreen(),
              AppConstants.registerRoute: (context) => const RegisterScreen(),
              AppConstants.homeRoute: (context) => const MainNavigationScreen(),
              AppConstants.profileRoute: (context) => const ProfileScreen(),
              AppConstants.servicesRoute: (context) => const ServicesScreen(),
              AppConstants.emergencyRoute: (context) => const EmergencyScreen(),
              AppConstants.settingsRoute: (context) => const SettingsScreen(),
              '/change-password': (context) => const ChangePasswordScreen(),
            },
          );
        },
      ),
    ),
  );
}