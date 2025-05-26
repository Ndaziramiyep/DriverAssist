import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';

  // Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // Check if biometric authentication is enabled in app settings
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  // Authenticate user with biometrics
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      // Handle specific platform exceptions for better error reporting
      print('Biometric authentication PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled' || e.code == 'NotStrong') {
        // Handle cases where biometrics are not available, not enrolled, or not strong enough
        throw Exception('Biometric authentication is not available or not set up on your device. Please check your device settings.');
      } else if (e.code == 'AuthenticationFailed') {
        // This code can sometimes be too generic, but we can catch it
         throw Exception('Authentication failed. Please try again or use a different method.');
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut'){
         throw Exception('Biometric authentication is locked out. Please unlock your device with PIN/Pattern/Password or try again later.');
      }
       else if (e.code == 'Canceled'){
        // User cancelled the authentication - not necessarily an error for the app flow
        return false;
       }
      
      // For any other unknown platform exception, rethrow it or handle generally
      rethrow; 
    }
  }

  // Check if device has biometrics enrolled
  Future<bool> hasBiometricsEnrolled() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }
} 