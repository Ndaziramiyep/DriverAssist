import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:driver_assist/services/notification_handler.dart';
import 'package:driver_assist/utils/constants.dart';
import 'package:driver_assist/services/firebase_messaging_handler.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    debugPrint('Initializing NotificationService...');
    
    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    final initialized = await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    debugPrint('Local notifications initialized: $initialized');

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'default_channel',
      'Default Channel',
      description: 'Default notification channel',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
      playSound: true,
    );
    
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
      debugPrint('Notification channel creation attempted');
    }

    // Request permission for notifications
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    // Get FCM token and save it to Firestore
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
    if (token != null) {
      await _saveFcmToken(token);
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      _saveFcmToken(newToken);
    });
  }

  Future<void> _saveFcmToken(String token) async {
    final userId = AppConstants.currentUserId;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        // Create user document with default notification preferences
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'notificationPreferences': {
            'pushNotifications': true,
            'maintenanceReminders': true,
            'serviceUpdates': true,
            'emergencyAlerts': true,
            'promotionalUpdates': false,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update FCM token
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Message tapped: ${message.data}');
    final context = navigatorKey.currentContext;
    if (context != null) {
      NotificationHandler.handleNotificationTap(
        context,
        message.data['type'] ?? 'default',
        message.data,
      );
    }
  }

  Future<void> _onNotificationTap(NotificationResponse response) async {
    debugPrint('Local notification tapped: ${response.payload}');
    final context = navigatorKey.currentContext;
    if (context != null && response.payload != null) {
      try {
        final data = Map<String, dynamic>.from(
          Map<String, dynamic>.from(response.payload as Map),
        );
        NotificationHandler.handleNotificationTap(
          context,
          data['type'] ?? 'default',
          data,
        );
      } catch (e) {
        debugPrint('Error handling notification tap: $e');
      }
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/launcher_icon',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      color: Color(0xFF2196F3),
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
      debugPrint('Local notification shown successfully with id: $id');
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  Future<bool> _shouldSendNotification(String type) async {
    try {
      final userId = AppConstants.currentUserId;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final preferences = userDoc.data()?['notificationPreferences'] as Map<String, dynamic>?;
      if (preferences == null) return false;

      // Check if push notifications are enabled globally
      if (!(preferences['pushNotifications'] ?? false)) return false;

      // Check specific notification type
      switch (type) {
        case 'maintenance_reminder':
          return preferences['maintenanceReminders'] ?? false;
        case 'service_update':
          return preferences['serviceUpdates'] ?? false;
        case 'emergency_alert':
          return preferences['emergencyAlerts'] ?? false;
        case 'promotional':
          return preferences['promotionalUpdates'] ?? false;
        default:
          return true;
      }
    } catch (e) {
      debugPrint('Error checking notification preferences: $e');
      return false;
    }
  }

  Future<void> sendVehicleAddedNotification({
    required String userId,
    required String vehicleId,
    required String vehicleName,
  }) async {
    if (!await _shouldSendNotification('service_update')) return;
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        // Add to notifications collection with proper timestamp
        final notificationData = {
          'userId': userId,
          'type': 'vehicle_added',
          'title': 'New Vehicle Added',
          'body': 'Your vehicle $vehicleName has been added successfully',
          'data': {
            'vehicleId': vehicleId,
            'type': 'vehicle_added',
          },
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Save to Firestore
        await _firestore.collection('notifications').add(notificationData);
        debugPrint('Notification saved to Firestore for vehicle: $vehicleName');

        // Show local notification immediately
        await _showLocalNotification(
          title: 'New Vehicle Added',
          body: 'Your vehicle $vehicleName has been added successfully',
          payload: {
            'type': 'vehicle_added',
            'vehicleId': vehicleId,
          }.toString(),
        );
      }
    } catch (e) {
      debugPrint('Error sending vehicle added notification: $e');
    }
  }

  // Add a method to get notifications
  Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add a method to mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Add a method to delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> sendServiceHistoryNotification({
    required String userId,
    required String vehicleId,
    required String serviceType,
  }) async {
    if (!await _shouldSendNotification('service_update')) return;
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'service_history',
          'title': 'Service History Updated',
          'body': 'New $serviceType service has been added to your vehicle',
          'data': {
            'vehicleId': vehicleId,
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error sending service history notification: $e');
    }
  }

  Future<void> sendMaintenanceReminder({
    required String userId,
    required String vehicleId,
    required String maintenanceType,
    required DateTime dueDate,
  }) async {
    if (!await _shouldSendNotification('maintenance_reminder')) return;
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'maintenance_reminder',
          'title': 'Maintenance Reminder',
          'body': '$maintenanceType is due in 3 days',
          'data': {
            'vehicleId': vehicleId,
            'dueDate': Timestamp.fromDate(dueDate),
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error sending maintenance reminder: $e');
    }
  }

  Future<void> sendServiceUpdate({
    required String userId,
    required String serviceId,
    required String status,
    required String serviceType,
  }) async {
    if (!await _shouldSendNotification('service_update')) return;
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'service_update',
          'title': 'Service Update',
          'body': 'Your $serviceType service status has been updated to $status',
          'data': {
            'serviceId': serviceId,
            'status': status,
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error sending service update: $e');
    }
  }

  Future<void> sendEmergencyAlert({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> emergencyData,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'emergency_alert',
          'title': title,
          'body': body,
          'data': emergencyData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error sending emergency alert: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  Future<void> scheduleMaintenanceReminder({
    required String userId,
    required String vehicleId,
    required String maintenanceType,
    required DateTime dueDate,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'maintenance_reminder',
          'title': 'Maintenance Reminder',
          'body': '$maintenanceType is due in 3 days',
          'data': {
            'vehicleId': vehicleId,
            'dueDate': Timestamp.fromDate(dueDate),
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error scheduling maintenance reminder: $e');
    }
  }

  Future<void> cancelMaintenanceReminder(String reminderId) async {
    try {
      await _firestore.collection('notifications').doc(reminderId).delete();
      debugPrint('Cancelled maintenance reminder: $reminderId');
    } catch (e) {
      debugPrint('Error cancelling maintenance reminder: $e');
    }
  }
}