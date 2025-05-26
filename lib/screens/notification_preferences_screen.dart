import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_assist/utils/constants.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _isLoading = true;
  Map<String, bool> _preferences = {
    'pushNotifications': true,
    'maintenanceReminders': true,
    'serviceUpdates': true,
    'emergencyAlerts': true,
    'promotionalUpdates': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final userId = AppConstants.currentUserId;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data['notificationPreferences'] != null) {
          setState(() {
            _preferences = Map<String, bool>.from(data['notificationPreferences']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updatePreference(String key, bool value) async {
    try {
      final userId = AppConstants.currentUserId;

      setState(() {
        _preferences[key] = value;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'notificationPreferences.$key': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating notification preference: $e');
      // Revert the change if there was an error
      setState(() {
        _preferences[key] = !value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPreferenceTile(
            'Push Notifications',
            'Enable all app notifications',
            'pushNotifications',
            Icons.notifications,
          ),
          _buildPreferenceTile(
            'Maintenance Reminders',
            'Get notified about upcoming maintenance',
            'maintenanceReminders',
            Icons.build,
          ),
          _buildPreferenceTile(
            'Service Updates',
            'Receive updates about your service requests',
            'serviceUpdates',
            Icons.engineering,
          ),
          _buildPreferenceTile(
            'Emergency Alerts',
            'Get notified about emergency situations',
            'emergencyAlerts',
            Icons.warning,
          ),
          _buildPreferenceTile(
            'Promotional Updates',
            'Receive promotional offers and updates',
            'promotionalUpdates',
            Icons.local_offer,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile(
    String title,
    String subtitle,
    String preferenceKey,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: _preferences[preferenceKey] ?? false,
        onChanged: (value) => _updatePreference(preferenceKey, value),
        secondary: Icon(icon),
      ),
    );
  }
} 