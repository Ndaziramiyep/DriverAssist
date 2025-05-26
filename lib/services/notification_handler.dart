import 'package:flutter/material.dart';
import 'package:driver_assist/screens/vehicle_details_screen.dart';
import 'package:driver_assist/screens/service_history_screen.dart';

class NotificationHandler {
  static void handleNotificationTap(BuildContext context, String type, Map<String, dynamic> data) {
    switch (type) {
      case 'vehicle_added':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailsScreen(vehicleId: data['vehicleId']),
          ),
        );
        break;
      case 'service_history':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceHistoryScreen(),
          ),
        );
        break;
      case 'maintenance_reminder':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailsScreen(vehicleId: data['vehicleId']),
          ),
        );
        break;
      case 'emergency_alert':
        // Handle emergency alert navigation
        break;
      case 'service_update':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceHistoryScreen(),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown notification type')),
        );
    }
  }
} 