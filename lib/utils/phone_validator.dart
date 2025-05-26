import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class PhoneValidator {
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }

    // Remove any non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Basic length validation (most phone numbers are between 7 and 15 digits)
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  static Future<String?> validatePhoneNumberWithCountry(
    String? value,
    String countryCode,
  ) async {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }

    try {
      // Parse the phone number with country code
      final phoneNumber = await PhoneNumber.getRegionInfoFromPhoneNumber(value);
      
      // Check if the number is valid for the given country
      if (phoneNumber.phoneNumber == null) {
        return 'Please enter a valid phone number for $countryCode';
      }

      return null;
    } catch (e) {
      return 'Invalid phone number format';
    }
  }
} 