
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class ServiceProviderModel {
  final String id;
  final String name;
  final String type; // fuel, charging, mechanic, emergency
  final String address;
  final GeoPoint location;
  final String phoneNumber;
  final String? email;
  final String? website;
  final List<String> services;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isOpen;
  final Map<String, dynamic> operatingHours;
  final List<String> acceptedPaymentMethods;
  final String? imageUrl;

  ServiceProviderModel({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.location,
    required this.phoneNumber,
    this.email,
    this.website,
    required this.services,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.isOpen,
    required this.operatingHours,
    required this.acceptedPaymentMethods,
    this.imageUrl,
  });

  factory ServiceProviderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ServiceProviderModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] as GeoPoint,
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'],
      website: data['website'],
      services: List<String>.from(data['services'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      isOpen: data['isOpen'] ?? false,
      operatingHours: data['operatingHours'] ?? {},
      acceptedPaymentMethods: List<String>.from(data['acceptedPaymentMethods'] ?? []),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'address': address,
      'location': location,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'services': services,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
      'isOpen': isOpen,
      'operatingHours': operatingHours,
      'acceptedPaymentMethods': acceptedPaymentMethods,
      'imageUrl': imageUrl,
    };
  }

  double getDistance(GeoPoint userLocation) {
    // Calculate distance between two GeoPoints
    // This is a simple calculation, you might want to use a more accurate formula
    double lat1 = location.latitude;
    double lon1 = location.longitude;
    double lat2 = userLocation.latitude;
    double lon2 = userLocation.longitude;

    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }
}