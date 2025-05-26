import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Screen tracking
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  // User actions
  Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  Future<void> logServiceRequest({
    required String serviceType,
    required String serviceProviderId,
    required double amount,
  }) async {
    await _analytics.logEvent(
      name: 'service_request',
      parameters: {
        'service_type': serviceType,
        'service_provider_id': serviceProviderId,
        'amount': amount,
      },
    );
  }

  Future<void> logEmergencyRequest({
    required String emergencyType,
    required String location,
  }) async {
    await _analytics.logEvent(
      name: 'emergency_request',
      parameters: {'emergency_type': emergencyType, 'location': location},
    );
  }

  Future<void> logUserRegistration({
    required String method,
    required bool success,
  }) async {
    await _analytics.logEvent(
      name: 'user_registration',
      parameters: {'method': method, 'success': success},
    );
  }

  Future<void> logUserLogin({
    required String method,
    required bool success,
  }) async {
    await _analytics.logEvent(
      name: 'user_login',
      parameters: {'method': method, 'success': success},
    );
  }

  // Service provider interactions
  Future<void> logServiceProviderView({
    required String serviceProviderId,
    required String serviceType,
  }) async {
    await _analytics.logEvent(
      name: 'service_provider_view',
      parameters: {
        'service_provider_id': serviceProviderId,
        'service_type': serviceType,
      },
    );
  }

  Future<void> logServiceProviderContact({
    required String serviceProviderId,
    required String contactMethod,
  }) async {
    await _analytics.logEvent(
      name: 'service_provider_contact',
      parameters: {
        'service_provider_id': serviceProviderId,
        'contact_method': contactMethod,
      },
    );
  }

  // App performance
  Future<void> logAppPerformance({
    required String metric,
    required double value,
  }) async {
    await _analytics.logEvent(
      name: 'app_performance',
      parameters: {'metric': metric, 'value': value},
    );
  }

  // Error tracking
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
      },
    );
  }

  // User preferences
  Future<void> logUserPreference({
    required String preference,
    required String value,
  }) async {
    await _analytics.logEvent(
      name: 'user_preference',
      parameters: {'preference': preference, 'value': value},
    );
  }

  // Feature usage
  Future<void> logFeatureUsage({
    required String feature,
    required bool success,
    String? errorMessage,
  }) async {
    await _analytics.logEvent(
      name: 'feature_usage',
      parameters: {
        'feature': feature,
        'success': success,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
  }

  // Get analytics observer for navigation
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // Set user properties
  Future<void> setUserProperties({
    required String userId,
    required String userType,
    String? userLocation,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'user_type', value: userType);
    if (userLocation != null) {
      await _analytics.setUserProperty(
        name: 'user_location',
        value: userLocation,
      );
    }
  }
}
