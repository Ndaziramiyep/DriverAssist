import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:driver_assist/providers/location_provider.dart';
import 'package:driver_assist/providers/saved_locations_provider.dart';
import 'package:driver_assist/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:driver_assist/widgets/custom_app_bar.dart';
import 'package:driver_assist/widgets/quick_action_button.dart';
import 'package:driver_assist/screens/place_results_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Polyline> _routes = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Marker? _currentLocationMarker;
  Marker? _destinationMarker;
  String _currentDisplayLabel = "";
  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  bool _isNavigating = false;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  String? _nextTurn;
  double _bearing = 0.0;
  List<Map<String, dynamic>> _nearbyServices = [];
  bool _isSheetOpen = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _initializeMicAnimation();
    _loadRecentSearches();
    // Listen to location changes
    Provider.of<LocationProvider>(context, listen: false).addListener(_onLocationChanged);
  }

  void _initializeMicAnimation() {
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _micAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _micAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _micAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _micAnimationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _micAnimationController.forward();
      }
    });
  }

  Future<void> _loadRecentSearches() async {
    // TODO: Implement loading recent searches from local storage
    setState(() {
      _recentSearches = [
        'Gas Station',
        'Charging Station',
        'Mechanic',
        'Restaurant',
        'Parking',
      ];
    });
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = _recentSearches;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _suggestions = _recentSearches
          .where((search) => search.toLowerCase().contains(lowercaseQuery))
          .toList();
    });
  }

  void _onLocationChanged() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final currentLatLng = locationProvider.getCurrentLatLng();
    
    if (currentLatLng != null) {
      setState(() {
        _currentLocationMarker = Marker(
          point: currentLatLng,
          width: 80,
          height: 80,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 40,
          ),
        );
      });
    }
  }

  Future<void> _initializeMap() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final latLng = locationProvider.getCurrentLatLng();

    if (latLng == null) {
      print('[HomeScreen] LatLng is null, cannot fetch nearby services yet.');
      return;
    }

    print('[HomeScreen] Using LatLng: ${latLng.latitude}, ${latLng.longitude}');
    await _fetchNearbyServices(latLng);
  }

  Future<void> _fetchNearbyServices(LatLng latLng) async {
    setState(() => _isLoading = true);
    try {
      // Use Overpass API instead of Google Places
      final overpassUrl = 'https://overpass-api.de/api/interpreter';
      final query = '''
        [out:json][timeout:25];
        (
          node["amenity"="fuel"](around:5000,${latLng.latitude},${latLng.longitude});
          node["amenity"="mechanic"](around:5000,${latLng.latitude},${latLng.longitude});
          node["amenity"="charging_station"](around:5000,${latLng.latitude},${latLng.longitude});
          node["shop"="car_repair"](around:5000,${latLng.latitude},${latLng.longitude});
          node["shop"="car"](around:5000,${latLng.latitude},${latLng.longitude});
        );
        out body;
        >;
        out skel qt;
      ''';

      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        
        setState(() {
          _nearbyServices = elements.map((element) {
            final tags = element['tags'] as Map<String, dynamic>? ?? {};
            final name = tags['name'] ?? tags['operator'] ?? 'Unknown Place';
            final type = tags['amenity'] ?? tags['shop'] ?? 'unknown';
            
            // Use only the name for display
            final displayAddress = name; // Use the determined name as the display address

            return {
              'name': name,
              'type': type,
              'geometry': {
                'location': {
                  'lat': element['lat'],
                  'lng': element['lon'],
                }
              },
              'vicinity': displayAddress,
            };
          }).toList();

          // Update markers
          _markers = _nearbyServices.map((service) {
            final lat = service['geometry']['location']['lat'];
            final lng = service['geometry']['location']['lng'];
            final type = service['type'];
            
            IconData icon;
            switch (type) {
              case 'fuel':
                icon = Icons.local_gas_station;
                break;
              case 'charging_station':
                icon = Icons.ev_station;
                break;
              case 'mechanic':
              case 'car_repair':
                icon = Icons.build;
                break;
              default:
                icon = Icons.location_on;
            }

            return Marker(
              point: LatLng(lat, lng),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () {
                  final loc = service['geometry']['location'];
                  final destination = LatLng(loc['lat'], loc['lng']);
                  _startNavigation(destination);
                },
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 40,
                ),
              ),
            );
          }).toList();
        });

        print('Found ${_nearbyServices.length} nearby services');
      }
    } catch (e) {
      print('Error fetching nearby services: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showServiceDetails(Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service['name'],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              service['vicinity'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    final lat = service['geometry']['location']['lat'];
                    final lng = service['geometry']['location']['lng'];
                    final destination = LatLng(lat, lng);
                    _startNavigation(destination);
                  },
                  icon: const Icon(Icons.navigation_sharp),
                  label: const Text('Start Navigation'),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    final lat = service['geometry']['location']['lat'];
                    final lng = service['geometry']['location']['lng'];
                    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Open in Maps'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    final lat = service['geometry']['location']['lat'];
                    final lng = service['geometry']['location']['lng'];
                    final text = '${service['name']}\n${service['vicinity']}\nhttps://www.google.com/maps/search/?api=1&query=$lat,$lng';
                    Share.share(text);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;
    final apiKey = AppConstants.googleMapsApiKey;
    final url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?query=${Uri.encodeComponent(query)}&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;
      if (results.isNotEmpty) {
        final place = results[0];
        final loc = place['geometry']['location'];
        final destination = LatLng(loc['lat'], loc['lng']);
        
        setState(() {
          _destination = destination;
          _destinationMarker = Marker(
            point: destination,
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () => _showNavigationOptions(destination, place['name']),
              child: Icon(
                Icons.location_on,
                color: Theme.of(context).primaryColor,
                size: 40,
            ),
          ),
        );
          _markers.clear();
          _markers.add(_destinationMarker!);
        });

        _mapController.move(destination, _mapController.zoom);
        _showNavigationOptions(destination, place['name']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching location found.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to search for location.')),
      );
    }
  }

  void _showNavigationOptions(LatLng destination, String placeName) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              placeName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _startNavigation(destination),
              icon: const Icon(Icons.directions),
              label: const Text('Start Navigation'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showSaveLocationDialog(
                name: placeName,
                address: placeName,
                location: destination,
              ),
              icon: const Icon(Icons.save),
              label: const Text('Save Location'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNavigation(LatLng destination) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final currentLocation = locationProvider.getCurrentLatLng();
    
    if (currentLocation == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available')),
      );
      return;
    }

    setState(() {
      _isNavigating = true;
      _destination = destination;
       // Clear existing markers except current location
      _markers.removeWhere((marker) => marker != _currentLocationMarker);
       // Add destination marker
       _destinationMarker = Marker(
            point: destination,
            width: 80,
            height: 80,
            child: Icon(
              Icons.location_on,
              color: Theme.of(context).primaryColor,
              size: 40,
            ),
          );
        _markers.add(_destinationMarker!);
    });

    // Get route from OSRM API
    final url = 'https://router.project-osrm.org/route/v1/driving/${currentLocation.longitude},${currentLocation.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';
    
    try {
      final response = await http.get(Uri.parse(url)).timeout(
         const Duration(seconds: 15),
         onTimeout: () {
            throw TimeoutException('Route calculation timed out');
         },
      );
      
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          final routePoints = coordinates.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();
          
          setState(() {
            _routePoints = routePoints;
            _routes = [
              Polyline(
                points: routePoints,
                color: Theme.of(context).primaryColor,
                strokeWidth: 4.0,
              ),
            ];
          });

           // Move map to fit the route
           if (_routePoints.isNotEmpty) {
               final bounds = LatLngBounds.fromPoints(_routePoints);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                   _mapController.fitBounds(bounds, options: FitBoundsOptions(padding: EdgeInsets.all(50)));
                });
           }

          // You could potentially start navigation updates here if needed
          // _startNavigationUpdates();

        } else {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed to get navigation route: ${data['code']}')),
           );
        }
      }
    } catch (e) {
      print('Error getting route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get navigation route: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _routes.clear();
      _routePoints.clear();
      _destination = null;
      _destinationMarker = null;
       // Optionally re-fetch nearby services or just clear markers
       _markers.removeWhere((marker) => marker != _currentLocationMarker);
    });
  }

  Future<void> _showSaveLocationDialog({
    required String name,
    required String address,
    required LatLng location,
  }) async {
    final nameController = TextEditingController(text: name);
    final addressController = TextEditingController(text: address);
    final notesController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<SavedLocationsProvider>().saveLocation(
                    name: nameController.text,
                    address: addressController.text,
                    location: location,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );
              if (mounted) {
                print('[HomeScreen] Attempting to show success snackbar.');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location saved successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _micAnimationController.forward();
      
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            setState(() {
              _isListening = false;
              _searchController.text = val.recognizedWords;
            });
            _micAnimationController.stop();
            _micAnimationController.reset();
            _performSearch(val.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
        localeId: 'en_US',
        onSoundLevelChange: (level) {
          // You can use this to show sound level visualization if needed
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    _micAnimationController.stop();
    _micAnimationController.reset();
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _currentDisplayLabel = query;
    });

    // Add to recent searches if not already present
    if (!_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      });
    }

    // Navigate to PlaceResultsScreen with the search query
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceResultsScreen(
          query: query,
        ),
      ),
    );
  }

  void _showNearbyServicesSheet() {
    setState(() => _isSheetOpen = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.2,
          maxChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Text(
                          'Nearby Services',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _nearbyServices.isEmpty
                          ? Center(
                              child: Text(
                                'No services found.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _nearbyServices.length,
                            itemBuilder: (context, index) {
                              final place = _nearbyServices[index];
                              return ListTile(
                                  leading: Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  title: Text(
                                    place['name'] ?? '',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Text(
                                        place['vicinity'] ?? '',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        IconButton(
                                            icon: Icon(
                                              Icons.directions,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          tooltip: 'Directions',
                                          onPressed: () {
                                              // Get location from the service item
                                            final loc = place['geometry']['location'];
                                              final destination = LatLng(loc['lat'], loc['lng']);
                                              
                                              // Close the bottom sheet
                                              Navigator.pop(context);
                                              
                                              // Start in-app navigation
                                              _startNavigation(destination);
                                          },
                                        ),
                                        if (place['formatted_phone_number'] != null)
                                          IconButton(
                                              icon: Icon(
                                                Icons.call,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                            tooltip: 'Call',
                                            onPressed: () {
                                              final phone = place['formatted_phone_number'];
                                              launchUrl(Uri.parse('tel:$phone'));
                                            },
                                          ),
                                        IconButton(
                                            icon: Icon(
                                              Icons.share,
                                              color: Theme.of(context).iconTheme.color,
                                            ),
                                          tooltip: 'Share',
                                          onPressed: () {
                                            final loc = place['geometry']['location'];
                                            final text = '${place['name'] ?? ''}\n${place['vicinity'] ?? ''}\nhttps://www.google.com/maps/search/?api=1&query=${loc['lat']},${loc['lng']}';
                                            Share.share(text);
                                          },
                                        ),
                                          // Add Save Location button
                                          IconButton(
                                            icon: Icon(
                                              Icons.bookmark_border, // Using bookmark outline icon
                                              color: Theme.of(context).iconTheme.color,
                                            ),
                                            tooltip: 'Save Location',
                                            onPressed: () {
                                              // Call a new method to save the location
                                              _saveServiceLocation(place);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  final loc = place['geometry']['location'];
                                    _mapController.move(
                                      LatLng(loc['lat'], loc['lng']),
                                      _mapController.zoom,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => setState(() => _isSheetOpen = false));
  }

  // Method to save a service location
  void _saveServiceLocation(Map<String, dynamic> service) async {
     try {
       final loc = service['geometry']['location'];
       final location = LatLng(loc['lat'], loc['lng']);
       final name = service['name'] ?? 'Unknown Place';
       final address = service['vicinity'] ?? 'Unknown Address';

       await context.read<SavedLocationsProvider>().saveLocation(
         name: name,
         address: address,
         location: location,
         notes: null, // No specific notes from this view
       );

       if (mounted) {
         print('[HomeScreen] Attempting to show success snackbar.');
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('$name saved successfully!')),
         );
       }

     } catch (e) {
       print('Error saving location: $e');
        if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to save location.')),
         );
        }
     }
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    setState(() => _isSearching = true);
    // Implement your search logic here
    // For example, search for locations or services
    debugPrint('Searching for: $query');
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final currentLatLng = locationProvider.getCurrentLatLng();

    if (currentLatLng == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: CustomAppBar(
        searchController: _searchController,
        onSearchTap: () async {
          final query = _searchController.text;
          await _searchPlace(query);
        },
        onVoiceSearchTap: () {
          if (_isListening) {
            _stopListening();
          } else {
            _startListening();
          }
        },
        onProfileTap: () {
          Navigator.pushNamed(context, AppConstants.profileRoute);
        },
        isListening: _isListening,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: currentLatLng,
              zoom: 15.0,
              onTap: (_, point) {
                if (_isNavigating) {
                  _stopNavigation();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.driver_assist',
              ),
              PolylineLayer(polylines: _routes),
              MarkerLayer(markers: [
                if (_currentLocationMarker != null) _currentLocationMarker!,
                if (_destinationMarker != null) _destinationMarker!,
                ..._markers,
              ]),
            ],
          ),
          
          // Navigation UI
          if (_isNavigating && _nextTurn != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.navigation,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _nextTurn!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _stopNavigation,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Quick Action Buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                QuickActionButton(
                  icon: Icons.local_gas_station,
                  label: 'Fuel',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaceResultsScreen(
                          query: 'Fuel Stations',
                          placeType: 'fuel',
                        ),
                      ),
                    );
                  },
                ),
                QuickActionButton(
                  icon: Icons.ev_station,
                  label: 'Charging',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaceResultsScreen(
                          query: 'Charging Stations',
                          placeType: 'charging_station',
                        ),
                      ),
                    );
                  },
                ),
                QuickActionButton(
                  icon: Icons.build,
                  label: 'Mechanic',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaceResultsScreen(
                          query: 'Mechanics',
                          placeType: 'mechanic',
                        ),
                      ),
                    );
                  },
                ),
                QuickActionButton(
                  icon: Icons.emergency,
                  label: 'SOS',
                  onTap: () {
                    Navigator.pushNamed(context, AppConstants.emergencyRoute);
                  },
                ),
              ],
            ),
          ),

          // Bottom Sheet with Nearby Services Preview
          if (!_isSheetOpen)
            DraggableScrollableSheet(
              initialChildSize: 0.15,
              minChildSize: 0.1,
              maxChildSize: 0.2,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nearby Services',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: _showNearbyServicesSheet,
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _nearbyServices.isEmpty
                            ? Center(
                                child: Text(
                                  'No services found.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _nearbyServices.length > 3 ? 3 : _nearbyServices.length,
                                itemBuilder: (context, index) {
                                  final place = _nearbyServices[index];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Icon(
                                      Icons.location_on,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    title: Text(
                                      place['name'] ?? '',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place['vicinity'] ?? '',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.directions,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                              tooltip: 'Directions',
                                              onPressed: () {
                                                // Get location from the service item
                                                final loc = place['geometry']['location'];
                                                final destination = LatLng(loc['lat'], loc['lng']);
                                                
                                                // Close the bottom sheet
                                                Navigator.pop(context);
                                                
                                                // Start in-app navigation
                                                _startNavigation(destination);
                                              },
                                            ),
                                            if (place['formatted_phone_number'] != null)
                                              IconButton(
                                                icon: Icon(
                                                  Icons.call,
                                                  color: Theme.of(context).colorScheme.secondary,
                                                ),
                                                tooltip: 'Call',
                                                onPressed: () {
                                                  final phone = place['formatted_phone_number'];
                                                  launchUrl(Uri.parse('tel:$phone'));
                                                },
                                              ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.share,
                                                color: Theme.of(context).iconTheme.color,
                                              ),
                                              tooltip: 'Share',
                                              onPressed: () {
                                                final loc = place['geometry']['location'];
                                                final text = '${place['name'] ?? ''}\n${place['vicinity'] ?? ''}\nhttps://www.google.com/maps/search/?api=1&query=${loc['lat']},${loc['lng']}';
                                                Share.share(text);
                                              },
                                            ),
                                            // Add Save Location button
                                            IconButton(
                                              icon: Icon(
                                                Icons.bookmark_border, // Using bookmark outline icon
                                                color: Theme.of(context).iconTheme.color,
                                              ),
                                              tooltip: 'Save Location',
                                              onPressed: () {
                                                // Call a new method to save the location
                                                _saveServiceLocation(place);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      final loc = place['geometry']['location'];
                                      _mapController.move(
                                          LatLng(loc['lat'], loc['lng']),
                                        _mapController.zoom,
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    Provider.of<LocationProvider>(context, listen: false).removeListener(_onLocationChanged);
    _searchController.dispose();
    _mapController.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }
}