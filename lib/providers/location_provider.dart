import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_assist/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_assist/services/location_service.dart';
import 'dart:async'; // Import dart:async for StreamSubscription

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  Position? _currentLocation;
  LatLng? _currentLatLng;
  bool _isLoading = false;
  String? _error;

  // New fields for user preferences
  bool _locationServicesEnabled = true;
  String _locationAccuracy = 'high'; // 'high', 'balanced', 'low'

  StreamSubscription<Position>? _positionSubscription;

  // Getters
  bool get locationServicesEnabled => _locationServicesEnabled;
  String get locationAccuracy => _locationAccuracy;

  LocationProvider() {
    _loadPreferences();
    initialize();
  }

  Position? get currentLocation => _currentLocation;
  LatLng? get currentLatLng => _currentLatLng;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _locationServicesEnabled = prefs.getBool('locationServicesEnabled') ?? true;
    _locationAccuracy = prefs.getString('locationAccuracy') ?? 'high';
    notifyListeners();
    // Optionally, load from Firestore for cross-device sync
    final userId = AppConstants.currentUserId;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data['locationSettings'] != null) {
        _locationServicesEnabled = data['locationSettings']['enabled'] ?? _locationServicesEnabled;
        _locationAccuracy = data['locationSettings']['accuracy'] ?? _locationAccuracy;
        notifyListeners();
      }
    }
  }

  Future<void> setLocationServicesEnabled(bool enabled) async {
    _locationServicesEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('locationServicesEnabled', enabled);
    notifyListeners();
    // Save to Firestore
    final userId = AppConstants.currentUserId;
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'locationSettings': {
        'enabled': enabled,
        'accuracy': _locationAccuracy,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!enabled) {
      await stopLocationUpdates();
    } else {
      await initialize();
    }
  }

  Future<void> setLocationAccuracy(String accuracy) async {
    _locationAccuracy = accuracy;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locationAccuracy', accuracy);
    notifyListeners();
    // Save to Firestore
    final userId = AppConstants.currentUserId;
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'locationSettings': {
        'enabled': _locationServicesEnabled,
        'accuracy': accuracy,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasPermission = await _locationService.checkPermission();
      if (!hasPermission) {
        _error = 'Location permission denied';
        return;
      }

      final position = await _locationService.getCurrentPosition();
      _currentLocation = position;
      _currentLatLng = LatLng(position.latitude, position.longitude);
      
      // Start listening to location updates ONLY if location services are enabled
      if (_locationServicesEnabled) {
         _positionSubscription = _locationService.getPositionStream().listen((position) {
          _currentLocation = position;
          _currentLatLng = LatLng(position.latitude, position.longitude);
          notifyListeners();
        });
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLocation() async {
    try {
      _currentLocation = await _locationService.getCurrentPosition();
      _currentLatLng = await _locationService.getCurrentLatLng();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void startLocationUpdates() {
    // Cancel existing subscription if any
    _positionSubscription?.cancel();

    _positionSubscription = _locationService.getPositionStream().listen((Position position) {
      _currentLocation = position;
      _currentLatLng = LatLng(position.latitude, position.longitude);
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  LatLng? getCurrentLatLng() {
    return _currentLatLng;
  }

  Future<double?> calculateDistance(LatLng destination) async {
    if (_currentLatLng == null) return null;
    return await _locationService.calculateDistance(_currentLatLng!, destination);
  }

  Future<void> stopLocationUpdates() async {
    // Cancel the location stream to stop tracking
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Cancel subscription when the provider is disposed
  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
