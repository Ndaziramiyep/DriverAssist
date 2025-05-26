import 'package:flutter/material.dart';
import 'package:driver_assist/widgets/service_provider_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedServiceType = 'all';
  String _selectedSortBy = 'distance';
  bool _showOnlyOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                // Implement search logic
              },
            ),
          ),

          // Service Type Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildServiceTypeChip('all', 'All'),
                _buildServiceTypeChip('fuel', 'Fuel'),
                _buildServiceTypeChip('charging', 'Charging'),
                _buildServiceTypeChip('mechanic', 'Mechanic'),
                _buildServiceTypeChip('emergency', 'Emergency'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Services List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 10, // Replace with actual service count
              itemBuilder: (context, index) {
                return const ServiceProviderCard();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to map view
        },
        icon: const Icon(Icons.map),
        label: const Text('Map View'),
      ),
    );
  }

  Widget _buildServiceTypeChip(String type, String label) {
    final isSelected = _selectedServiceType == type;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedServiceType = selected ? type : 'all';
          });
        },
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter Services',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  // Sort By
                  Text(
                    'Sort By',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'distance',
                        label: Text('Distance'),
                        icon: Icon(Icons.location_on),
                      ),
                      ButtonSegment(
                        value: 'rating',
                        label: Text('Rating'),
                        icon: Icon(Icons.star),
                      ),
                      ButtonSegment(
                        value: 'price',
                        label: Text('Price'),
                        icon: Icon(Icons.attach_money),
                      ),
                    ],
                    selected: {_selectedSortBy},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedSortBy = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Show Only Open
                  SwitchListTile(
                    title: const Text('Show Only Open'),
                    value: _showOnlyOpen,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyOpen = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Apply Button
                  ElevatedButton(
                    onPressed: () {
                      // Apply filters
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}