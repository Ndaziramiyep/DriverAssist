import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_assist/models/maintenance_reminder_model.dart';
import 'package:driver_assist/models/service_history_model.dart';
import 'package:driver_assist/models/vehicle_model.dart';
import 'package:driver_assist/services/notification_service.dart';
import 'package:flutter/foundation.dart';

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService;

  MaintenanceService(this._notificationService);

  // Service History Methods
  Future<void> addServiceHistory(ServiceHistoryModel service) async {
    await _firestore.collection('service_history').doc(service.id).set(service.toMap());
    
    // Update vehicle's last service date and mileage
    await _firestore.collection('vehicles').doc(service.vehicleId).update({
      'lastServiceDate': service.serviceDate,
      'mileage': service.mileage,
    });
  }

  Stream<List<ServiceHistoryModel>> getServiceHistory(String vehicleId) {
    return _firestore
        .collection('service_history')
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('serviceDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceHistoryModel.fromFirestore(doc))
            .toList());
  }

  // Maintenance Reminder Methods
  Future<void> addMaintenanceReminder(MaintenanceReminderModel reminder) async {
    try {
      await _firestore
          .collection('maintenance_reminders')
          .doc(reminder.id)
          .set(reminder.toMap());

      await _notificationService.scheduleMaintenanceReminder(
        userId: reminder.userId,
        vehicleId: reminder.vehicleId,
        maintenanceType: reminder.type,
        dueDate: reminder.dueDate,
      );
    } catch (e) {
      debugPrint('Error adding maintenance reminder: $e');
      rethrow;
    }
  }

  Stream<List<MaintenanceReminderModel>> getMaintenanceReminders(String vehicleId) {
    return _firestore
        .collection('maintenance_reminders')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceReminderModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateMaintenanceReminder(MaintenanceReminderModel reminder) async {
    try {
      await _firestore
          .collection('maintenance_reminders')
          .doc(reminder.id)
          .update(reminder.toMap());

      if (!reminder.isCompleted) {
        await _notificationService.scheduleMaintenanceReminder(
          userId: reminder.userId,
          vehicleId: reminder.vehicleId,
          maintenanceType: reminder.type,
          dueDate: reminder.dueDate,
        );
      } else {
        await _notificationService.cancelMaintenanceReminder(reminder.id);
      }
    } catch (e) {
      debugPrint('Error updating maintenance reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteMaintenanceReminder(String reminderId) async {
    await _firestore.collection('maintenance_reminders').doc(reminderId).delete();
    await _notificationService.cancelMaintenanceReminder(reminderId);
  }

  // Check for upcoming maintenance
  Future<List<MaintenanceReminderModel>> getUpcomingMaintenance(String vehicleId) async {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    final snapshot = await _firestore
        .collection('maintenance_reminders')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('isCompleted', isEqualTo: false)
        .where('dueDate', isLessThanOrEqualTo: thirtyDaysFromNow)
        .orderBy('dueDate')
        .get();

    return snapshot.docs
        .map((doc) => MaintenanceReminderModel.fromFirestore(doc))
        .toList();
  }

  // Check if vehicle needs service based on mileage
  Future<bool> checkMileageBasedMaintenance(VehicleModel vehicle) async {
    final reminders = await _firestore
        .collection('maintenance_reminders')
        .where('vehicleId', isEqualTo: vehicle.id)
        .where('isCompleted', isEqualTo: false)
        .where('reminderType', isEqualTo: 'mileage')
        .get();

    for (var doc in reminders.docs) {
      final reminder = MaintenanceReminderModel.fromFirestore(doc);
      if (reminder.dueMileage != null && vehicle.mileage >= reminder.dueMileage!) {
        return true;
      }
    }
    return false;
  }
}