import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MaintenanceReminderModel {
  final String id;
  final String userId;
  final String vehicleId;
  final String type;
  final String title;
  final String description;
  final DateTime dueDate;
  final int? dueMileage;
  final String reminderType; // 'date' or 'mileage'
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? serviceProviderId;
  final String? serviceProviderName;
  final String? notes;
  final int priority; // 1: Low, 2: Medium, 3: High

  MaintenanceReminderModel({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.type,
    required this.title,
    required this.description,
    required this.dueDate,
    this.dueMileage,
    required this.reminderType,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.serviceProviderId,
    this.serviceProviderName,
    this.notes,
    this.priority = 2,
  });

  factory MaintenanceReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaintenanceReminderModel(
      id: doc.id,
      userId: data['userId'] as String,
      vehicleId: data['vehicleId'] as String,
      type: data['type'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      dueMileage: data['dueMileage'] as int?,
      reminderType: data['reminderType'] as String,
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      serviceProviderId: data['serviceProviderId'],
      serviceProviderName: data['serviceProviderName'],
      notes: data['notes'],
      priority: data['priority'] ?? 2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleId': vehicleId,
      'type': type,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'dueMileage': dueMileage,
      'reminderType': reminderType,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'serviceProviderId': serviceProviderId,
      'serviceProviderName': serviceProviderName,
      'notes': notes,
      'priority': priority,
    };
  }

  MaintenanceReminderModel copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? type,
    String? title,
    String? description,
    DateTime? dueDate,
    int? dueMileage,
    String? reminderType,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    String? serviceProviderId,
    String? serviceProviderName,
    String? notes,
    int? priority,
  }) {
    return MaintenanceReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueMileage: dueMileage ?? this.dueMileage,
      reminderType: reminderType ?? this.reminderType,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      serviceProviderName: serviceProviderName ?? this.serviceProviderName,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
    );
  }

  bool get isOverdue {
    if (reminderType == 'date') {
      return DateTime.now().isAfter(dueDate);
    }
    return false; // For mileage-based reminders, we'll check in the service
  }

  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Medium';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}