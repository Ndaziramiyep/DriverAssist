import 'package:firebase_auth/firebase_auth.dart';

class AppConstants {
  // User ID
  static String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // API Keys and Endpoints
  static const String googleMapsApiKey = 'AIzaSyCFftlppEpk7iKIe_k2leWaO5kyjX2dZNk';
  
  // Storage Keys
  static const String userPrefsKey = 'user_preferences';
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  
  // Route Names
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String servicesRoute = '/services';
  static const String emergencyRoute = '/emergency';
  static const String settingsRoute = '/settings';
  
  // Service Types
  static const String fuelService = 'fuel';
  static const String chargingService = 'charging';
  static const String mechanicService = 'mechanic';
  static const String emergencyService = 'emergency';
  
  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String locationError = 'Unable to access location. Please enable location services.';
  
  // Success Messages
  static const String registrationSuccess = 'Account created successfully!';
  static const String loginSuccess = 'Welcome back!';
  static const String profileUpdateSuccess = 'Profile updated successfully!';
  
  // Map Constants
  static const double defaultZoom = 15.0;
  static const double defaultLatitude = -1.9403; // Rwanda's approximate center
  static const double defaultLongitude = 29.8739;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
}