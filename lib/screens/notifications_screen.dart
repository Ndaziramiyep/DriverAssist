import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver_assist/services/notification_service.dart';
import 'package:driver_assist/utils/constants.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  final NotificationService _notificationService = NotificationService();

  NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = AppConstants.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearAllDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final id = notifications[index].id;
              final title = notification['title'] as String? ?? 'Notification';
              final body = notification['body'] as String? ?? '';
              final isRead = notification['read'] as bool? ?? false;
              final timestamp = notification['createdAt'] as Timestamp?;
              final date = timestamp?.toDate() ?? DateTime.now();

              return Dismissible(
                key: Key(id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: theme.colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (direction) {
                  _notificationService.deleteNotification(id);
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : theme.colorScheme.primary,
                    child: Icon(
                      _getNotificationIcon(notification['type'] as String?),
                      color: isRead
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onPrimary,
                    ),
                  ),
                  title: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(body),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, y • h:mm a').format(date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!isRead) {
                      _notificationService.markNotificationAsRead(id);
                    }
                    _handleNotificationTap(context, notification);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'vehicle_added':
        return Icons.directions_car;
      case 'maintenance_reminder':
        return Icons.build;
      case 'service_update':
        return Icons.engineering;
      case 'emergency_alert':
        return Icons.emergency;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    final type = notification['type'] as String?;
    final data = notification['data'] as Map<String, dynamic>?;

    switch (type) {
      case 'vehicle_added':
        // Navigate to vehicle details
        if (data != null && data['vehicleId'] != null) {
          // Navigate to vehicle details screen
          // Navigator.pushNamed(context, '/vehicle-details', arguments: data['vehicleId']);
        }
        break;
      case 'maintenance_reminder':
        // Navigate to maintenance screen
        if (data != null && data['vehicleId'] != null) {
          // Navigator.pushNamed(context, '/maintenance', arguments: data['vehicleId']);
        }
        break;
      // Add more cases for different notification types
    }
  }

  Future<void> _showClearAllDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear all notifications
      final userId = AppConstants.currentUserId;
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }
    }
  }
} 