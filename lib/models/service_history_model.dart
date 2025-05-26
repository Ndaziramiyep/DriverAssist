import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceHistoryModel {
  final String id;
  final String vehicleId;
  final String serviceType;
  final String description;
  final DateTime serviceDate;
  final double cost;
  final String serviceProviderId;
  final String serviceProviderName;
  final int mileage;
  final List<String>? attachments;
  final String? notes;
  final bool isCompleted;

  ServiceHistoryModel({
    required this.id,
    required this.vehicleId,
    required this.serviceType,
    required this.description,
    required this.serviceDate,
    required this.cost,
    required this.serviceProviderId,
    required this.serviceProviderName,
    required this.mileage,
    this.attachments,
    this.notes,
    this.isCompleted = true,
  });

  factory ServiceHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceHistoryModel(
      id: doc.id,
      vehicleId: data['vehicleId'] ?? '',
      serviceType: data['serviceType'] ?? '',
      description: data['description'] ?? '',
      serviceDate: (data['serviceDate'] as Timestamp).toDate(),
      cost: (data['cost'] ?? 0.0).toDouble(),
      serviceProviderId: data['serviceProviderId'] ?? '',
      serviceProviderName: data['serviceProviderName'] ?? '',
      mileage: data['mileage'] ?? 0,
      attachments: List<String>.from(data['attachments'] ?? []),
      notes: data['notes'],
      isCompleted: data['isCompleted'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'serviceType': serviceType,
      'description': description,
      'serviceDate': Timestamp.fromDate(serviceDate),
      'cost': cost,
      'serviceProviderId': serviceProviderId,
      'serviceProviderName': serviceProviderName,
      'mileage': mileage,
      'attachments': attachments,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  ServiceHistoryModel copyWith({
    String? id,
    String? vehicleId,
    String? serviceType,
    String? description,
    DateTime? serviceDate,
    double? cost,
    String? serviceProviderId,
    String? serviceProviderName,
    int? mileage,
    List<String>? attachments,
    String? notes,
    bool? isCompleted,
  }) {
    return ServiceHistoryModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      serviceDate: serviceDate ?? this.serviceDate,
      cost: cost ?? this.cost,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      serviceProviderName: serviceProviderName ?? this.serviceProviderName,
      mileage: mileage ?? this.mileage,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}