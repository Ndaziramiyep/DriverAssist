import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:driver_assist/providers/auth_provider.dart' as app_auth;
import 'package:driver_assist/widgets/animated_mic_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final VoidCallback onSearchTap;
  final VoidCallback onVoiceSearchTap;
  final VoidCallback onProfileTap;
  final bool isListening;

  const CustomAppBar({
    super.key,
    required this.searchController,
    required this.onSearchTap,
    required this.onVoiceSearchTap,
    required this.onProfileTap,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      title: Row(
        children: [
          // App Name
          Text(
            'DriverAssist',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          // Search Bar
          Flexible(
            child: GestureDetector(
              onTap: onSearchTap,
              child: Container(
                height: 36,
                constraints: const BoxConstraints(minWidth: 80, maxWidth: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Search location',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Voice Search Button
          SizedBox(
            width: 48,
            height: 48,
            child: AnimatedMicButton(
              isListening: isListening,
              onTap: onVoiceSearchTap,
            ),
          ),
          const SizedBox(width: 6),
          // Profile Picture
          StreamBuilder<DocumentSnapshot>(
            stream: _userDocStream(),
            builder: (context, snapshot) {
              String? base64Img;
              String initials = 'U';
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                base64Img = data['profileImageBase64'];
                final name = data['name'] ?? '';
                initials = _getUserInitials(name);
              }
              return PopupMenuButton<String>(
                tooltip: 'Profile options',
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (value) async {
                  if (value == 'profile') {
                    onProfileTap();
                  } else if (value == 'logout') {
                    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
                    await authProvider.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Text('Profile'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: theme.colorScheme.primary,
                  backgroundImage: base64Img != null ? MemoryImage(base64Decode(base64Img)) : null,
                  child: base64Img == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<DocumentSnapshot> _userDocStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Return a dummy stream
      return const Stream.empty();
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
  }

  String _getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    final nameParts = name.split(' ');
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'.toUpperCase();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 