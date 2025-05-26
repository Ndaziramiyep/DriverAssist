import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:driver_assist/utils/constants.dart';
import 'package:driver_assist/providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:driver_assist/widgets/animated_mic_button.dart';
import 'package:driver_assist/providers/saved_locations_provider.dart';

class PlaceResultsScreen extends StatefulWidget {
  final String query;
  final String? placeType;

  const PlaceResultsScreen({
    super.key,
    required this.query,
    this.placeType,
  });

  @override
  State<PlaceResultsScreen> createState() => _PlaceResultsScreenState();
}

class _PlaceResultsScreenState extends State<PlaceResultsScreen> with SingleTickerProviderStateMixin {
  MapController _mapController = MapController();
  List<Marker> _markers = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _places = [];
  LatLng? _selectedDestination;
  List<LatLng> _routePoints = [];
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _currentDisplayLabel = "";
  bool _isInitializing = true;
  LatLng? _cachedLocation;
  bool _isSearching = false;
  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;

  @override
  void initState() {
    super.initState();
    _currentDisplayLabel = widget.query;
    _searchController.text = widget.query;
    _initializeLocation();
    _loadRecentSearches();
    _initializeMicAnimation();
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

  Future<void> _initializeLocation() async {
    if (!mounted) return;
    
    setState(() => _isInitializing = true);
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      // Try to get cached location first
      _cachedLocation = locationProvider.getCurrentLatLng();
      
      if (_cachedLocation == null) {
        await locationProvider.initialize();
        _cachedLocation = locationProvider.getCurrentLatLng();
      }

      if (_cachedLocation != null) {
        await _fetchPlaces();
      }
    } catch (e) {
      print('Error initializing location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error getting location. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _fetchPlaces() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      if (_cachedLocation == null) {
        print('[PlaceResultsScreen] LatLng is null, cannot fetch places yet.');
        return;
      }

      // Clear existing markers
      _markers.clear();

      // Add current location marker
      _markers.add(
        Marker(
          point: _cachedLocation!,
          width: 80,
          height: 80,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );

      // Use Overpass API for place search with timeout
      final overpassUrl = 'https://overpass-api.de/api/interpreter';
      String query;

      if (widget.placeType != null) {
        // Search by amenity or shop type if placeType is provided (from quick actions)
        String amenityQuery = '';
        String shopQuery = '';

        if (widget.placeType == 'mechanic') {
          // Include car_repair for mechanics
          amenityQuery = 'node["amenity"="mechanic"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});\nway["amenity"="mechanic"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});\nrelation["amenity"="mechanic"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});';
          shopQuery = 'node["shop"="car_repair"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});\nway["shop"="car_repair"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});\nrelation["shop"="car_repair"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});';
        } else {
          // Use the provided placeType for other services
          amenityQuery = 'node["amenity"="${widget.placeType}"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});\nway["amenity"="${widget.placeType}"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});\nrelation["amenity"="${widget.placeType}"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});';
          shopQuery = 'node["shop"="${widget.placeType}"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});\nway["shop"="${widget.placeType}"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});\nrelation["shop"="${widget.placeType}"](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});';
        }

        query = '''
          [out:json][timeout:10];
          (
            $amenityQuery
            $shopQuery
          );
          out body;
          >;
          out skel qt;
        ''';
        print('[PlaceResultsScreen] Querying by placeType: ${widget.placeType}');
      } else {
        // Search by name if no placeType is provided (from search bar)
        query = '''
          [out:json][timeout:10];
          (
            node["name"~"${widget.query}",i](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});
            way["name"~"${widget.query}",i](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});
            relation["name"~"${widget.query}",i](around:5000,${_cachedLocation!.latitude},${_cachedLocation!.longitude});
          );
          out body;
          >;
          out skel qt;
        ''';
        print('[PlaceResultsScreen] Querying by name: ${widget.query}');
      }

      print('[PlaceResultsScreen] Overpass API URL: $overpassUrl');
      print('[PlaceResultsScreen] Overpass API Query: $query');

      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('The request timed out');
        },
      );

      if (!mounted) return;

      print('[PlaceResultsScreen] Overpass API Response Status Code: ${response.statusCode}');
      print('[PlaceResultsScreen] Overpass API Response Body: ${response.body}');

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
        final elements = data['elements'] as List;
        
        setState(() {
          _places = elements.map((element) {
            final tags = element['tags'] as Map<String, dynamic>? ?? {};
            final name = tags['name'] ?? tags['operator'] ?? tags['addr:street'] ?? 'Unknown Place';
            final type = tags['amenity'] ?? tags['shop'] ?? 'Unknown';
             final lat = element['lat'] ?? element['center']?['lat'];
            final lon = element['lon'] ?? element['center']?['lon'];

            // Use only the name for display
            final displayAddress = name; // Use the determined name as the display address

            return {
              'name': name,
              'type': type,
              'lat': lat,
              'lon': lon,
              'address': displayAddress,
            };
          }).toList();

          // Add destination markers
          _markers.addAll(elements.map((element) {
            final lat = element['lat'] ?? element['center']?['lat'];
            final lon = element['lon'] ?? element['center']?['lon'];
            final tags = element['tags'] as Map<String, dynamic>? ?? {};
            final type = tags['amenity'] ?? tags['shop'] ?? 'unknown';

            print('[PlaceResultsScreen] Element tags: $tags');
            print('[PlaceResultsScreen] Extracted type: $type');

            IconData icon;
            Color color = Theme.of(context).primaryColor;

            switch (type) {
              case 'fuel':
                icon = Icons.local_gas_station;
                color = Colors.green;
                 print('[PlaceResultsScreen] Assigning fuel icon and green color.');
                break;
              case 'charging_station':
                icon = Icons.ev_station;
                color = Colors.purple;
                 print('[PlaceResultsScreen] Assigning charging icon and purple color.');
                break;
              case 'mechanic':
              case 'car_repair':
                icon = Icons.build;
                color = Colors.orange;
                 print('[PlaceResultsScreen] Assigning mechanic icon and orange color.');
                break;
              default:
                icon = Icons.location_on;
                color = Theme.of(context).primaryColor;
                 print('[PlaceResultsScreen] Assigning default location icon and theme color.');
            }

            return Marker(
              point: LatLng(
                lat?.toDouble() ?? 0.0,
                lon?.toDouble() ?? 0.0,
              ),
              width: 80,
              height: 80,
              child: Icon(
                icon,
                color: color,
                size: 40,
              ),
            );
          }).toList());
        });

         print('[PlaceResultsScreen] Found ${_places.length} places');

        if (_places.isNotEmpty) {
          // Move map to the first result or current location if no results
           final firstPlace = _places.first;
           if (firstPlace['lat'] != null && firstPlace['lon'] != null) {
             // Use addPostFrameCallback to ensure the map is built before moving
             WidgetsBinding.instance.addPostFrameCallback((_) {
                  _mapController.move(
                    LatLng(firstPlace['lat'], firstPlace['lon']),
                    _mapController.zoom,
                  );
             });
           } else if (_cachedLocation != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                  _mapController.move(
                   _cachedLocation!,
                   _mapController.zoom,
                 );
              });
           }
        } else if (_cachedLocation != null) {
           // If no places found, center map on current location
            WidgetsBinding.instance.addPostFrameCallback((_) {
                 _mapController.move(
                    _cachedLocation!,
                    _mapController.zoom,
                  );
            });
        }

      } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Error fetching places. Status code: ${response.statusCode}'),
               duration: const Duration(seconds: 2),
             ),
           );
         }
      }
    } catch (e) {
      print('Error fetching places: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading places: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    try {
      // Use OSRM API to get the route with timeout
      final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('The request timed out');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          
          if (mounted) {
      setState(() {
              _routePoints = coordinates.map((coord) {
                return LatLng(coord[1].toDouble(), coord[0].toDouble());
              }).toList();
              _selectedDestination = end;
            });
          }
        }
      }
    } catch (e) {
      print('Error getting route: $e');
      if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error calculating route. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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

    _fetchPlaces();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Results for ${widget.query}'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing location...'),
            ],
          ),
        ),
      );
    }

    if (_cachedLocation == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Results for ${widget.query}'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text('Location services are disabled'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _initializeLocation,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Results for $_currentDisplayLabel'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search for places...',
              leading: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _performSearch(_searchController.text),
              ),
              trailing: [
                if (_isListening)
                  AnimatedBuilder(
                    animation: _micAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _micAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.2),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.mic, color: Colors.blue),
                            onPressed: _stopListening,
                          ),
                        ),
                      );
                    },
            )
          else
                  IconButton(
                    icon: const Icon(Icons.mic_none),
                    onPressed: _startListening,
                  ),
              ],
              onChanged: (value) {
                _updateSuggestions(value);
                setState(() => _isSearching = true);
              },
              onSubmitted: _performSearch,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _cachedLocation!,
              zoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.driver_assist',
              ),
              MarkerLayer(markers: _markers),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              if (_routePoints.isNotEmpty)
                MarkerLayer(
                  markers: _buildDirectionMarkers(),
                ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_isSearching && _suggestions.isNotEmpty)
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(suggestion),
                      onTap: () {
                        _searchController.text = suggestion;
                        _performSearch(suggestion);
                        setState(() => _isSearching = false);
                      },
                    );
                  },
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                    'Found ${_places.length} places',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                              itemCount: _places.length,
                              itemBuilder: (context, index) {
                                final place = _places[index];
                                return ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(
                            place['name'],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            place['address'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                icon: const Icon(Icons.directions),
                                            onPressed: () {
                                  final destination = LatLng(place['lat'], place['lon']);
                                  _getRoute(_cachedLocation!, destination);
                                  _mapController.move(
                                    destination,
                                    _mapController.zoom,
                                  );
                                },
                              ),
                                            IconButton(
                                icon: const Icon(Icons.share),
                                color: Theme.of(context).iconTheme.color,
                                tooltip: 'Share Location',
                                              onPressed: () {
                                  final lat = place['lat'];
                                  final lon = place['lon'];
                                  if (lat != null && lon != null) {
                                    final text = '${place['name'] ?? ''}\n${place['address'] ?? ''}\nhttps://www.google.com/maps/search/?api=1&query=$lat,$lon';
                                    Share.share(text);
                                  } else {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       const SnackBar(content: Text('Cannot share location, data missing.')),
                                     );
                                  }
                                              },
                                            ),
                                          IconButton(
                                icon: const Icon(Icons.bookmark_border),
                                color: Theme.of(context).iconTheme.color,
                                tooltip: 'Save Location',
                                            onPressed: () {
                                  _savePlace(place);
                                            },
                                          ),
                                        ],
                                      ),
                                  onTap: () {
                            final destination = LatLng(place['lat'], place['lon']);
                            _getRoute(_cachedLocation!, destination);
                            _mapController.move(
                              destination,
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
          ),
        ],
      ),
    );
  }

  List<Marker> _buildDirectionMarkers() {
    if (_routePoints.length < 2) return [];

    List<Marker> directionMarkers = [];
    const double markerSpacing = 0.0001;

    for (int i = 0; i < _routePoints.length - 1; i++) {
      if (i % 5 == 0) {
        final point = _routePoints[i];
        final nextPoint = _routePoints[i + 1];
        
        final bearing = const Distance().bearing(point, nextPoint);
        
        directionMarkers.add(
          Marker(
            point: point,
            width: 30,
            height: 30,
            child: Transform.rotate(
              angle: bearing * (3.14159 / 180),
              child: Icon(
                Icons.arrow_forward,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
          ),
        );
      }
    }

    return directionMarkers;
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Method to save a place from the results list
  void _savePlace(Map<String, dynamic> place) async {
     try {
       final lat = place['lat'];
       final lon = place['lon'];
       if (lat == null || lon == null) {
         print('[PlaceResultsScreen] Cannot save place, location data missing.');
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Cannot save place, location data missing.')),
           );
         }
         return;
       }

       final location = LatLng(lat, lon);
       final name = place['name'] ?? 'Unknown Place';
       final address = place['address'] ?? 'Unknown Address';

       await context.read<SavedLocationsProvider>().saveLocation(
         name: name,
         address: address,
         location: location,
         notes: null, // No specific notes from this view
       );

       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('$name saved successfully!')),
         );
       }

     } catch (e) {
       print('Error saving place: $e');
        if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to save place.')),
         );
        }
     }
  }
} 