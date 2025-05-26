import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;

  Future<bool> checkPermission() async {
    bool serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position> getCurrentPosition() async {
    return await _geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<LatLng> getCurrentLatLng() async {
    final position = await getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  Future<double> calculateDistance(LatLng start, LatLng end) async {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, start, end);
  }

  Stream<Position> getPositionStream() {
    return _geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}