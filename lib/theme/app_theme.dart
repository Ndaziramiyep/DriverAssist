import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1E88E5); // Professional blue
  static const Color secondaryColor = Color(0xFF42A5F5); // Lighter blue
  static const Color accentColor = Color(0xFFFFA726); // Orange accent
  static const Color errorColor = Color(0xFFE53935); // Red for errors
  static const Color successColor = Color(0xFF43A047); // Green for success
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light gray background
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: textPrimaryColor),
          displayMedium: TextStyle(color: textPrimaryColor),
          displaySmall: TextStyle(color: textPrimaryColor),
          headlineLarge: TextStyle(color: textPrimaryColor),
          headlineMedium: TextStyle(color: textPrimaryColor),
          headlineSmall: TextStyle(color: textPrimaryColor),
          titleLarge: TextStyle(color: textPrimaryColor),
          titleMedium: TextStyle(color: textPrimaryColor),
          titleSmall: TextStyle(color: textPrimaryColor),
          bodyLarge: TextStyle(color: textPrimaryColor),
          bodyMedium: TextStyle(color: textPrimaryColor),
          bodySmall: TextStyle(color: textSecondaryColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: errorColor),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: const Color(0xFF222831),
      ),
      scaffoldBackgroundColor: const Color(0xFF181A20),
      textTheme: GoogleFonts.poppinsTextTheme(
        TextTheme(
          displayLarge: const TextStyle(color: Colors.white),
          displayMedium: const TextStyle(color: Colors.white),
          displaySmall: const TextStyle(color: Colors.white),
          headlineLarge: const TextStyle(color: Colors.white),
          headlineMedium: const TextStyle(color: Colors.white),
          headlineSmall: const TextStyle(color: Colors.white),
          titleLarge: const TextStyle(color: Colors.white),
          titleMedium: const TextStyle(color: Colors.white),
          titleSmall: const TextStyle(color: Colors.white),
          bodyLarge: const TextStyle(color: Colors.white),
          bodyMedium: const TextStyle(color: Colors.white),
          bodySmall: const TextStyle(color: Colors.white70),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF222831),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF222831),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: errorColor),
        ),
      ),
    );
  }
}