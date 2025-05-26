import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'Terms of Service\n\n'
            '1. Acceptance of Terms\n'
            'By using this app, you agree to these terms...\n\n'
            '2. User Responsibilities\n'
            'You agree to use the app responsibly...\n\n'
            '3. Limitation of Liability\n'
            'We are not liable for any damages...\n\n'
            '4. Changes to Terms\n'
            'We may update these terms at any time.\n\n'
            'For the full terms, please contact support.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
} 