class VehicleConstants {
  // Fuel Types
  static const List<String> fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'CNG',
    'LPG',
    'Biofuel',
  ];

  // Year Range
  static int get currentYear => DateTime.now().year;
  static int get minYear => currentYear - 50; // Allow vehicles up to 50 years old
  static int get maxYear => currentYear + 1; // Allow next year's models

  // License Plate Formats by Country (Regex patterns)
  static const Map<String, String> licensePlateFormats = {
    'US': r'^[A-Z0-9]{1,8}$', // Basic US format
    'UK': r'^[A-Z]{2}[0-9]{2}\s?[A-Z]{3}$', // UK format
    'EU': r'^[A-Z]{1,3}[0-9]{1,4}[A-Z]{1,3}$', // Basic EU format
    'CA': r'^[A-Z]{3}[0-9]{3}$', // Basic Canadian format
    // Add more country formats as needed
  };

  // Default country for license plate validation
  static const String defaultCountry = 'US';

  // Validation Messages
  static const Map<String, String> validationMessages = {
    'fuelType': 'Please select a valid fuel type',
    'year': 'Year must be between {minYear} and {maxYear}',
    'licensePlate': 'Please enter a valid license plate number',
    'fuelLevel': 'Fuel level cannot exceed fuel capacity',
  };
} 