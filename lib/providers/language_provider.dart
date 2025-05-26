import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  final SharedPreferences _prefs;
  Locale _currentLocale;

  LanguageProvider(this._prefs)
      : _currentLocale = Locale(_prefs.getString(_languageKey) ?? 'en');

  Locale get currentLocale => _currentLocale;

  static final Map<String, String> supportedLanguages = {
    'en': 'English',
    'rw': 'Kinyarwanda',
    'fr': 'French',
  };

  Future<void> setLanguage(String languageCode) async {
    if (supportedLanguages.containsKey(languageCode)) {
      _currentLocale = Locale(languageCode);
      await _prefs.setString(_languageKey, languageCode);
      notifyListeners();
    }
  }

  String getLanguageName(String code) {
    return supportedLanguages[code] ?? code;
  }

  String get currentLanguageName => getLanguageName(_currentLocale.languageCode);
} 