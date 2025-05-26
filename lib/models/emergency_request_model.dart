import 'package:cloud_firestore/cloud_firestore.dart';

enum EmergencyRequestStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled
}

enum EmergencyRequestType {
  fuelDelivery,
  mechanic,
  towing,
  general
}

class EmergencyRequestModel {
  final String id;
  final String userId;
  final String? serviceProviderId;
  final EmergencyRequestType type;
  final EmergencyRequestStatus status;
  final GeoPoint location;
  final String description;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final double? estimatedCost;
  final String? notes;
  final Map<String, dynamic>? additionalData;

  EmergencyRequestModel({
    required this.id,
    required this.userId,
    this.serviceProviderId,
    required this.type,
    required this.status,
    required this.location,
    required this.description,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.estimatedCost,
    this.notes,
    this.additionalData,
  });

  factory EmergencyRequestModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EmergencyRequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      serviceProviderId: data['serviceProviderId'],
      type: EmergencyRequestType.values.firstWhere(
        (e) => e.toString() == 'EmergencyRequestType.${data['type']}',
        orElse: () => EmergencyRequestType.general,
      ),
      status: EmergencyRequestStatus.values.firstWhere(
        (e) => e.toString() == 'EmergencyRequestStatus.${data['status']}',
        orElse: () => EmergencyRequestStatus.pending,
      ),
      location: data['location'] as GeoPoint,
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      estimatedCost: data['estimatedCost']?.toDouble(),
      notes: data['notes'],
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'serviceProviderId': serviceProviderId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'location': location,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'estimatedCost': estimatedCost,
      'notes': notes,
      'additionalData': additionalData,
    };
  }

  EmergencyRequestModel copyWith({
    String? serviceProviderId,
    EmergencyRequestStatus? status,
    DateTime? acceptedAt,
    DateTime? completedAt,
    double? estimatedCost,
    String? notes,
    Map<String, dynamic>? additionalData,
  }) {
    return EmergencyRequestModel(
      id: id,
      userId: userId,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      type: type,
      status: status ?? this.status,
      location: location,
      description: description,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      notes: notes ?? this.notes,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}