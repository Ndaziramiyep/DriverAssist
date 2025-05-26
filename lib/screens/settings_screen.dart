import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:driver_assist/providers/theme_provider.dart';
import 'package:driver_assist/screens/notification_preferences_screen.dart';
import 'package:driver_assist/providers/location_provider.dart';
import 'package:driver_assist/providers/biometric_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:driver_assist/screens/change_password_screen.dart';
import 'package:driver_assist/screens/terms_of_service_screen.dart';
import 'package:driver_assist/screens/privacy_policy_screen.dart';
import 'package:driver_assist/screens/contact_support_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final bool _darkMode = false;
  bool _notificationsEnabled = true;
  final bool _locationEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'RWF';
  final bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('pushNotificationsEnabled') ?? true;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotificationsEnabled', value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance
          _buildSection(
            context,
            'Appearance',
            [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Enable dark theme'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.setDarkMode(value);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String>(
                  value: 'English',
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    prefixIcon: Icon(Icons.language_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'English',
                      child: Text('English'),
                    ),
                  ],
                  onChanged: null, // Disabled
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notifications
          _buildSection(
            context,
            'Notifications',
            [
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive app notifications'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _saveNotificationPreference(value);
                },
              ),
              ListTile(
                title: const Text('Notification Preferences'),
                subtitle: const Text('Customize notification settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPreferencesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Location
          _buildSection(
            context,
            'Location',
            [
              Consumer<LocationProvider>(
                builder: (context, locationProvider, _) => SwitchListTile(
                  title: const Text('Location Services'),
                  subtitle: const Text('Enable location tracking'),
                  value: locationProvider.locationServicesEnabled,
                  onChanged: (value) {
                    locationProvider.setLocationServicesEnabled(value);
                  },
                ),
              ),
              Consumer<LocationProvider>(
                builder: (context, locationProvider, _) => ListTile(
                  title: const Text('Location Accuracy'),
                  subtitle: Text(_getAccuracyLabel(locationProvider.locationAccuracy)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAccuracyDialog(context, locationProvider),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security
          _buildSection(
            context,
            'Security',
            [
              Consumer<BiometricProvider>(
                builder: (context, biometricProvider, _) {
                  if (!biometricProvider.isBiometricAvailable) {
                    return const ListTile(
                      title: Text('Biometric Authentication'),
                      subtitle: Text('Not available on this device'),
                      leading: Icon(Icons.fingerprint),
                    );
                  }

                  return SwitchListTile(
                    title: const Text('Biometric Authentication'),
                    subtitle: Text(
                      biometricProvider.availableBiometrics.contains(BiometricType.fingerprint)
                          ? 'Use fingerprint to unlock'
                          : 'Use Face ID to unlock',
                    ),
                    value: biometricProvider.isBiometricEnabled,
                    onChanged: (value) async {
                      await biometricProvider.setBiometricEnabled(value);
                      if (biometricProvider.error != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(biometricProvider.error!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    secondary: const Icon(Icons.fingerprint),
                  );
                },
              ),
              ListTile(
                title: const Text('Change Password'),
                subtitle: const Text('Update your account password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                  );
                },
              ),
              ListTile(
                title: const Text('Two-Factor Authentication'),
                subtitle: const Text('Coming soon - Enhanced security for your account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Two-Factor Authentication will be available in a future update!'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Payment
          _buildSection(
            context,
            'Payment',
            [
              ListTile(
                title: const Text('Currency'),
                subtitle: const Text('Coming soon - Multiple currency support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Multiple currency support will be available in a future update!'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Payment Methods'),
                subtitle: const Text('Coming soon - Add and manage payment methods'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment methods management will be available in a future update!'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Transaction History'),
                subtitle: const Text('Coming soon - View your payment history'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction history will be available in a future update!'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About
          _buildSection(
            context,
            'About',
            [
              ListTile(
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
                  );
                },
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                  );
                },
              ),
              ListTile(
                title: const Text('Contact Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactSupportScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('English'),
              _buildLanguageOption('Kinyarwanda'),
              _buildLanguageOption('French'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: _selectedLanguage == language
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCurrencyOption('RWF'),
              _buildCurrencyOption('USD'),
              _buildCurrencyOption('EUR'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyOption(String currency) {
    return ListTile(
      title: Text(currency),
      trailing: _selectedCurrency == currency
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        setState(() {
          _selectedCurrency = currency;
        });
        Navigator.pop(context);
      },
    );
  }

  String _getAccuracyLabel(String accuracy) {
    switch (accuracy) {
      case 'high':
        return 'High accuracy (GPS & network)';
      case 'balanced':
        return 'Balanced (Battery saving)';
      case 'low':
        return 'Low (Device only)';
      default:
        return 'Unknown';
    }
  }

  void _showAccuracyDialog(BuildContext context, LocationProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Location Accuracy'),
          children: [
            RadioListTile<String>(
              title: const Text('High accuracy (GPS & network)'),
              value: 'high',
              groupValue: provider.locationAccuracy,
              onChanged: (value) {
                provider.setLocationAccuracy(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Balanced (Battery saving)'),
              value: 'balanced',
              groupValue: provider.locationAccuracy,
              onChanged: (value) {
                provider.setLocationAccuracy(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Low (Device only)'),
              value: 'low',
              groupValue: provider.locationAccuracy,
              onChanged: (value) {
                provider.setLocationAccuracy(value!);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}