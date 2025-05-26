import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_assist/services/biometric_service.dart';
import 'package:driver_assist/services/secure_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BiometricProvider with ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final BiometricService _biometricService = BiometricService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  String? _error;

  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isBiometricAvailable => _isBiometricAvailable;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  String? get error => _error;

  BiometricProvider() {
    _initializeBiometrics();
  }

  Future<void> _initializeBiometrics() async {
    try {
      _isBiometricAvailable = await _localAuth.canCheckBiometrics;
      _availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      // Load saved preference
      final prefs = await SharedPreferences.getInstance();
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize biometrics: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> setBiometricEnabled(bool value) async {
    try {
      if (value) {
        // Authenticate before enabling
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric login',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!authenticated) {
          _error = 'Authentication failed';
          notifyListeners();
          return;
        }
      }

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', value);
      
      _isBiometricEnabled = value;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to set biometric state: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<bool> authenticate() async {
    try {
      if (!_isBiometricEnabled) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      _error = 'Authentication failed: $e';
      debugPrint(_error);
      return false;
    }
  }

  // Store credentials after successful login
  Future<void> storeCredentialsAfterLogin(String email, String password) async {
    if (_isBiometricEnabled) {
      await _secureStorage.storeCredentials(email, password);
    }
  }
} 