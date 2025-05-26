import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class SavedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? notes;
  final DateTime createdAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.notes,
    required this.createdAt,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedLocation.fromMap(String id, Map<String, dynamic> map) {
    dynamic createdAtValue = map['createdAt'];
    DateTime createdAtDateTime;

    if (createdAtValue is Timestamp) {
      createdAtDateTime = createdAtValue.toDate(); // Convert Firebase Timestamp to DateTime
    } else if (createdAtValue is String) {
      createdAtDateTime = DateTime.parse(createdAtValue); // Parse ISO 8601 string
    } else {
      createdAtDateTime = DateTime.now(); // Default to now if value is unexpected
    }

    return SavedLocation(
      id: id,
      name: map['name'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
      notes: map['notes'],
      createdAt: createdAtDateTime,
    );
  }

  SavedLocation copyWith({
    String? name,
    String? address,
    String? notes,
    double? latitude,
    double? longitude,
  }) {
    return SavedLocation(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
} 