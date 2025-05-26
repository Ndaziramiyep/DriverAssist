import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String userId;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final String color;
  final String fuelType;
  final double fuelCapacity;
  final double currentFuelLevel;
  final int mileage;
  final DateTime lastServiceDate;
  final Map<String, dynamic> specifications;
  final List<Map<String, dynamic>> serviceHistory;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleModel({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.color,
    required this.fuelType,
    required this.fuelCapacity,
    required this.currentFuelLevel,
    required this.mileage,
    required this.lastServiceDate,
    required this.specifications,
    required this.serviceHistory,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$year $make $model';

  double get fuelPercentage => (currentFuelLevel / fuelCapacity) * 100;

  bool get needsService => mileage >= 5000; // Example condition

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'make': make,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'color': color,
      'fuelType': fuelType,
      'fuelCapacity': fuelCapacity,
      'currentFuelLevel': currentFuelLevel,
      'mileage': mileage,
      'lastServiceDate': lastServiceDate,
      'specifications': specifications,
      'serviceHistory': serviceHistory,
      'isDefault': isDefault,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      make: data['make'] ?? '',
      model: data['model'] ?? '',
      year: data['year'] ?? 0,
      licensePlate: data['licensePlate'] ?? '',
      color: data['color'] ?? '',
      fuelType: data['fuelType'] ?? '',
      fuelCapacity: (data['fuelCapacity'] ?? 0).toDouble(),
      currentFuelLevel: (data['currentFuelLevel'] ?? 0).toDouble(),
      mileage: data['mileage'] ?? 0,
      lastServiceDate: (data['lastServiceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      specifications: data['specifications'] ?? {},
      serviceHistory: List<Map<String, dynamic>>.from(data['serviceHistory'] ?? []),
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  VehicleModel copyWith({
    String? id,
    String? userId,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? color,
    String? fuelType,
    double? fuelCapacity,
    double? currentFuelLevel,
    int? mileage,
    DateTime? lastServiceDate,
    Map<String, dynamic>? specifications,
    List<Map<String, dynamic>>? serviceHistory,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      color: color ?? this.color,
      fuelType: fuelType ?? this.fuelType,
      fuelCapacity: fuelCapacity ?? this.fuelCapacity,
      currentFuelLevel: currentFuelLevel ?? this.currentFuelLevel,
      mileage: mileage ?? this.mileage,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      specifications: specifications ?? this.specifications,
      serviceHistory: serviceHistory ?? this.serviceHistory,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}