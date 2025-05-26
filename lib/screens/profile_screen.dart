import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:driver_assist/utils/constants.dart';
import 'package:driver_assist/screens/personal_info_screen.dart';
import 'package:driver_assist/screens/service_history_screen.dart';
import 'package:driver_assist/screens/vehicle_management_screen.dart';
import 'package:driver_assist/screens/saved_locations_screen.dart';
import 'package:driver_assist/screens/emergency_contacts_screen.dart';
import 'package:driver_assist/screens/notifications_screen.dart';
import 'package:driver_assist/screens/privacy_policy_screen.dart';
import 'package:driver_assist/screens/terms_of_service_screen.dart';
import 'package:driver_assist/providers/biometric_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Stream<DocumentSnapshot> _getUserDataStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
       return Stream.empty();
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.settingsRoute);
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _getUserDataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'User not logged in or profile data not found',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final user = FirebaseAuth.instance.currentUser;
          final name = data?['name'] ?? 'User';
          final email = (data?['email'] ?? user?.email) ?? '';
          final base64Img = data?['profileImageBase64'];
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      backgroundImage: base64Img != null
                          ? MemoryImage(base64Decode(base64Img))
                          : null,
                      child: base64Img == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                'Account',
                [
                  _buildProfileTile(
                    context,
                    'Personal Information',
                    Icons.person_outline,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PersonalInfoScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileTile(
                    context,
                    'Vehicle Information',
                    Icons.directions_car_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VehicleManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileTile(
                    context,
                    'Payment Methods',
                    Icons.payment_outlined,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment methods management will be available in a future update!'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    subtitle: 'Add and manage payment methods',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Services',
                [
                  _buildProfileTile(
                    context,
                    'Service History',
                    Icons.history,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServiceHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileTile(
                    context,
                    'Saved Locations',
                    Icons.location_on_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedLocationsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileTile(
                    context,
                    'Emergency Contacts',
                    Icons.emergency_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencyContactsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Preferences',
                [
                  _buildProfileTile(
                    context,
                    'Notifications',
                    Icons.notifications,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationsScreen()),
                      );
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
                  _buildProfileTile(
                    context,
                    'Privacy & Security',
                    Icons.security_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacySecurityScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
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

  Widget _buildProfileTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    {String? subtitle}
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      subtitle: subtitle != null ? Text(subtitle) : null,
    );
  }
}

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Manage your privacy and security settings. You can review our policies and enable biometric authentication for extra security.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
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
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          Consumer<BiometricProvider>(
            builder: (context, biometricProvider, _) {
              if (!biometricProvider.isBiometricAvailable) {
                return const ListTile(
                  leading: Icon(Icons.fingerprint),
                  title: Text('Biometric Authentication'),
                  subtitle: Text('Not available on this device'),
                );
              }

              final hasFingerprint = biometricProvider.availableBiometrics.contains(BiometricType.fingerprint);
              final hasFaceId = biometricProvider.availableBiometrics.contains(BiometricType.face);
              final hasIris = biometricProvider.availableBiometrics.contains(BiometricType.iris);

              String subtitle = 'Not configured';
              if (hasFingerprint) subtitle = 'Use fingerprint to unlock';
              else if (hasFaceId) subtitle = 'Use Face ID to unlock';
              else if (hasIris) subtitle = 'Use iris scan to unlock';

              return Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Biometric Authentication'),
                    subtitle: Text(subtitle),
                    value: biometricProvider.isBiometricEnabled,
                    onChanged: (value) async {
                      try {
                        await biometricProvider.setBiometricEnabled(value);
                        if (biometricProvider.error != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(biometricProvider.error!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? 'Biometric authentication enabled' : 'Biometric authentication disabled'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  if (biometricProvider.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        biometricProvider.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}