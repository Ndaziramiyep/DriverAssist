import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:driver_assist/models/saved_location_model.dart';
import 'package:driver_assist/utils/constants.dart';

class SavedLocationsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<SavedLocation> _savedLocations = [];
  bool _isLoading = false;
  String? _error;

  List<SavedLocation> get savedLocations => _savedLocations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSavedLocations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_locations')
          .get();

      _savedLocations = snapshot.docs
          .map((doc) => SavedLocation.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveLocation({
    required String name,
    required String address,
    required LatLng location,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_locations')
          .add({
        'name': name,
        'address': address,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newLocation = SavedLocation(
        id: docRef.id,
        name: name,
        latitude: location.latitude,
        longitude: location.longitude,
        address: address,
        notes: notes,
        createdAt: DateTime.now(),
      );

      _savedLocations.add(newLocation);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLocation({
    required String id,
    required String name,
    required String address,
    required LatLng location,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_locations')
          .doc(id)
          .update({
        'name': name,
        'address': address,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'notes': notes,
      });

      final index = _savedLocations.indexWhere((loc) => loc.id == id);
      if (index != -1) {
        _savedLocations[index] = _savedLocations[index].copyWith(
          name: name,
          address: address,
          latitude: location.latitude,
          longitude: location.longitude,
          notes: notes,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteLocation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_locations')
          .doc(id)
          .delete();

      _savedLocations.removeWhere((loc) => loc.id == id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 