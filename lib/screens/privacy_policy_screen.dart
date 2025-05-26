import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            '1. Data Collection\n'
            'We collect personal information to provide our services...\n\n'
            '2. Data Usage\n'
            'Your data is used to improve your experience...\n\n'
            '3. Data Sharing\n'
            'We do not share your data with third parties except as required by law...\n\n'
            '4. Changes to Policy\n'
            'We may update this policy at any time.\n\n'
            'For questions, please contact support.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
} 